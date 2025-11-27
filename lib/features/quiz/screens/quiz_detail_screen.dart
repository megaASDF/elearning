import 'package:flutter/material.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/models/quiz_attempt_model.dart';
import '../../../core/services/api_service.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;
  final bool isInstructor;

  const QuizDetailScreen({super.key, required this.quizId, required this.isInstructor});

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  QuizModel? _quiz;
  List<QuizAttemptModel> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final quizData = await apiService.getQuizzes(''); // Filter by ID in real app
      final attemptsData = await apiService.getQuizAttempts(widget.quizId);

      if (mounted) {
        setState(() {
          // _quiz = ... parse quiz
          _attempts = attemptsData.map((json) => QuizAttemptModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quiz Details', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  if (widget.isInstructor) ...[
                    Text('Attempts (${_attempts.length})', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = _attempts[index];
                        return Card(
                          child: ListTile(
                            title: Text(attempt.studentName),
                            subtitle: Text('Submitted: ${attempt.submittedAt?.day}/${attempt.submittedAt?.month}/${attempt.submittedAt?.year}'),
                            trailing: Chip(label: Text('${attempt.score.toInt()}%'), backgroundColor: Colors.green),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}