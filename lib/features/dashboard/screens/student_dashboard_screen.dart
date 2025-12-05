import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/semester_provider.dart'; // To get current semester
import '../../../core/services/api_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  bool _isLoading = true;
  int _submittedAssignments = 0;
  int _pendingAssignments = 0;
  int _lateAssignments = 0;
  int _completedQuizzes = 0;
  double _averageQuizScore = 0.0;
  List<Map<String, dynamic>> _upcomingDeadlines = [];
  List<double> _quizScores = []; // Store scores for the chart

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final semesterProvider = context.read<SemesterProvider>();
      final userId = authProvider.user?.id;
      final currentSemesterId = semesterProvider.currentSemester?.id;

      if (userId == null || currentSemesterId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final apiService = ApiService();

      // 1. Get Enrolled Courses
      final courses = await apiService.getEnrolledCourses(currentSemesterId, userId);

      int submitted = 0;
      int pending = 0;
      int late = 0;
      int completedQuizzes = 0;
      double totalQuizScore = 0;
      List<Map<String, dynamic>> deadlines = [];
      List<double> scoresForChart = [];

      // 2. Iterate through courses to get Assignments and Quizzes
      for (var course in courses) {
        final courseId = course['id'];
        final courseCode = course['code'];

        // --- FETCH ASSIGNMENTS ---
        final assignments = await apiService.getAssignments(courseId);
        for (var assignment in assignments) {
          // Check if submitted
          final submissions = await apiService.getMySubmissions(assignment['id'], userId);
          final isSubmitted = submissions.isNotEmpty;
          final deadline = DateTime.tryParse(assignment['deadline'] ?? '') ?? DateTime.now().add(const Duration(days: 365));
          
          if (isSubmitted) {
            submitted++;
            // Check if it was late (simple check against submission time if available, otherwise just count as submitted)
             if (submissions.first['submittedAt'] != null) {
                 final submittedAt = DateTime.tryParse(submissions.first['submittedAt']) ?? DateTime.now();
                 if (submittedAt.isAfter(deadline)) {
                   late++;
                 }
             }
          } else {
            // Not submitted
            if (DateTime.now().isAfter(deadline)) {
              late++; // Missed deadline
            } else {
              pending++; // Future deadline
              deadlines.add({
                'title': assignment['title'],
                'type': 'assignment',
                'deadline': deadline,
                'course': courseCode,
              });
            }
          }
        }

        // --- FETCH QUIZZES ---
        final quizzes = await apiService.getQuizzes(courseId);
        for (var quiz in quizzes) {
           final attempts = await apiService.getQuizAttempts(quiz['id']);
           // Filter for THIS student's attempts
           final myAttempts = attempts.where((a) => a['studentId'] == userId && a['submittedAt'] != null).toList();

           if (myAttempts.isNotEmpty) {
             completedQuizzes++;
             // Use the highest score if multiple attempts
             // Assuming score is 0-10 or 0-100. Normalize to 0-100 for chart.
             double maxScore = 0.0;
             for(var attempt in myAttempts) {
               final score = (attempt['score'] ?? 0.0).toDouble();
                if(score > maxScore) maxScore = score;
             }
             
             // If your quiz scores are out of 10, multiply by 10. If 100, keep as is.
             // Adjust this multiplier based on your grading scale!
             // Assuming 10 is max score based on standard logic, so * 10 to get percentage.
             double percentageScore = maxScore <= 10 ? maxScore * 10 : maxScore; 
             
             totalQuizScore += percentageScore;
             scoresForChart.add(percentageScore);
           } else {
             // Not taken yet
             final closeTime = DateTime.tryParse(quiz['closeTime'] ?? '') ?? DateTime.now().add(const Duration(days: 365));
             if (DateTime.now().isBefore(closeTime)) {
                deadlines.add({
                'title': quiz['title'],
                'type': 'quiz',
                'deadline': closeTime,
                'course': courseCode,
              });
             }
           }
        }
      }

      // Sort deadlines by date (soonest first)
      deadlines.sort((a, b) => (a['deadline'] as DateTime).compareTo(b['deadline'] as DateTime));

      setState(() {
        _submittedAssignments = submitted;
        _pendingAssignments = pending;
        _lateAssignments = late;
        _completedQuizzes = completedQuizzes;
        _averageQuizScore = completedQuizzes > 0 ? totalQuizScore / completedQuizzes : 0.0;
        _upcomingDeadlines = deadlines.take(5).toList(); // Show top 5
        _quizScores = scoresForChart.take(5).toList(); // Show last 5 scores on chart
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    Text(
                      'Learning Progress',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Submitted',
                          _submittedAssignments.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Pending',
                          _pendingAssignments.toString(),
                          Icons.pending,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Late/Missed',
                          _lateAssignments.toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Quizzes Done',
                          _completedQuizzes.toString(),
                          Icons.quiz,
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Quiz Performance Chart
                    if (_quizScores.isNotEmpty) ...[
                      Text(
                        'Recent Quiz Scores',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Average Score'),
                                  Text(
                                    '${_averageQuizScore.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _averageQuizScore >= 70 ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 200,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: 100,
                                    barGroups: _quizScores.asMap().entries.map((entry) {
                                      return BarChartGroupData(
                                        x: entry.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: entry.value,
                                            color: entry.value >= 70 ? Colors.green : Colors.orange,
                                            width: 16,
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                          )
                                        ],
                                      );
                                    }).toList(),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true, 
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text('Q${value.toInt() + 1}'),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    gridData: FlGridData(
                                      show: true, 
                                      drawVerticalLine: false,
                                      horizontalInterval: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Upcoming Deadlines
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Deadlines',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_upcomingDeadlines.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_available, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('No upcoming deadlines!', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    else
                      ..._upcomingDeadlines.map((deadline) {
                        final date = deadline['deadline'] as DateTime;
                        final daysUntil = date.difference(DateTime.now()).inDays;
                        final isUrgent = daysUntil <= 1; // Urgent if due today or tomorrow

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isUrgent ? Colors.red.shade50 : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: deadline['type'] == 'quiz'
                                  ? Colors.purple.shade100
                                  : Colors.orange.shade100,
                              child: Icon(
                                deadline['type'] == 'quiz'
                                    ? Icons.quiz
                                    : Icons.assignment,
                                color: deadline['type'] == 'quiz'
                                    ? Colors.purple
                                    : Colors.orange,
                              ),
                            ),
                            title: Text(
                              deadline['title'],
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${deadline['course']} • ${DateFormat('MMM d, h:mm a').format(date)}'),
                            trailing: isUrgent
                                ? Chip(
                                    label: const Text('Urgent', style: TextStyle(color: Colors.white, fontSize: 10)),
                                    backgroundColor: Colors.red,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  )
                                : Text(
                                    daysUntil == 0 ? 'Today' : '$daysUntil days',
                                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                                  ),
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}