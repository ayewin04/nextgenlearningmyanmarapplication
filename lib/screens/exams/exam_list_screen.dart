// lib/screens/exams/exam_list_screen.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/exam_model.dart';
import '../../widgets/exam_card.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<ExamModel> _exams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exams = await _firestoreService.getExams();
      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load exams: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Exams'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadExams,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadExams,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_exams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No exams available yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        return ExamCard(exam: _exams[index]);
      },
    );
  }
}