// lib/screens/exams/exam_question_screen.dart
import 'package:flutter/material.dart';
import '../../models/exam_model.dart';
import '../../models/question_model.dart';

class ExamQuestionScreen extends StatefulWidget {
  final QuestionModel question;
  final ExamModel exam;

  const ExamQuestionScreen({
    super.key,
    required this.question,
    required this.exam,
  });

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  String? _selectedAnswer;
  bool _isAnswered = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse('FF${widget.exam.color.replaceAll('#', '')}', radix: 16),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exam.name} Question'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.question.category,
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.question.level,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.question.points} pts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question Text
            Text(
              widget.question.questionText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Options
            ...widget.question.options!.map((option) {
              final isSelected = _selectedAnswer == option;
              final isCorrectOption = option == widget.question.correctAnswer;
              
              Color? optionColor;
              if (_isAnswered) {
                if (isCorrectOption) {
                  optionColor = Colors.green;
                } else if (isSelected && !isCorrectOption) {
                  optionColor = Colors.red;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: optionColor ?? Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: optionColor?.withOpacity(0.1) ?? Colors.transparent,
                ),
                child: RadioListTile<String>(
                  value: option,
                  groupValue: _selectedAnswer,
                  onChanged: _isAnswered ? null : (value) {
                    setState(() {
                      _selectedAnswer = value;
                    });
                  },
                  title: Text(
                    option,
                    style: TextStyle(
                      color: optionColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  activeColor: Colors.blue,
                  dense: true,
                ),
              );
            }),

            const SizedBox(height: 24),

            // Submit Button
            if (!_isAnswered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedAnswer == null ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Answer',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

            // Result
            if (_isAnswered)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCorrect ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle : Icons.cancel,
                          color: _isCorrect ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isCorrect ? '✅ Correct!' : '❌ Incorrect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _isCorrect ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_isCorrect)
                      Text(
                        'Correct answer: ${widget.question.correctAnswer}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(height: 12),
                    if (widget.question.aiExplanation != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💡 Explanation:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.question.aiExplanation!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Next Question'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _submitAnswer() {
    final isCorrect = _selectedAnswer == widget.question.correctAnswer;
    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    // TODO: Save progress to Firestore
  }
}