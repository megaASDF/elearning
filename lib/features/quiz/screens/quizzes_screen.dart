import 'package:flutter/material.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/services/api_service.dart';
import '../widgets/quiz_form_dialog.dart';
import 'quiz_detail_screen.dart';

class QuizzesScreen extends StatefulWidget {
  final String courseId;
  final bool isInstructor;

  const QuizzesScreen({
    super.key,
    required this.courseId,
    required this.isInstructor,
  });

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getQuizzes(widget.courseId);
      if (mounted) {
        setState(() {
          _quizzes = data.map((json) => QuizModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quizzes: $e')),
        );
      }
    }
  }

  Future<void> _showQuizDialog({QuizModel? quiz}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuizFormDialog(
        courseId: widget.courseId,
        quiz: quiz,
      ),
    );

    if (result == true) {
      await _loadQuizzes();
    }
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete "${quiz.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final apiService = ApiService();
        await apiService.deleteQuiz(quiz.id);
        await _loadQuizzes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildStatusChip(QuizModel quiz) {
    if (quiz.isClosed) {
      return const Chip(
        label: Text('Closed', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        visualDensity: VisualDensity.compact,
      );
    } else if (quiz.isOpen) {
      return const Chip(
        label: Text('Open', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        visualDensity: VisualDensity.compact,
      );
    } else {
      return const Chip(
        label: Text('Upcoming', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        visualDensity: VisualDensity.compact,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuizzes = _quizzes.where((quiz) {
      return quiz.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
      ),
      floatingActionButton: widget.isInstructor
          ? FloatingActionButton.extended(
              onPressed: () => _showQuizDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Quiz'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search quizzes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredQuizzes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.quiz, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No quizzes yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadQuizzes,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = filteredQuizzes[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QuizDetailScreen(
                                        quizId: quiz.id,
                                        isInstructor: widget.isInstructor,
                                      ),
                                    ),
                                  ).then((_) => _loadQuizzes());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              quiz.title,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          _buildStatusChip(quiz),
                                          if (widget.isInstructor) ...[
                                            const SizedBox(width: 8),
                                            PopupMenuButton(
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _showQuizDialog(quiz: quiz);
                                                } else if (value == 'delete') {
                                                  _deleteQuiz(quiz);
                                                }
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(quiz.description, style: TextStyle(color: Colors.grey[700])),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 8,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.question_answer, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text('${quiz.totalQuestions} questions'),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text('${quiz.durationMinutes} min'),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.replay, size: 16, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text('${quiz.maxAttempts} attempt(s)'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}