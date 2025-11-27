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
    required this.courseId,
    required this.courseCode,
    required this.courseName,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;

  Future<void> _exportAssignmentReport(String assignmentId, String assignmentTitle) async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      final data = await apiService.getSubmissions(assignmentId);
      final submissions = data.map((json) => SubmissionModel.fromJson(json)).toList();
      
      final filePath = await CsvExportService.exportSubmissions(
        submissions: submissions,
        assignmentTitle: assignmentTitle,
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

  Future<void> _exportQuizReport(String quizId, String quizTitle) async {
    setState(() => _isLoading = true);
    
    try {
      final apiService = ApiService();
      final data = await apiService.getQuizAttempts(quizId);
      final attempts = data.map((json) => QuizAttemptModel.fromJson(json)).toList();
      
      final filePath = await CsvExportService.exportQuizAttempts(
        attempts: attempts,
        quizTitle: quizTitle,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
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
      // Mock student data - replace with real API call
      final studentData = [
        {
          'name': 'Nguyen Van A',
          'email': 'student1@student.fit.edu',
          'assignmentsSubmitted': 8,
          'quizzesCompleted': 5,
          'averageGrade': 92.5,
          'status': 'Active',
        },
        {
          'name': 'Tran Thi B',
          'email': 'student2@student.fit.edu',
          'assignmentsSubmitted': 7,
          'quizzesCompleted': 4,
          'averageGrade': 85.3,
          'status': 'Active',
        },
        {
          'name': 'Le Van C',
          'email': 'student3@student.fit.edu',
          'assignmentsSubmitted': 6,
          'quizzesCompleted': 5,
          'averageGrade': 78.9,
          'status': 'Active',
        },
      ];
      
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
        ScaffoldMessenger.of(context).showSnackBar(
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.assignment)),
                    title: const Text('Export All Assignments'),
                    subtitle: const Text('Export all assignment submissions to CSV'),
                    trailing: const Icon(Icons.download),
                    onTap: () {
                      // Export all assignments for this course
                      _exportAssignmentReport('1', 'All_Assignments');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.quiz)),
                    title: const Text('Export All Quizzes'),
                    subtitle: const Text('Export all quiz attempts to CSV'),
                    trailing: const Icon(Icons.download),
                    onTap: () {
                      _exportQuizReport('1', 'All_Quizzes');
                    },
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
                _buildStatCard('Total Students', '45', Icons.people, Colors.blue),
                const SizedBox(height: 12),
                _buildStatCard('Assignments', '10', Icons.assignment, Colors.green),
                const SizedBox(height: 12),
                _buildStatCard('Quizzes', '5', Icons.quiz, Colors.orange),
                const SizedBox(height: 12),
                _buildStatCard('Avg Completion', '87%', Icons.check_circle, Colors.purple),
              ],
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
              backgroundColor: color.withOpacity(0.1),
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