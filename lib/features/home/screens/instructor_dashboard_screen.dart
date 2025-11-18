import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/semester_provider.dart';
import '../../../core/providers/course_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/semester_selector.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final semesterProvider = context.read<SemesterProvider>();
    await semesterProvider.loadSemesters();

    if (semesterProvider.currentSemester != null) {
      final courseProvider = context.read<CourseProvider>();
      await courseProvider.loadCourses(semesterProvider.currentSemester!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final semesterProvider = context.watch<SemesterProvider>();
    final courseProvider = context.watch<CourseProvider>();

    final totalCourses = courseProvider.courses.length;
    final totalGroups = courseProvider.courses
        .fold<int>(0, (sum, course) => sum + (course.groupCount ?? 0));
    final totalStudents = courseProvider.courses
        .fold<int>(0, (sum, course) => sum + (course.studentCount ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        actions: [
          if (semesterProvider.currentSemester != null)
            SemesterSelector(
              currentSemester: semesterProvider.currentSemester!,
              semesters: semesterProvider.semesters,
              onChanged: (semester) async {
                semesterProvider.setCurrentSemester(semester);
                await courseProvider.loadCourses(semester.id);
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: courseProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        DashboardCard(
                          title: 'Courses',
                          value: totalCourses.toString(),
                          icon: Icons.book,
                          color: Colors.blue,
                        ),
                        DashboardCard(
                          title: 'Groups',
                          value: totalGroups.toString(),
                          icon: Icons.groups,
                          color: Colors.green,
                        ),
                        DashboardCard(
                          title: 'Students',
                          value: totalStudents.toString(),
                          icon: Icons.people,
                          color: Colors.orange,
                        ),
                        DashboardCard(
                          title: 'Assignments',
                          value: '0',
                          icon: Icons.assignment,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Courses',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to create course
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('New Course'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (courseProvider.courses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No courses created yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courseProvider.courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final course = courseProvider.courses[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(course.code.substring(0, 2)),
                              ),
                              title: Text(course.name),
                              subtitle: Text(
                                '${course.code} • ${course.groupCount ?? 0} groups • ${course.studentCount ?? 0} students',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  // TODO: Show options
                                },
                              ),
                              onTap: () {
                                // TODO: Navigate to course details
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}