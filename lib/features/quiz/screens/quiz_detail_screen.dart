import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- Need Provider
import '../../../core/models/quiz_model.dart';
import '../../../core/models/quiz_attempt_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart'; // <--- Import AuthProvider
import 'quiz_taking_screen.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;
  final String courseId;
  final bool isInstructor;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
    required this.courseId,
    required this.isInstructor,
  });

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
      final authProvider = context.read<AuthProvider>(); // Get current user

      // Get quiz directly by ID
      final quizData = await apiService.getQuizById(widget.quizId);

      if (quizData != null) {
        _quiz = QuizModel.fromJson(quizData);
      }

      // Get attempts
      final attemptsData = await apiService.getQuizAttempts(widget.quizId);
      final allAttempts = attemptsData
          .map((json) => QuizAttemptModel.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          // ✅ FIX: Filter attempts
          if (widget.isInstructor) {
            _attempts = allAttempts; // Instructors see everything
          } else {
            // Students only see their own attempts
            _attempts = allAttempts
                .where((a) => a.studentId == authProvider.user?.id)
                .toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading quiz details: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startQuiz() {
    if (_quiz == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizTakingScreen(
          quizId: widget.quizId,
          quizTitle: _quiz!.title,
          durationMinutes: _quiz!.durationMinutes,
        ),
      ),
    ).then((_) => _loadData()); // Reload after quiz
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Check Expiration
    bool isExpired = false;
    bool isNotStarted = false;
    final now = DateTime.now();

    if (_quiz != null) {
      isExpired = now.isAfter(_quiz!.closeTime);
      isNotStarted = now.isBefore(_quiz!.openTime);
    }

    // Determine Button State
    bool canStart = !isExpired && !isNotStarted;
    String buttonText = 'Start Quiz';
    if (isExpired) buttonText = 'Quiz Closed';
    if (isNotStarted) buttonText = 'Not Started Yet';

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quiz == null
              ? const Center(child: Text('Quiz not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quiz Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _quiz!.title,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              if (_quiz!.description.isNotEmpty) ...[
                                Text(_quiz!.description),
                                const SizedBox(height: 16),
                              ],
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.timer, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                      'Duration: ${_quiz!.durationMinutes} minutes'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.repeat, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Max Attempts: ${_quiz!.maxAttempts}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Open: ${_quiz!.openTime.day}/${_quiz!.openTime.month}/${_quiz!.openTime.year}',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.event_busy, size: 20, color: isExpired ? Colors.red : null),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Close: ${_quiz!.closeTime.day}/${_quiz!.closeTime.month}/${_quiz!.closeTime.year}',
                                    style: TextStyle(
                                      color: isExpired ? Colors.red : null,
                                      fontWeight: isExpired ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Start Quiz Button (Students only)
                      if (!widget.isInstructor) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            // ✅ FIX: Disable button if expired
                            onPressed: canStart ? _startQuiz : null,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(buttonText),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey, // Grey out when disabled
                              disabledForegroundColor: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Attempts Section
                      Text(
                        widget.isInstructor
                            ? 'Student Attempts (${_attempts.length})'
                            : 'Your Attempts (${_attempts.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),

                      if (_attempts.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('No attempts yet'),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _attempts.length,
                          itemBuilder: (context, index) {
                            final attempt = _attempts[index];
                            final isPassed = attempt.score >= 70;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      isPassed ? Colors.green : Colors.red,
                                  child: Text(
                                    '${attempt.attemptNumber}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  widget.isInstructor
                                      ? attempt.studentName
                                      : 'Attempt ${attempt.attemptNumber}',
                                ),
                                subtitle: attempt.submittedAt != null
                                    ? Text(
                                        'Submitted: ${attempt.submittedAt!.day}/${attempt.submittedAt!.month}/${attempt.submittedAt!.year} ${attempt.submittedAt!.hour}:${attempt.submittedAt!.minute.toString().padLeft(2, '0')}',
                                      )
                                    : const Text('In progress'),
                                trailing: Chip(
                                  label: Text(
                                    '${attempt.score.toInt()}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor:
                                      isPassed ? Colors.green : Colors.red,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}