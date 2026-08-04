// scripts/upload_data_tomorrow.js
// Complete script - Uploads ONLY new documents, skips existing ones

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');
const { performance } = require('perf_hooks');

// ============================================
// CONFIGURATION
// ============================================
const CONFIG = {
  BATCH_SIZE: 200,              // Documents per batch
  CHECK_BATCH_SIZE: 500,        // Documents to check at once
  DELAY_BETWEEN_BATCHES: 2000,  // 2 seconds between batches
  DELAY_BETWEEN_COLLECTIONS: 3000, // 3 seconds between collections
  RETRY_ATTEMPTS: 5,
  RETRY_DELAY: 5000,            // 5 seconds
};

// ============================================
// SETUP
// ============================================
const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ serviceAccountKey.json not found!');
  console.error(`   Expected at: ${serviceAccountPath}`);
  console.error('   Please download from Firebase Console → Project Settings → Service Accounts');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// ============================================
// HELPER FUNCTIONS
// ============================================

/**
 * Sleep for specified milliseconds
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Retry operation with exponential backoff
 */
async function retryOperation(operation, context = '', attempt = 1) {
  try {
    return await operation();
  } catch (error) {
    const isRetryable = error.code === 8 ||      // RESOURCE_EXHAUSTED
                        error.code === 4 ||      // DEADLINE_EXCEEDED
                        error.code === 14 ||     // UNAVAILABLE
                        error.message?.includes('quota') ||
                        error.message?.includes('timeout');
    
    if (isRetryable && attempt <= CONFIG.RETRY_ATTEMPTS) {
      const delay = CONFIG.RETRY_DELAY * Math.pow(1.5, attempt - 1);
      console.log(`   ⏳ Retry ${attempt}/${CONFIG.RETRY_ATTEMPTS} in ${(delay/1000).toFixed(1)}s`);
      await sleep(delay);
      return retryOperation(operation, context, attempt + 1);
    }
    
    throw error;
  }
}

/**
 * Split array into chunks
 */
function chunkArray(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

/**
 * Remove duplicates from data
 */
function removeDuplicates(data) {
  const seen = new Map();
  const unique = [];
  
  for (const item of data) {
    const key = item.id || JSON.stringify(item);
    if (!seen.has(key)) {
      seen.set(key, true);
      unique.push(item);
    }
  }
  
  if (unique.length < data.length) {
    console.log(`   🗑️ Removed ${data.length - unique.length} duplicates`);
  }
  
  return unique;
}

/**
 * Add IDs to data if missing
 */
function addIdsToData(data, prefix) {
  if (!data || data.length === 0) return data;
  
  // Check if any item has an ID
  const hasId = data.some(item => item.id);
  if (hasId) return data;
  
  console.log(`   🆔 Adding IDs with prefix '${prefix}'`);
  return data.map((item, index) => ({
    ...item,
    id: `${prefix}_${String(index + 1).padStart(5, '0')}`
  }));
}

// ============================================
// CHECK EXISTING DOCUMENTS
// ============================================

/**
 * Check which documents already exist in Firestore
 * Returns Set of existing document IDs
 */
async function getExistingDocumentIds(collectionName, ids) {
  if (!ids || ids.length === 0) {
    return new Set();
  }
  
  const existingIds = new Set();
  const chunks = chunkArray(ids, CONFIG.CHECK_BATCH_SIZE);
  
  console.log(`   🔍 Checking ${ids.length} IDs in batches of ${CONFIG.CHECK_BATCH_SIZE}...`);
  
  let checked = 0;
  for (const chunk of chunks) {
    const refs = chunk.map(id => db.collection(collectionName).doc(id));
    
    try {
      // Use getAll for efficient batch reads
      const snapshots = await retryOperation(
        () => db.getAll(...refs),
        `checking ${collectionName}`
      );
      
      snapshots.forEach((snap, index) => {
        if (snap.exists) {
          existingIds.add(chunk[index]);
        }
      });
      
      checked += chunk.length;
      console.log(`   📊 Checked ${checked}/${ids.length} documents`);
      
    } catch (error) {
      console.error(`   ⚠️ Error checking batch: ${error.message}`);
      // If batch check fails, check individually
      console.log(`   🔄 Falling back to individual checks...`);
      for (const id of chunk) {
        try {
          const doc = await retryOperation(
            () => db.collection(collectionName).doc(id).get(),
            `checking ${id}`
          );
          if (doc.exists) {
            existingIds.add(id);
          }
        } catch (err) {
          console.error(`   ❌ Failed to check ${id}: ${err.message}`);
        }
      }
    }
    
    // Small delay between check batches
    if (chunks.length > 1) {
      await sleep(500);
    }
  }
  
  return existingIds;
}

// ============================================
// UPLOAD FUNCTIONS
// ============================================

/**
 * Upload a single batch of documents
 */
async function uploadBatch(collectionName, items) {
  if (!items || items.length === 0) {
    return { added: 0 };
  }
  
  const batch = db.batch();
  
  for (const item of items) {
    if (!item.id) {
      console.warn(`   ⚠️ Item missing ID, generating one...`);
      item.id = `${collectionName}_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`;
    }
    
    const docRef = db.collection(collectionName).doc(item.id);
    const { id, ...data } = item;
    batch.set(docRef, data);
  }
  
  await retryOperation(
    () => batch.commit(),
    `uploading ${items.length} docs to ${collectionName}`
  );
  
  return { added: items.length };
}

/**
 * Upload only new documents (skip existing ones)
 */
async function uploadNewDocuments(collectionName, data) {
  console.log(`\n📤 PROCESSING: ${collectionName}`);
  console.log(`   📊 Total items: ${data.length}`);
  
  if (data.length === 0) {
    console.log(`   ⚠️ No data to process`);
    return { added: 0, skipped: 0, total: 0 };
  }
  
  // 1. Clean up data
  const cleanData = removeDuplicates(data);
  const dataWithIds = addIdsToData(cleanData, collectionName);
  
  // 2. Get all IDs
  const allIds = dataWithIds
    .filter(item => item.id)
    .map(item => item.id);
  
  if (allIds.length === 0) {
    console.log(`   ⚠️ No valid IDs found`);
    return { added: 0, skipped: 0, total: dataWithIds.length };
  }
  
  // 3. Check which exist
  console.log(`   🔍 Checking existing documents...`);
  const existingIds = await getExistingDocumentIds(collectionName, allIds);
  
  // 4. Separate existing and new
  const existingDocs = dataWithIds.filter(item => existingIds.has(item.id));
  const newDocs = dataWithIds.filter(item => !existingIds.has(item.id));
  
  console.log(`   ✅ Already exists: ${existingDocs.length} (SKIPPED - no quota used)`);
  console.log(`   🆕 New documents: ${newDocs.length} (TO UPLOAD)`);
  
  if (newDocs.length === 0) {
    console.log(`   ✅ All documents already exist in Firestore!`);
    return { added: 0, skipped: existingDocs.length, total: dataWithIds.length };
  }
  
  // 5. Upload new documents in batches
  const batches = chunkArray(newDocs, CONFIG.BATCH_SIZE);
  console.log(`   📦 ${batches.length} batches of ${CONFIG.BATCH_SIZE}`);
  
  let added = 0;
  const startTime = performance.now();
  
  for (let i = 0; i < batches.length; i++) {
    const batch = batches[i];
    const batchNum = i + 1;
    
    console.log(`   🔄 Batch ${batchNum}/${batches.length} (${batch.length} docs)`);
    
    try {
      const result = await uploadBatch(collectionName, batch);
      added += result.added;
      
      const progress = ((i + 1) / batches.length * 100).toFixed(1);
      console.log(`   📊 ${progress}% complete (${added}/${newDocs.length})`);
      
      // Delay between batches (except last)
      if (i < batches.length - 1) {
        await sleep(CONFIG.DELAY_BETWEEN_BATCHES);
      }
      
    } catch (error) {
      console.error(`   ❌ Batch ${batchNum} failed: ${error.message}`);
      console.log(`   ⏳ Waiting 10s before retrying batch...`);
      await sleep(10000);
      
      // Retry the failed batch once more
      try {
        console.log(`   🔄 Retrying batch ${batchNum}...`);
        const result = await uploadBatch(collectionName, batch);
        added += result.added;
        console.log(`   ✅ Batch ${batchNum} retry successful`);
      } catch (retryError) {
        console.error(`   ❌ Batch ${batchNum} retry failed: ${retryError.message}`);
        console.log(`   ⚠️ Skipping batch ${batchNum}...`);
      }
    }
  }
  
  const duration = ((performance.now() - startTime) / 1000).toFixed(1);
  
  console.log(`   ✅ Complete: ${added} new docs uploaded in ${duration}s`);
  console.log(`   ⏭️  Skipped: ${existingDocs.length} existing docs`);
  
  return { 
    added: added, 
    skipped: existingDocs.length, 
    total: dataWithIds.length 
  };
}

// ============================================
// PERFORMANCE MONITOR
// ============================================

class PerformanceMonitor {
  constructor() {
    this.startTime = performance.now();
    this.totalDocs = 0;
    this.totalCollections = 0;
    this.results = [];
  }
  
  addResult(collectionName, result) {
    this.results.push({ collectionName, ...result });
    this.totalDocs += result.added || 0;
    this.totalCollections += 1;
  }
  
  printSummary() {
    const elapsed = ((performance.now() - this.startTime) / 1000).toFixed(1);
    
    console.log('\n' + '=' .repeat(70));
    console.log('🎉 UPLOAD SUMMARY');
    console.log('=' .repeat(70));
    
    console.log('📊 Collection Results:');
    console.log('─'.repeat(70));
    console.log(`  ${'Collection'.padEnd(20)} ${'Added'.padEnd(10)} ${'Skipped'.padEnd(10)} ${'Total'.padEnd(10)}`);
    console.log('─'.repeat(70));
    
    for (const result of this.results) {
      console.log(
        `  ${result.collectionName.padEnd(20)} ` +
        `${String(result.added || 0).padEnd(10)} ` +
        `${String(result.skipped || 0).padEnd(10)} ` +
        `${String(result.total || 0).padEnd(10)}`
      );
    }
    
    console.log('─'.repeat(70));
    console.log(`  TOTAL: ${this.totalDocs} new documents uploaded`);
    console.log(`  ⏱️  Time: ${elapsed} seconds`);
    console.log(`  📦 Collections processed: ${this.totalCollections}`);
    
    if (this.totalDocs > 0) {
      const rate = (this.totalDocs / parseFloat(elapsed)).toFixed(1);
      console.log(`  📊 Average rate: ${rate} docs/second`);
    }
    
    console.log('=' .repeat(70));
    console.log(`💡 Daily quota used: ${this.totalDocs} / 20,000 writes`);
    console.log(`💡 Remaining writes available: ${20000 - this.totalDocs}`);
    
    if (this.totalDocs > 18000) {
      console.log(`\n⚠️  WARNING: You're close to the daily limit!`);
      console.log(`   Remaining: ${20000 - this.totalDocs} writes`);
    }
  }
}

// ============================================
// MAIN UPLOAD FUNCTION
// ============================================

/**
 * Upload all collections, skipping existing documents
 */
async function uploadAllData() {
  console.log('\n🚀 FIRESTORE UPLOAD - SKIP EXISTING DOCUMENTS');
  console.log('=' .repeat(70));
  console.log(`📋 Configuration:`);
  console.log(`   • Batch size: ${CONFIG.BATCH_SIZE} documents`);
  console.log(`   • Delay between batches: ${CONFIG.DELAY_BETWEEN_BATCHES}ms`);
  console.log(`   • Retry attempts: ${CONFIG.RETRY_ATTEMPTS}`);
  console.log(`   • Daily write limit: 20,000 (free tier)`);
  console.log(`   • Strategy: Only upload NEW documents, skip existing`);
  console.log('=' .repeat(70));
  
  const startTime = performance.now();
  const DATA_DIR = path.join(__dirname, '../data');
  
  if (!fs.existsSync(DATA_DIR)) {
    console.error(`❌ Data directory not found: ${DATA_DIR}`);
    console.error(`   Please create the data directory and add JSON files`);
    process.exit(1);
  }
  
  // List available files
  console.log(`\n📁 Data directory: ${DATA_DIR}`);
  const availableFiles = fs.readdirSync(DATA_DIR).filter(f => f.endsWith('.json'));
  console.log(`   Found ${availableFiles.length} JSON files: ${availableFiles.join(', ')}\n`);
  
  // Define collections to upload (in priority order)
  const collections = [
    { name: 'exams', file: 'exams.json', required: false },
    { name: 'questions', file: 'questions.json', required: false },
    { name: 'vocabulary', file: 'vocabulary.json', required: true },
    { name: 'exam_vocabulary', file: 'exam_vocabulary.json', required: false },
    { name: 'grammar', file: 'grammar.json', required: false },
    { name: 'kanji', file: 'kanji.json', required: false },
    { name: 'ielts_questions', file: 'ielts_questions.json', required: false },
    { name: 'hsk_questions', file: 'hsk_questions.json', required: false },
    { name: 'jlpt_questions', file: 'jlpt_questions.json', required: false },
    { name: 'topik_questions', file: 'topik_questions.json', required: false },
  ];
  
  const monitor = new PerformanceMonitor();
  let totalAdded = 0;
  
  for (const collection of collections) {
    const filePath = path.join(DATA_DIR, collection.file);
    
    if (!fs.existsSync(filePath)) {
      console.log(`⚠️ Skipping ${collection.file} - file not found`);
      if (collection.required) {
        console.log(`   ⚠️ Required collection missing!`);
      }
      continue;
    }
    
    try {
      // Read and parse JSON
      console.log(`\n📄 Reading ${collection.file}...`);
      const fileContent = fs.readFileSync(filePath, 'utf8');
      let data = JSON.parse(fileContent);
      
      if (!Array.isArray(data)) {
        console.error(`   ❌ Invalid data format - expected array`);
        continue;
      }
      
      if (data.length === 0) {
        console.log(`   ⚠️ Empty file - skipping`);
        continue;
      }
      
      console.log(`   📊 Found ${data.length} items`);
      
      // Upload collection
      const result = await uploadNewDocuments(collection.name, data);
      
      monitor.addResult(collection.name, result);
      totalAdded += result.added || 0;
      
      // Check if we're approaching quota limit
      if (totalAdded > 18000) {
        console.log(`\n⚠️  CRITICAL: Approaching daily quota (${totalAdded}/20000)`);
        console.log(`   Stopping to avoid exhausting quota for other operations.`);
        console.log(`   Run again tomorrow to upload remaining data.`);
        break;
      }
      
      // Delay between collections
      if (collections.indexOf(collection) < collections.length - 1) {
        console.log(`\n⏳ Waiting ${CONFIG.DELAY_BETWEEN_COLLECTIONS/1000}s before next collection...`);
        await sleep(CONFIG.DELAY_BETWEEN_COLLECTIONS);
      }
      
    } catch (error) {
      console.error(`❌ Failed to process ${collection.name}: ${error.message}`);
      console.error(`   ${error.stack}`);
    }
  }
  
  // Print summary
  monitor.printSummary();
  
  const elapsed = ((performance.now() - startTime) / 1000).toFixed(1);
  
  if (totalAdded === 0) {
    console.log('\n⚠️  No new documents were uploaded. Everything may already exist.');
    console.log('   Check your Firestore console to verify.');
  }
}

// ============================================
// CHECK QUOTA FUNCTION
// ============================================

/**
 * Check current Firestore quota status
 */
async function checkQuotaStatus() {
  console.log('\n🔍 CHECKING QUOTA STATUS');
  console.log('=' .repeat(50));
  
  try {
    // Test read
    const testQuery = db.collection('exams').limit(1);
    await testQuery.get();
    console.log('✅ Read operations: WORKING');
  } catch (error) {
    console.log('❌ Read operations: FAILED');
    console.log(`   Error: ${error.message}`);
  }
  
  try {
    // Test write with cleanup
    const testRef = db.collection('_quota_test').doc('test');
    await testRef.set({ timestamp: new Date().toISOString() });
    await testRef.delete();
    console.log('✅ Write operations: WORKING');
    console.log('✅ Quota available for writes');
  } catch (error) {
    console.log('❌ Write operations: FAILED');
    console.log(`   Error: ${error.message}`);
    
    if (error.message.includes('Quota exceeded')) {
      console.log('\n💡 QUOTA EXCEEDED!');
      console.log('   You have reached the daily write limit (20,000 writes).');
      console.log('   Wait 24 hours from your first write today.');
      console.log('   Or upgrade to Blaze plan for unlimited writes.');
    }
  }
  
  console.log('\n💡 Daily limits (Free Tier):');
  console.log('   • Writes: 20,000/day');
  console.log('   • Reads: 50,000/day');
  console.log('   • Deletes: 20,000/day');
}

// ============================================
// RUN THE SCRIPT
// ============================================

/**
 * Main function - checks quota then uploads
 */
async function main() {
  console.log('\n🔧 FIRESTORE UPLOAD SCRIPT');
  console.log('=' .repeat(70));
  console.log(`📅 Date: ${new Date().toLocaleString()}`);
  console.log(`📦 Total data size: ~${Math.round(process.memoryUsage().heapTotal / 1024 / 1024)}MB`);
  console.log('=' .repeat(70));
  
  // First, check quota
  await checkQuotaStatus();
  
  // Ask user to continue
  console.log('\n' + '-'.repeat(50));
  console.log('Ready to upload data...');
  console.log('Press Ctrl+C to cancel, or wait 5 seconds to continue.');
  
  await sleep(5000);
  
  // Upload data
  await uploadAllData();
}

// ============================================
// ERROR HANDLING
// ============================================

process.on('unhandledRejection', (error) => {
  console.error('\n❌ Unhandled Promise Rejection:');
  console.error(error);
  process.exit(1);
});

process.on('uncaughtException', (error) => {
  console.error('\n❌ Uncaught Exception:');
  console.error(error);
  process.exit(1);
});

// ============================================
// EXPORT FUNCTIONS (for use in other scripts)
// ============================================

module.exports = {
  uploadNewDocuments,
  checkQuotaStatus,
  getExistingDocumentIds,
  uploadBatch,
  CONFIG
};

// ============================================
// RUN
// ============================================

// Run if called directly (not imported)
if (require.main === module) {
  main().catch(error => {
    console.error('\n❌ Script failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  });
}