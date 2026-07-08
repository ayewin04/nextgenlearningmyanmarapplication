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
  EXAM_VOCABULARY: 'exam_vocabulary',
  KANJI: 'kanji',
  GRAMMAR: 'grammar',
  IELTS_QUESTIONS: 'ielts_questions',
  HSK_QUESTIONS: 'hsk_questions',
  JLPT_QUESTIONS: 'jlpt_questions',
  TOPIK_QUESTIONS: 'topik_questions',
  DAILY_CHALLENGES: 'daily_challenges'
};

// Data file paths
const DATA_DIR = path.join(__dirname, '../data');
console.log('📂 Data directory:', DATA_DIR);

const DATA_FILES = {
  exams: path.join(DATA_DIR, 'exams.json'),
  questions: path.join(DATA_DIR, 'questions.json'),
  vocabulary: path.join(DATA_DIR, 'vocabulary.json'),
  exam_vocabulary: path.join(DATA_DIR, 'exam_vocabulary.json'),
  kanji: path.join(DATA_DIR, 'kanji.json'),
  grammar: path.join(DATA_DIR, 'grammar.json'),
  ielts_questions: path.join(DATA_DIR, 'ielts_questions.json'),
  hsk_questions: path.join(DATA_DIR, 'hsk_questions.json'),
  jlpt_questions: path.join(DATA_DIR, 'jlpt_questions.json'),
  topik_questions: path.join(DATA_DIR, 'topik_questions.json'),
};

// ✅ Retry function with exponential backoff
async function retryOperation(operation, maxRetries = 5) {
  let lastError;
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      console.log(`⚠️ Attempt ${i + 1}/${maxRetries} failed: ${error.message}`);
      if (i < maxRetries - 1) {
        const delay = Math.pow(2, i) * 1000;
        console.log(`⏳ Waiting ${delay/1000}s before retry...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  throw lastError;
}

// ✅ Check for duplicates in data using ID
function checkForDuplicates(data, collectionName) {
  console.log(`\n🔍 Checking for duplicates in '${collectionName}'...`);
  
  const seen = new Map();
  const duplicates = [];
  const uniqueData = [];
  let duplicateCount = 0;
  
  for (const item of data) {
    let key;
    if (item.id) {
      key = item.id;
    } else {
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
    const duplicateReport = {
      totalDuplicates: duplicateCount,
      collection: collectionName,
      duplicates: duplicates.map(d => ({
        duplicate: d.item.id || d.item.burmeseWord || 'Unknown',
        existing: d.existingItem.id || d.existingItem.burmeseWord || 'Unknown'
      }))
    };
    const reportPath = path.join(DATA_DIR, `duplicates_report_${collectionName}.json`);
    fs.writeFileSync(reportPath, JSON.stringify(duplicateReport, null, 2));
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
    if (item.id) {
      try {
        const docRef = db.collection(collectionName).doc(item.id);
        const doc = await retryOperation(() => docRef.get(), 3);
        
        if (doc.exists) {
          existingCount++;
          existingDocs.push(item);
          console.log(`📄 Document exists: ${item.id}`);
        } else {
          newCount++;
          newDocs.push(item);
          console.log(`✨ New document: ${item.id}`);
        }
      } catch (error) {
        console.log(`⚠️ Error checking ${item.id}: ${error.message}`);
        newCount++;
        newDocs.push(item);
      }
    } else {
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
      await retryOperation(() => batch.commit(), 3);
      console.log(`✅ Committed ${count} new documents`);
      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await retryOperation(() => batch.commit(), 3);
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
          await retryOperation(() => updateBatch.commit(), 3);
          console.log(`✅ Updated ${updateCount} documents`);
          updateBatch = db.batch();
          updateCount = 0;
        }
      }
    }
    
    if (updateCount > 0) {
      await retryOperation(() => updateBatch.commit(), 3);
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
  if (!data || !Array.isArray(data)) {
    console.log(`⚠️ Cannot add IDs: data is not an array (${typeof data})`);
    return [];
  }
  
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

// ✅ MAIN FUNCTION
async function uploadAllData() {
  console.log('\n🚀 Starting Firestore Data Upload...');
  console.log('=' .repeat(60));
  console.log(`📂 Data directory: ${DATA_DIR}`);
  
  try {
    if (!fs.existsSync(DATA_DIR)) {
      console.error(`❌ Data directory not found: ${DATA_DIR}`);
      process.exit(1);
    }
    
    console.log('\n📁 Files in data directory:');
    const files = fs.readdirSync(DATA_DIR);
    files.forEach(file => console.log(`   - ${file}`));
    console.log('');

    let totalExams = 0;
    let totalQuestions = 0;
    let totalVocabulary = 0;
    let totalExamVocabulary = 0;
    let totalGrammar = 0;
    let totalKanji = 0;
    let totalIeltsQuestions = 0;
    let totalHskQuestions = 0;
    let totalJlptQuestions = 0;
    let totalTopikQuestions = 0;

    // ===== Upload Exams =====
    if (fs.existsSync(DATA_FILES.exams)) {
      console.log('\n📄 Reading exams.json...');
      let examsData = JSON.parse(fs.readFileSync(DATA_FILES.exams, 'utf8'));
      console.log(`   Found ${examsData.length} exam entries`);
      examsData = addIdsToData(examsData, 'exam');
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
      vocabularyData = addIdsToData(vocabularyData, 'vocab');
      const uniqueVocabulary = checkForDuplicates(vocabularyData, 'vocabulary');
      const validVocabulary = validateData(uniqueVocabulary, 'vocabulary');
      const result = await uploadCollection(COLLECTIONS.VOCABULARY, validVocabulary);
      totalVocabulary = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping vocabulary.json - file not found');
    }

    // ===== Upload Exam Vocabulary =====
    if (fs.existsSync(DATA_FILES.exam_vocabulary)) {
      console.log('\n📄 Reading exam_vocabulary.json...');
      let examVocabData = JSON.parse(fs.readFileSync(DATA_FILES.exam_vocabulary, 'utf8'));
      console.log(`   Found ${examVocabData.length} exam vocabulary entries`);
      examVocabData = addIdsToData(examVocabData, 'ev');
      const uniqueExamVocab = checkForDuplicates(examVocabData, 'exam_vocabulary');
      const validExamVocab = validateData(uniqueExamVocab, 'exam_vocabulary');
      const result = await uploadCollection(COLLECTIONS.EXAM_VOCABULARY, validExamVocab);
      totalExamVocabulary = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping exam_vocabulary.json - file not found');
    }

    // ===== Upload Grammar =====
    if (fs.existsSync(DATA_FILES.grammar)) {
      console.log('\n📄 Reading grammar.json...');
      let grammarData = JSON.parse(fs.readFileSync(DATA_FILES.grammar, 'utf8'));
      console.log(`   Found ${grammarData.length} grammar entries`);
      grammarData = addIdsToData(grammarData, 'gram');
      const uniqueGrammar = checkForDuplicates(grammarData, 'grammar');
      const validGrammar = validateData(uniqueGrammar, 'grammar');
      const result = await uploadCollection(COLLECTIONS.GRAMMAR, validGrammar);
      totalGrammar = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping grammar.json - file not found');
    }

    // ===== Upload Kanji =====
    if (fs.existsSync(DATA_FILES.kanji)) {
      console.log('\n📄 Reading kanji.json...');
      let kanjiData = JSON.parse(fs.readFileSync(DATA_FILES.kanji, 'utf8'));
      console.log(`   Found ${kanjiData.length} kanji entries`);
      kanjiData = addIdsToData(kanjiData, 'kanji');
      const uniqueKanji = checkForDuplicates(kanjiData, 'kanji');
      const validKanji = validateData(uniqueKanji, 'kanji');
      const result = await uploadCollection(COLLECTIONS.KANJI, validKanji);
      totalKanji = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping kanji.json - file not found');
    }

    // ===== Upload IELTS Questions =====
    if (fs.existsSync(DATA_FILES.ielts_questions)) {
      console.log('\n📄 Reading ielts_questions.json...');
      let ieltsData = JSON.parse(fs.readFileSync(DATA_FILES.ielts_questions, 'utf8'));
      console.log(`   Found ${ieltsData.length} IELTS questions`);
      ieltsData = addIdsToData(ieltsData, 'ielts');
      const uniqueIelts = checkForDuplicates(ieltsData, 'ielts_questions');
      const validIelts = validateData(uniqueIelts, 'ielts_questions');
      const result = await uploadCollection(COLLECTIONS.IELTS_QUESTIONS, validIelts);
      totalIeltsQuestions = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping ielts_questions.json - file not found');
    }

    // ===== Upload HSK Questions =====
    if (fs.existsSync(DATA_FILES.hsk_questions)) {
      console.log('\n📄 Reading hsk_questions.json...');
      let hskData = JSON.parse(fs.readFileSync(DATA_FILES.hsk_questions, 'utf8'));
      console.log(`   Found ${hskData.length} HSK questions`);
      hskData = addIdsToData(hskData, 'hsk');
      const uniqueHsk = checkForDuplicates(hskData, 'hsk_questions');
      const validHsk = validateData(uniqueHsk, 'hsk_questions');
      const result = await uploadCollection(COLLECTIONS.HSK_QUESTIONS, validHsk);
      totalHskQuestions = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping hsk_questions.json - file not found');
    }

    // ===== Upload JLPT Questions =====
    if (fs.existsSync(DATA_FILES.jlpt_questions)) {
      console.log('\n📄 Reading jlpt_questions.json...');
      let jlptData = JSON.parse(fs.readFileSync(DATA_FILES.jlpt_questions, 'utf8'));
      console.log(`   Found ${jlptData.length} JLPT questions`);
      jlptData = addIdsToData(jlptData, 'jlpt');
      const uniqueJlpt = checkForDuplicates(jlptData, 'jlpt_questions');
      const validJlpt = validateData(uniqueJlpt, 'jlpt_questions');
      const result = await uploadCollection(COLLECTIONS.JLPT_QUESTIONS, validJlpt);
      totalJlptQuestions = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping jlpt_questions.json - file not found');
    }

    // ===== Upload TOPIK Questions =====
    if (fs.existsSync(DATA_FILES.topik_questions)) {
      console.log('\n📄 Reading topik_questions.json...');
      let topikData = JSON.parse(fs.readFileSync(DATA_FILES.topik_questions, 'utf8'));
      console.log(`   Found ${topikData.length} TOPIK questions`);
      topikData = addIdsToData(topikData, 'topik');
      const uniqueTopik = checkForDuplicates(topikData, 'topik_questions');
      const validTopik = validateData(uniqueTopik, 'topik_questions');
      const result = await uploadCollection(COLLECTIONS.TOPIK_QUESTIONS, validTopik);
      totalTopikQuestions = result.totalAdded + result.totalUpdated;
    } else {
      console.log('⚠️ Skipping topik_questions.json - file not found');
    }

    console.log('\n' + '=' .repeat(60));
    console.log('🎉 All data uploaded successfully!');
    console.log(`📊 Summary:
    - Exams: ${totalExams}
    - Questions: ${totalQuestions}
    - Vocabulary: ${totalVocabulary}
    - Exam Vocabulary: ${totalExamVocabulary}
    - Grammar: ${totalGrammar}
    - IELTS Questions: ${totalIeltsQuestions}
    - HSK Questions: ${totalHskQuestions}
    - JLPT Questions: ${totalJlptQuestions}
    - TOPIK Questions: ${totalTopikQuestions}
    `);

  } catch (error) {
    console.error('\n❌ Upload failed:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

// ✅ Run the upload
uploadAllData();