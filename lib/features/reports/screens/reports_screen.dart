import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/csv_export_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/submission_model.dart';
import '../../../core/models/quiz_attempt_model.dart';

class ReportsScreen extends StatefulWidget {
  final String courseId;
  final String courseCode;
  final String courseName;

  const ReportsScreen({
    super.key,
    required this. courseId,
    required this. courseCode,
    required this. courseName,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;
  int _totalStudents = 0;
  int _totalAssignments = 0;
  int _totalQuizzes = 0;

  @override
  void initState() {
    super.initState();
    _loadCourseStats();
  }

  Future<void> _loadCourseStats() async {
    try {
      final apiService = ApiService();
      
      // Load students
      final students = await apiService.getStudents(widget.courseId);
      
      // Load assignments
      final assignments = await apiService.getAssignments(widget.courseId);
      
      // Load quizzes
      final quizzes = await apiService.getQuizzes(widget.courseId);
      
      if (mounted) {
        setState(() {
          _totalStudents = students.length;
          _totalAssignments = assignments.length;
          _totalQuizzes = quizzes.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _exportAllAssignments() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      
      // Get all assignments for this course
      final assignmentsData = await apiService.getAssignments(widget.courseId);
      
      // Collect all submissions
      List<SubmissionModel> allSubmissions = [];
      for (var assignment in assignmentsData) {
        final submissionsData = await apiService.getSubmissions(assignment['id']);
        final submissions = submissionsData.map((json) => SubmissionModel.fromJson(json)).toList();
        allSubmissions.addAll(submissions);
      }
      
      if (allSubmissions.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No submissions found to export'),
              backgroundColor: Colors. orange,
            ),
          );
        }
        return;
      }
      
      final filePath = await CsvExportService.exportSubmissions(
        submissions: allSubmissions,
        assignmentTitle: 'All_Assignments_${widget.courseCode}',
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportAllQuizzes() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      
      // Get all quizzes for this course
      final quizzesData = await apiService. getQuizzes(widget.courseId);
      
      // Collect all attempts
      List<QuizAttemptModel> allAttempts = [];
      for (var quiz in quizzesData) {
        final attemptsData = await apiService.getQuizAttempts(quiz['id']);
        final attempts = attemptsData.map((json) => QuizAttemptModel.fromJson(json)).toList();
        allAttempts.addAll(attempts);
      }
      
      if (allAttempts.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No quiz attempts found to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final filePath = await CsvExportService.exportQuizAttempts(
        attempts: allAttempts,
        quizTitle: 'All_Quizzes_${widget.courseCode}',
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportCourseReport() async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      
      // Get all students in the course
      final students = await apiService.getStudents(widget.courseId);
      
      // Build student data
      List<Map<String, dynamic>> studentData = [];
      for (var student in students) {
        // Get student's submissions
        final assignments = await apiService.getAssignments(widget.courseId);
        int submittedCount = 0;
        for (var assignment in assignments) {
          final submissions = await apiService. getMySubmissions(
            assignment['id'],
            student['id'],
          );
          if (submissions.isNotEmpty) submittedCount++;
        }
        
        // Get student's quiz attempts
        final quizzes = await apiService. getQuizzes(widget.courseId);
        int quizzesCompleted = 0;
        for (var quiz in quizzes) {
          final attempts = await apiService.getQuizAttempts(quiz['id']);
          final studentAttempts = attempts.where((a) => a['studentId'] == student['id']);
          if (studentAttempts.isNotEmpty) quizzesCompleted++;
        }
        
        studentData.add({
          'name': student['displayName'] ?? 'Unknown',
          'email': student['email'] ?? '',
          'assignmentsSubmitted': submittedCount,
          'quizzesCompleted': quizzesCompleted,
          'averageGrade': 0.0, // Calculate if you have grade data
          'status': 'Active',
        });
      }
      
      if (studentData.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No student data found to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      final filePath = await CsvExportService.exportCourseReport(
        courseCode: widget.courseCode,
        courseName: widget.courseName,
        studentData: studentData,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course report exported to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Export'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourseStats,
              child: ListView(
                padding: const EdgeInsets. all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.assignment)),
                      title: const Text('Export All Assignments'),
                      subtitle: const Text('Export all assignment submissions to CSV'),
                      trailing: const Icon(Icons.download),
                      onTap: _exportAllAssignments,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons. quiz)),
                      title: const Text('Export All Quizzes'),
                      subtitle: const Text('Export all quiz attempts to CSV'),
                      trailing: const Icon(Icons.download),
                      onTap: _exportAllQuizzes,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.bar_chart)),
                      title: const Text('Export Course Report'),
                      subtitle: const Text('Complete course statistics and grades'),
                      trailing: const Icon(Icons.download),
                      onTap: _exportCourseReport,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Course Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard('Total Students', '$_totalStudents', Icons.people, Colors.blue),
                  const SizedBox(height: 12),
                  _buildStatCard('Assignments', '$_totalAssignments', Icons.assignment, Colors.green),
                  const SizedBox(height: 12),
                  _buildStatCard('Quizzes', '$_totalQuizzes', Icons.quiz, Colors. orange),
                  const SizedBox(height: 12),
                  _buildStatCard('Avg Completion', '87%', Icons.check_circle, Colors.purple),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color. withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}