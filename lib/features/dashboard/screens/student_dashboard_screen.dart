import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id ?? '';
      final apiService = ApiService();

      // Get all courses for current semester
      // For now, we'll use a mock approach - you'd need to get actual enrolled courses

      // Mock data - replace with actual API calls
      setState(() {
        _submittedAssignments = 8;
        _pendingAssignments = 3;
        _lateAssignments = 1;
        _completedQuizzes = 5;
        _averageQuizScore = 85.5;
        _upcomingDeadlines = [
          {
            'title': 'Assignment 3: Web Development',
            'type': 'assignment',
            'deadline': DateTime.now().add(const Duration(days: 2)),
            'course': 'INT3123',
          },
          {
            'title': 'Midterm Quiz',
            'type': 'quiz',
            'deadline': DateTime.now().add(const Duration(days: 5)),
            'course': 'INT3120',
          },
          {
            'title': 'Final Project',
            'type': 'assignment',
            'deadline': DateTime.now().add(const Duration(days: 14)),
            'course': 'INT3123',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
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
                          'Late',
                          _lateAssignments.toString(),
                          Icons.warning,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Quizzes',
                          _completedQuizzes.toString(),
                          Icons.quiz,
                          Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Quiz Performance Chart
                    Text(
                      'Quiz Performance',
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
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barGroups: [
                                    BarChartGroupData(x: 0, barRods: [
                                      BarChartRodData(
                                          toY: 90, color: Colors.blue)
                                    ]),
                                    BarChartGroupData(x: 1, barRods: [
                                      BarChartRodData(
                                          toY: 85, color: Colors.blue)
                                    ]),
                                    BarChartGroupData(x: 2, barRods: [
                                      BarChartRodData(
                                          toY: 92, color: Colors.blue)
                                    ]),
                                    BarChartGroupData(x: 3, barRods: [
                                      BarChartRodData(
                                          toY: 78, color: Colors.blue)
                                    ]),
                                    BarChartGroupData(x: 4, barRods: [
                                      BarChartRodData(
                                          toY: 82, color: Colors.blue)
                                    ]),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                          showTitles: true, reservedSize: 40),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Text('Q${value.toInt() + 1}');
                                        },
                                      ),
                                    ),
                                    topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: FlGridData(show: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Upcoming Deadlines
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Deadlines',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to full calendar view
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_upcomingDeadlines.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No upcoming deadlines'),
                          ),
                        ),
                      )
                    else
                      ..._upcomingDeadlines.map((deadline) {
                        final daysUntil = deadline['deadline']
                            .difference(DateTime.now())
                            .inDays;
                        final isUrgent = daysUntil <= 3;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isUrgent ? Colors.red.shade50 : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: deadline['type'] == 'quiz'
                                  ? Colors.blue
                                  : Colors.green,
                              child: Icon(
                                deadline['type'] == 'quiz'
                                    ? Icons.quiz
                                    : Icons.assignment,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(deadline['title']),
                            subtitle: Text(
                              '${deadline['course']} • ${daysUntil} days remaining',
                            ),
                            trailing: isUrgent
                                ? const Icon(Icons.warning, color: Colors.red)
                                : null,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
