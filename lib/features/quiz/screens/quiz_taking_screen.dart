import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class QuizTakingScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int durationMinutes;

  const QuizTakingScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.durationMinutes,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final Map<String, int> _selectedAnswers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _questions = [];
  int _remainingSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);

    try {
      // 🛑 VALIDATION: Check dates before letting the student start 🛑
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (quizDoc.exists) {
        final data = quizDoc.data()!;
        final now = DateTime.now();

        // 1. Check Start Date
        if (data['startDate'] != null) {
          final startDate = (data['startDate'] as Timestamp).toDate();
          if (now.isBefore(startDate)) {
            if (mounted) {
              await _showErrorDialog(
                  'Quiz Not Started', 'This quiz opens on $startDate');
              Navigator.of(context).pop(); // Exit screen
              return;
            }
          }
        }

        // 2. Check Deadline
        if (data['deadline'] != null) {
          final deadline = (data['deadline'] as Timestamp).toDate();
          if (now.isAfter(deadline)) {
            if (mounted) {
              await _showErrorDialog(
                  'Quiz Expired', 'The deadline for this quiz has passed.');
              Navigator.of(context).pop(); // Exit screen
              return;
            }
          }
        }
      }

      // Generate mock questions for now (Replace with real questions fetch)
      _questions = List.generate(10, (index) => {
        'id': 'q${index + 1}',
        'question': 'Question ${index + 1}: What is ${index + 2} + ${index + 3}?',
        'options': [
          '${index + 2 + index + 3}',
          '${index + 1}',
          '${index + 5}',
          '${index + 10}',
        ],
        'correctAnswer': 0,
        'difficulty': index < 3 ? 'easy' : index < 7 ? 'medium' : 'hard',
      });

      _remainingSeconds = widget.durationMinutes * 60;
      _startTimer();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading quiz: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
      }
    }
  }

  Future<void> _showErrorDialog(String title, String content) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();

      // 🛑 VALIDATION: Double-check deadline before submitting 🛑
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(widget.quizId)
          .get();

      if (quizDoc.exists) {
        final data = quizDoc.data()!;
        if (data['deadline'] != null) {
          final deadline = (data['deadline'] as Timestamp).toDate();
          if (DateTime.now().isAfter(deadline)) {
            throw Exception("The deadline for this quiz has passed. Submission rejected.");
          }
        }
      }

      // Calculate score
      int correctCount = 0;
      for (var entry in _selectedAnswers.entries) {
        final questionIndex = int.parse(entry.key);
        final selectedAnswer = entry.value;
        final correctAnswer = _questions[questionIndex]['correctAnswer'];

        if (selectedAnswer == correctAnswer) {
          correctCount++;
        }
      }

      final score = (_questions.isEmpty
          ? 0.0
          : (correctCount / _questions.length) * 100);

      // Start attempt
      final attempt = await apiService.startQuizAttempt(
        widget.quizId,
        authProvider.user?.id ?? '',
        authProvider.user?.displayName ?? '',
      );

      // Submit attempt with answers
      await apiService.submitQuizAttempt(
        attempt['id'],
        _selectedAnswers,
      );

      // Update score
      await FirebaseFirestore.instance
          .collection('quizAttempts')
          .doc(attempt['id'])
          .update({'score': score});

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              score: score,
              correctCount: correctCount,
              totalQuestions: _questions.length,
              answers: _selectedAnswers,
              questions: _questions,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting quiz: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost if you exit now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isTimeRunningOut = _remainingSeconds < 60;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.quizTitle),
          backgroundColor: isTimeRunningOut ? Colors.red : null,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: isTimeRunningOut ? Colors.white : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTimeRunningOut ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: _selectedAnswers.length / _questions.length,
              backgroundColor: Colors.grey[300],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Question ${_selectedAnswers.length}/${_questions.length} answered',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),

            // Questions
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final isAnswered =
                      _selectedAnswers.containsKey(index.toString());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isAnswered ? Colors.blue.shade50 : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: question['difficulty'] == 'easy'
                                      ? Colors.green
                                      : question['difficulty'] == 'medium'
                                          ? Colors.orange
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  question['difficulty'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (isAnswered)
                                const Icon(Icons.check_circle,
                                    color: Colors.green),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Q${index + 1}.  ${question['question']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            (question['options'] as List).length,
                            (optionIndex) {
                              final option = question['options'][optionIndex];
                              final isSelected =
                                  _selectedAnswers[index.toString()] ==
                                      optionIndex;

                              return RadioListTile<int>(
                                value: optionIndex,
                                groupValue: _selectedAnswers[index.toString()],
                                title: Text(option),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAnswers[index.toString()] = value!;
                                  });
                                },
                                selected: isSelected,
                                activeColor: Colors.blue,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Submit button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (_selectedAnswers.length < _questions.length) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Submit Quiz?'),
                                content: Text(
                                  'You have answered ${_selectedAnswers.length}/${_questions.length} questions.  Submit anyway?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Submit'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              _submitQuiz();
                            }
                          } else {
                            _submitQuiz();
                          }
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label:
                      Text(_isSubmitting ? 'Submitting...' : 'Submit Quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quiz Result Screen
class QuizResultScreen extends StatelessWidget {
  final double score;
  final int correctCount;
  final int totalQuestions;
  final Map<String, int> answers;
  final List<Map<String, dynamic>> questions;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.answers,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score Card
            Card(
              color:
                  score >= 70 ? Colors.green.shade50 : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      score >= 70 ? Icons.check_circle : Icons.cancel,
                      size: 64,
                      color: score >= 70 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${score.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: score >= 70 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$correctCount out of $totalQuestions correct',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      score >= 70 ? 'Passed!' : 'Failed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: score >= 70 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Review Answers
            Text(
              'Review Your Answers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...List.generate(questions.length, (index) {
              final question = questions[index];
              final userAnswer = answers[index.toString()];
              final correctAnswer = question['correctAnswer'];
              final isCorrect = userAnswer == correctAnswer;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color:
                    isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Q${index + 1}.  ${question['question']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (userAnswer != null) ...[
                        Text('Your answer: ${question['options'][userAnswer]}'),
                        if (!isCorrect) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Correct answer: ${question['options'][correctAnswer]}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ] else
                        const Text(
                          'Not answered',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Back to Course'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}