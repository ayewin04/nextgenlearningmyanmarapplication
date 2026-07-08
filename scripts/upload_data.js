// scripts/upload_data.js
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// 🔴 IMPORTANT: Check if serviceAccountKey.json exists
const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');
console.log('🔍 Looking for service account at:', serviceAccountPath);

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ serviceAccountKey.json NOT FOUND at:', serviceAccountPath);
  console.error('📌 Please download it from Firebase Console → Project Settings → Service Accounts');
  process.exit(1);
}

console.log('✅ serviceAccountKey.json found!');

// Load service account
const serviceAccount = require(serviceAccountPath);

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✅ Firebase Admin initialized!');

const db = admin.firestore();

// Collection names
const COLLECTIONS = {
  EXAMS: 'exams',
  QUESTIONS: 'questions',
  VOCABULARY: 'vocabulary',
  DAILY_CHALLENGES: 'daily_challenges'
};

// Data file paths
const DATA_DIR = path.join(__dirname, '../data');
console.log('📂 Data directory:', DATA_DIR);

const DATA_FILES = {
  exams: path.join(DATA_DIR, 'exams.json'),
  questions: path.join(DATA_DIR, 'questions.json'),
  vocabulary: path.join(DATA_DIR, 'vocabulary.json'),
};

// ✅ Check for duplicates in data using ID
function checkForDuplicates(data, collectionName) {
  console.log(`\n🔍 Checking for duplicates in '${collectionName}'...`);
  
  const seen = new Map();
  const duplicates = [];
  const uniqueData = [];
  let duplicateCount = 0;
  
  for (const item of data) {
    // Use ID as unique key if available
    let key;
    if (item.id) {
      key = item.id;
    } else {
      // Fallback: use burmeseWord + english translation
      const burmeseWord = item.burmeseWord || '';
      const englishTranslation = item.translations?.english || '';
      key = `${burmeseWord}_${englishTranslation}`;
    }
    
    if (seen.has(key)) {
      duplicateCount++;
      duplicates.push({
        item: item,
        existingItem: seen.get(key)
      });
      console.log(`⚠️ Duplicate found: ${item.id || item.burmeseWord || 'Unknown'}`);
    } else {
      seen.set(key, item);
      uniqueData.push(item);
    }
  }
  
  if (duplicateCount > 0) {
    console.log(`\n📊 Found ${duplicateCount} duplicate entries`);
    
    // Save duplicates for review
    const duplicateReport = {
      totalDuplicates: duplicateCount,
      collection: collectionName,
      duplicates: duplicates.map(d => ({
        duplicate: d.item.id || d.item.burmeseWord || 'Unknown',
        existing: d.existingItem.id || d.existingItem.burmeseWord || 'Unknown'
      }))
    };
    
    const reportPath = path.join(DATA_DIR, `duplicates_report_${collectionName}.json`);
    fs.writeFileSync(
      reportPath,
      JSON.stringify(duplicateReport, null, 2)
    );
    console.log(`📄 Duplicates report saved to ${reportPath}`);
  } else {
    console.log('✅ No duplicates found!');
  }
  
  return uniqueData;
}

// ✅ Check for existing documents in Firestore by ID
async function checkExistingDocuments(collectionName, data) {
  console.log(`\n🔍 Checking existing documents in Firestore for '${collectionName}'...`);
  
  let existingCount = 0;
  let newCount = 0;
  const existingDocs = [];
  const newDocs = [];
  
  for (const item of data) {
    // Check if item has an ID
    if (item.id) {
      const docRef = db.collection(collectionName).doc(item.id);
      const doc = await docRef.get();
      
      if (doc.exists) {
        existingCount++;
        existingDocs.push(item);
        console.log(`📄 Document exists: ${item.id} - ${item.burmeseWord || 'Unknown'}`);
      } else {
        newCount++;
        newDocs.push(item);
        console.log(`✨ New document: ${item.id} - ${item.burmeseWord || 'Unknown'}`);
      }
    } else {
      // Item without ID - treat as new
      newCount++;
      newDocs.push(item);
      console.log(`✨ New document (no ID): ${item.burmeseWord || 'Unknown'}`);
    }
  }
  
  console.log(`\n📊 Existing/New Summary:
    - Existing documents: ${existingCount}
    - New documents: ${newCount}
  `);
  
  return { existingDocs, newDocs };
}

// ✅ Upload a collection to Firestore with ID check
async function uploadCollection(collectionName, data, batchSize = 500) {
  console.log(`\n📤 Processing ${data.length} documents for '${collectionName}'...`);
  
  if (data.length === 0) {
    console.warn(`⚠️ No data to upload for '${collectionName}'`);
    return { totalAdded: 0, totalUpdated: 0, totalSkipped: 0 };
  }
  
  // First check for existing documents
  const { existingDocs, newDocs } = await checkExistingDocuments(collectionName, data);
  
  let batch = db.batch();
  let count = 0;
  let totalAdded = 0;
  let totalUpdated = 0;
  let totalSkipped = existingDocs.length;

  // Upload new documents
  for (const item of newDocs) {
    let docRef;
    
    if (item.id) {
      docRef = db.collection(collectionName).doc(item.id);
    } else {
      docRef = db.collection(collectionName).doc();
    }
    
    const { id, ...dataWithoutId } = item;
    batch.set(docRef, dataWithoutId);
    count++;
    totalAdded++;

    if (count === batchSize) {
      await batch.commit();
      console.log(`✅ Committed ${count} new documents`);
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
    console.log(`✅ Committed final ${count} new documents`);
  }

  // Update existing documents
  if (existingDocs.length > 0) {
    console.log(`\n🔄 Updating ${existingDocs.length} existing documents...`);
    let updateBatch = db.batch();
    let updateCount = 0;
    
    for (const item of existingDocs) {
      if (item.id) {
        const docRef = db.collection(collectionName).doc(item.id);
        const { id, ...dataWithoutId } = item;
        updateBatch.update(docRef, dataWithoutId);
        updateCount++;
        totalUpdated++;
        
        if (updateCount === batchSize) {
          await updateBatch.commit();
          console.log(`✅ Updated ${updateCount} documents`);
          updateBatch = db.batch();
          updateCount = 0;
        }
      }
    }
    
    if (updateCount > 0) {
      await updateBatch.commit();
      console.log(`✅ Updated final ${updateCount} documents`);
    }
  }

  console.log(`\n✅ '${collectionName}' upload complete:
    - New documents added: ${totalAdded}
    - Existing documents updated: ${totalUpdated}
    - Skipped (duplicates): ${totalSkipped}
  `);
  
  return { totalAdded, totalUpdated, totalSkipped };
}

// ✅ Auto-generate IDs if not present
function addIdsToData(data, prefix) {
  console.log(`\n🆔 Adding IDs to ${data.length} items with prefix '${prefix}'...`);
  
  let idCounter = 0;
  return data.map((item) => {
    if (!item.id) {
      idCounter++;
      return {
        ...item,
        id: `${prefix}_${String(idCounter).padStart(4, '0')}`
      };
    }
    return item;
  });
}

// Validate JSON data
function validateData(data, collectionName) {
  if (!data) {
    throw new Error(`Invalid data for ${collectionName}: Data is null or undefined`);
  }
  if (!Array.isArray(data)) {
    throw new Error(`Invalid data for ${collectionName}: Expected an array, got ${typeof data}`);
  }
  if (data.length === 0) {
    console.warn(`⚠️ Warning: Empty data for ${collectionName}`);
  }
  return data;
}

// Load and upload data
async function uploadAllData() {
  console.log('\n🚀 Starting Firestore Data Upload...');
  console.log('=' .repeat(60));
  console.log(`📂 Data directory: ${DATA_DIR}`);
  
  try {
    // Check if data directory exists
    if (!fs.existsSync(DATA_DIR)) {
      console.error(`❌ Data directory not found: ${DATA_DIR}`);
      console.error('📌 Please create a "data" folder and add your JSON files.');
      process.exit(1);
    }
    
    // List all files in data directory
    console.log('\n📁 Files in data directory:');
    const files = fs.readdirSync(DATA_DIR);
    files.forEach(file => console.log(`   - ${file}`));
    console.log('');

    let totalExams = 0;
    let totalQuestions = 0;
    let totalVocabulary = 0;

    // ===== Upload Exams =====
    if (fs.existsSync(DATA_FILES.exams)) {
      console.log('\n📄 Reading exams.json...');
      let examsData = JSON.parse(fs.readFileSync(DATA_FILES.exams, 'utf8'));
      console.log(`   Found ${examsData.length} exam entries`);
      
      // Add IDs if missing
      examsData = addIdsToData(examsData, 'exam');
      
      // Check for duplicates
      const uniqueExams = checkForDuplicates(examsData, 'exams');
      const validExams = validateData(uniqueExams, 'exams');
      const result = await uploadCollection(COLLECTIONS.EXAMS, validExams);
      totalExams = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping exams.json - file not found');
    }

    // ===== Upload Questions =====
    if (fs.existsSync(DATA_FILES.questions)) {
      console.log('\n📄 Reading questions.json...');
      let questionsData = JSON.parse(fs.readFileSync(DATA_FILES.questions, 'utf8'));
      console.log(`   Found ${questionsData.length} question entries`);
      
      // Add IDs if missing
      questionsData = addIdsToData(questionsData, 'q');
      
      const uniqueQuestions = checkForDuplicates(questionsData, 'questions');
      const validQuestions = validateData(uniqueQuestions, 'questions');
      const result = await uploadCollection(COLLECTIONS.QUESTIONS, validQuestions);
      totalQuestions = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping questions.json - file not found');
    }

    // ===== Upload Vocabulary =====
    if (fs.existsSync(DATA_FILES.vocabulary)) {
      console.log('\n📄 Reading vocabulary.json...');
      let vocabularyData = JSON.parse(fs.readFileSync(DATA_FILES.vocabulary, 'utf8'));
      console.log(`   Found ${vocabularyData.length} vocabulary entries`);
      
      // ✅ Add IDs if missing
      vocabularyData = addIdsToData(vocabularyData, 'vocab');
      
      // ✅ Check for duplicates
      const uniqueVocabulary = checkForDuplicates(vocabularyData, 'vocabulary');
      const validVocabulary = validateData(uniqueVocabulary, 'vocabulary');
      const result = await uploadCollection(COLLECTIONS.VOCABULARY, validVocabulary);
      totalVocabulary = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping vocabulary.json - file not found');
    }

    console.log('\n' + '=' .repeat(60));
    console.log('🎉 All data uploaded successfully!');
    console.log(`📊 Summary:
    - Exams: ${totalExams}
    - Questions: ${totalQuestions}
    - Vocabulary: ${totalVocabulary}
    `);

  } catch (error) {
    console.error('\n❌ Upload failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// Run the upload
uploadAllData();