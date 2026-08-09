import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/vocabulary_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store the last document reference for pagination
  DocumentSnapshot? _lastGrammarDoc;
  DocumentSnapshot? _lastVocabDoc;

  // ============ VOCABULARY PAGINATION ============
  
  Future<List<VocabularyModel>> getVocabularyByLevelPaginated({
    required String exam,
    required String level,
    required String language,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('vocabulary')
          .where('exam', isEqualTo: exam)
          .where('level', isEqualTo: level)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastVocabDoc = snapshot.docs.last;
      }
      
      return snapshot.docs
          .map((doc) => VocabularyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((vocab) => vocab.translations.containsKey(language))
          .toList();
    } catch (e) {
      throw Exception('Failed to load vocabulary: $e');
    }
  }

  DocumentSnapshot? getLastVocabDoc() => _lastVocabDoc;
  void resetVocabPagination() => _lastVocabDoc = null;

  // ============ GET VOCABULARY BY IDS (with batching) ============
  
  Future<List<VocabularyModel>> getVocabularyByIds({
    required List<String> wordIds,
    required String language,
  }) async {
    if (wordIds.isEmpty) return [];
    
    try {
      List<VocabularyModel> allVocabulary = [];
      
      // Firestore whereIn supports max 30 items
      for (var i = 0; i < wordIds.length; i += 30) {
        final end = (i + 30) > wordIds.length ? wordIds.length : i + 30;
        final batchIds = wordIds.sublist(i, end);
        
        final snapshot = await _firestore
            .collection('vocabulary')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        
        final batchVocabulary = snapshot.docs
            .map((doc) => VocabularyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .where((vocab) => vocab.translations.containsKey(language))
            .toList();
        
        allVocabulary.addAll(batchVocabulary);
      }
      
      // Preserve the original order
      final Map<String, VocabularyModel> vocabMap = {
        for (var vocab in allVocabulary) vocab.id: vocab
      };
      
      return wordIds
          .where((id) => vocabMap.containsKey(id))
          .map((id) => vocabMap[id]!)
          .toList();
    } catch (e) {
      throw Exception('Failed to load vocabulary: $e');
    }
  }

  // ============ EXAMS ============
  
  Future<List<ExamModel>> getExams() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exams')
          .get();
      
      return snapshot.docs
          .map((doc) => ExamModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load exams: $e');
    }
  }

  // ============ QUESTIONS ============
  
  Future<List<QuestionModel>> getQuestions({
    required String exam,
    String? level,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('questions')
          .where('exam', isEqualTo: exam);
      
      if (level != null) {
        query = query.where('level', isEqualTo: level);
      }
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      QuerySnapshot snapshot = await query
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  Future<List<QuestionModel>> getQuestionsByLevel({
    required String exam,
    required String level,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('questions')
          .where('exam', isEqualTo: exam)
          .where('level', isEqualTo: level);
      
      QuerySnapshot snapshot = await query
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  // ============ VOCABULARY ============
  
  Future<List<VocabularyModel>> getVocabularyByLanguage({
    required String language,
    int limit = 50,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('vocabulary')
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => VocabularyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((vocab) => vocab.translations.containsKey(language))
          .toList();
    } catch (e) {
      throw Exception('Failed to load vocabulary: $e');
    }
  }

  Future<List<VocabularyModel>> getVocabularyByPartOfSpeech({
    required String partOfSpeech,
    int limit = 20,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('vocabulary')
          .where('partOfSpeech', isEqualTo: partOfSpeech)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => VocabularyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load vocabulary: $e');
    }
  }

  Future<List<VocabularyModel>> getVocabulary({
    required String exam,
    String? level,
    int limit = 50,
  }) async {
    try {
      return await getVocabularyByLanguage(language: exam, limit: limit);
    } catch (e) {
      throw Exception('Failed to load vocabulary: $e');
    }
  }

  Future<List<VocabularyModel>> getVocabularyByLevel({
    required String exam,
    required String level,
    required String language,
    int limit = 5000,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('vocabulary')
          .where('exam', isEqualTo: exam)
          .where('level', isEqualTo: level)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => VocabularyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((vocab) => vocab.translations.containsKey(language))
          .toList();
    } catch (e) {
      throw Exception('Failed to load vocabulary: $e');
    }
  }

  Future<List<VocabularyModel>> getVocabularyByCategory({
    required String category,
    required String language,
    int limit = 5000,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('vocabulary')
          .where('category', isEqualTo: category)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => VocabularyModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((vocab) => vocab.translations.containsKey(language))
          .toList();
    } catch (e) {
      throw Exception('Failed to load vocabulary: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('vocabulary')
          .limit(100)
          .get();
      
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('category')) {
          categories.add(data['category'] as String);
        }
      }
      return categories.toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  // ============ EXAM VOCABULARY ============
  
  Future<List<Map<String, dynamic>>> getExamVocabulary({
    required String exam,
    String? level,
    int limit = 5000,
  }) async {
    try {
      Query query = _firestore
          .collection('exam_vocabulary')
          .where('exam', isEqualTo: exam);
      
      if (level != null && level != 'All') {
        query = query.where('level', isEqualTo: level);
      }
      
      QuerySnapshot snapshot = await query
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load exam vocabulary: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getExamVocabularyByLevel({
    required String exam,
    required String level,
    int limit = 5000,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('exam_vocabulary')
          .where('exam', isEqualTo: exam)
          .where('level', isEqualTo: level)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load exam vocabulary: $e');
    }
  }

  Future<Map<String, dynamic>> getExamVocabularyByLevelPaginated({
    required String exam,
    required String level,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('exam_vocabulary')
          .where('exam', isEqualTo: exam)
          .where('level', isEqualTo: level)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      final List<Map<String, dynamic>> data = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .toList();
      
      final bool hasMore = snapshot.docs.length == limit;
      final DocumentSnapshot? lastDocument = snapshot.docs.isNotEmpty 
          ? snapshot.docs.last 
          : null;
      
      return {
        'data': data,
        'lastDocument': lastDocument,
        'hasMore': hasMore,
      };
    } catch (e) {
      throw Exception('Failed to load exam vocabulary: $e');
    }
  }

  // ============ GRAMMAR ============
  
  Future<List<Map<String, dynamic>>> getGrammar({
    required String exam,
    String? level,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('grammar')
          .where('exam', isEqualTo: exam);
      
      if (level != null) {
        query = query.where('level', isEqualTo: level);
      }
      
      QuerySnapshot snapshot = await query
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load grammar: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGrammarByLevel({
    required String exam,
    required String level,
    int limit = 20,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('grammar')
          .where('exam', isEqualTo: exam)
          .where('level', isEqualTo: level)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load grammar: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getGrammarByLevelWithPagination({
    required String exam,
    required String level,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('grammar')
          .where('exam', isEqualTo: exam)
          .where('level', isEqualTo: level)
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastGrammarDoc = snapshot.docs.last;
      }
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['documentId'] = doc.id;
            return data;
          })
          .toList();
    } catch (e) {
      throw Exception('Failed to load grammar: $e');
    }
  }

  DocumentSnapshot? getLastGrammarDoc() {
    return _lastGrammarDoc;
  }

  void resetGrammarPagination() {
    _lastGrammarDoc = null;
  }

  // ============ KANJI ============
  
  Future<List<Map<String, dynamic>>> getKanji() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('kanji')
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load kanji: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getKanjiByLevel({
    required String level,
    int limit = 50,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('kanji')
          .where('jlptLevel', isEqualTo: level)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load kanji by level: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getKanjiByGrade({
    required int grade,
    int limit = 50,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('kanji')
          .where('grade', isEqualTo: grade.toString())
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load kanji by grade: $e');
    }
  }

  Future<Map<String, dynamic>> getKanjiPaginated({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('kanji')
          .limit(limit);
      
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      final List<Map<String, dynamic>> data = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['documentId'] = doc.id;
            return data;
          })
          .toList();
      
      final bool hasMore = snapshot.docs.length == limit;
      final DocumentSnapshot? lastDocument = snapshot.docs.isNotEmpty 
          ? snapshot.docs.last 
          : null;
      
      return {
        'data': data,
        'lastDocument': lastDocument,
        'hasMore': hasMore,
      };
    } catch (e) {
      throw Exception('Failed to load kanji: $e');
    }
  }

  // ============ EXAM QUESTIONS ============
  
  Future<List<QuestionModel>> getExamQuestionsByLevel({
    required String exam,
    required String level,
    int limit = 20,
  }) async {
    try {
      final collectionMap = {
        'ielts': 'ielts_questions',
        'hsk': 'hsk_questions',
        'jlpt': 'jlpt_questions',
        'topik': 'topik_questions',
      };
      
      final collectionName = collectionMap[exam] ?? 'ielts_questions';
      
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .where('level', isEqualTo: level)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load exam questions: $e');
    }
  }

  Future<List<QuestionModel>> getExamQuestions({
    required String exam,
    int limit = 20,
  }) async {
    try {
      final collectionMap = {
        'ielts': 'ielts_questions',
        'hsk': 'hsk_questions',
        'jlpt': 'jlpt_questions',
        'topik': 'topik_questions',
      };
      
      final collectionName = collectionMap[exam] ?? 'ielts_questions';
      
      QuerySnapshot snapshot = await _firestore
          .collection(collectionName)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => QuestionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load exam questions: $e');
    }
  }

  // ============ USER PROGRESS ============
  
  Future<void> saveUserProgress({
    required String userId,
    required String exam,
    required String questionId,
    required bool isCorrect,
    required int points,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot save progress.");
      throw Exception('User not authenticated');
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      throw Exception('User ID mismatch');
    }
    print("✅ User authenticated: ${user.uid}");
    
    try {
      DocumentReference progressRef = _firestore
          .collection('user_progress')
          .doc('$userId-$exam');
      
      await progressRef.set({
        'userId': userId,
        'exam': exam,
        'lastPracticed': FieldValue.serverTimestamp(),
        'questionsAnswered': FieldValue.increment(1),
        'correctAnswers': FieldValue.increment(isCorrect ? 1 : 0),
        'totalPoints': FieldValue.increment(isCorrect ? points : 0),
        'questionHistory': FieldValue.arrayUnion([questionId]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save progress: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProgress({
    required String userId,
    required String exam,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot get progress.");
      return null;
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      return null;
    }
    print("✅ Getting progress for user: ${user.uid}");
    
    try {
      DocumentSnapshot doc = await _firestore
          .collection('user_progress')
          .doc('$userId-$exam')
          .get();
      
      return doc.exists ? doc.data() as Map<String, dynamic>? : null;
    } catch (e) {
      throw Exception('Failed to load progress: $e');
    }
  }

  Future<void> saveLastWordIndex({
    required String userId,
    required String language,
    required String category,
    required int index,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot save last word index.");
      throw Exception('User not authenticated');
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      throw Exception('User ID mismatch');
    }
    print("✅ Saving last word index for user: ${user.uid}");
    
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final String key = '${language}_$category';
      
      await userRef.update({
        'lastWordIndex.$key': index,
      });
    } catch (e) {
      try {
        final userRef = _firestore.collection('users').doc(userId);
        final String key = '${language}_$category';
        
        await userRef.set({
          'lastWordIndex': {
            key: index,
          },
        }, SetOptions(merge: true));
      } catch (innerError) {
        print('Error saving last word index: $innerError');
      }
    }
  }

  Future<int?> getLastWordIndex({
    required String userId,
    required String language,
    required String category,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot get last word index.");
      return null;
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      return null;
    }
    print("✅ Getting last word index for user: ${user.uid}");
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      final lastWordIndex = data['lastWordIndex'] ?? {};
      final String key = '${language}_$category';
      
      return lastWordIndex[key];
    } catch (e) {
      return null;
    }
  }

  Future<void> updateWordsLearned({
    required String userId,
    required String language,
    required String category,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot update words learned.");
      throw Exception('User not authenticated');
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      throw Exception('User ID mismatch');
    }
    print("✅ Updating words learned for user: ${user.uid}");
    
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final wordsLearned = userData['wordsLearned'] ?? 0;
      final wordsPerCategory = Map<String, int>.from(userData['wordsPerCategory'] ?? {});
      final wordsPerLanguage = Map<String, int>.from(userData['wordsPerLanguage'] ?? {});
      
      wordsPerCategory[category] = (wordsPerCategory[category] ?? 0) + 1;
      wordsPerLanguage[language] = (wordsPerLanguage[language] ?? 0) + 1;
      
      await userRef.update({
        'wordsLearned': wordsLearned + 1,
        'wordsPerCategory': wordsPerCategory,
        'wordsPerLanguage': wordsPerLanguage,
        'lastPracticeDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update words learned: $e');
    }
  }

  Future<Map<String, dynamic>> getUserLearningProgress(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot get learning progress.");
      return {};
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      return {};
    }
    print("✅ Getting learning progress for user: ${user.uid}");
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return {};
      
      final data = doc.data()!;
      return {
        'wordsLearned': data['wordsLearned'] ?? 0,
        'wordsPerCategory': Map<String, int>.from(data['wordsPerCategory'] ?? {}),
        'wordsPerLanguage': Map<String, int>.from(data['wordsPerLanguage'] ?? {}),
        'lastPracticeDate': data['lastPracticeDate'],
      };
    } catch (e) {
      throw Exception('Failed to get user progress: $e');
    }
  }

  // ============ FAVOURITES ============

  Future<void> toggleFavourite({
    required String userId,
    required String wordId,
    required String language,
    required bool isFavourite,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot toggle favourite.");
      throw Exception('User not authenticated');
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      throw Exception('User ID mismatch');
    }
    print("✅ Toggling favourite for user: ${user.uid}");
    
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final String fieldName = 'favourites_$language';
      
      if (isFavourite) {
        await userRef.update({
          fieldName: FieldValue.arrayUnion([wordId]),
        });
      } else {
        await userRef.update({
          fieldName: FieldValue.arrayRemove([wordId]),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle favourite: $e');
    }
  }

  Future<List<String>> getFavouriteIds(String userId, String language) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ No user logged in! Cannot get favourites.");
      return [];
    }
    
    if (user.uid != userId) {
      print("❌ User ID mismatch! Logged in: ${user.uid}, Provided: $userId");
      return [];
    }
    print("✅ Getting favourites for user: ${user.uid}");
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return [];
      
      final data = doc.data()!;
      final String fieldName = 'favourites_$language';
      return List<String>.from(data[fieldName] ?? []);
    } catch (e) {
      throw Exception('Failed to get favourites: $e');
    }
  }

  // ============ LEADERBOARD ============
  
  Future<List<Map<String, dynamic>>> getLeaderboard({
    required String exam,
    int limit = 10,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('user_progress')
          .where('exam', isEqualTo: exam)
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to load leaderboard: $e');
    }
  }
}