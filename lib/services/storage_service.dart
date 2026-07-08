import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload audio file
  Future<String> uploadAudio({
    required File file,
    required String userId,
    required String exam,
    String? fileName,
  }) async {
    try {
      String filePath = 'audio/$exam/$userId/${fileName ?? path.basename(file.path)}';
      Reference ref = _storage.ref().child(filePath);
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }

  // Upload image
  Future<String> uploadImage({
    required File file,
    required String userId,
    String? fileName,
  }) async {
    try {
      String filePath = 'images/$userId/${fileName ?? path.basename(file.path)}';
      Reference ref = _storage.ref().child(filePath);
      
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete file
  Future<void> deleteFile(String url) async {
    try {
      Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Get download URL
  Future<String> getDownloadURL(String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  // Upload text file (for writing practice)
  Future<String> uploadTextFile({
    required String content,
    required String userId,
    required String exam,
    required String questionId,
  }) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.txt';
      String filePath = 'writing/$exam/$userId/$questionId/$fileName';
      
      Reference ref = _storage.ref().child(filePath);
      
      // Convert string to bytes
      List<int> bytes = content.codeUnits;
      
      UploadTask uploadTask = ref.putData(bytes);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload text: $e');
    }
  }

  // Upload speaking recording
  Future<String> uploadSpeakingRecording({
    required File audioFile,
    required String userId,
    required String exam,
    required String questionId,
  }) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      String filePath = 'speaking/$exam/$userId/$questionId/$fileName';
      
      Reference ref = _storage.ref().child(filePath);
      
      UploadTask uploadTask = ref.putFile(audioFile);
      TaskSnapshot snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload speaking recording: $e');
    }
  }
}