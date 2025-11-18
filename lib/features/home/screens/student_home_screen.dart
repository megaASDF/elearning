import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/semester_provider.dart';
import '../../../core/providers/course_provider.dart';
import '../widgets/course_card.dart';
import '../widgets/semester_selector.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
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
            : courseProvider.courses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No courses enrolled',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: courseProvider.courses.length,
                    itemBuilder: (context, index) {
                      return CourseCard(course: courseProvider.courses[index]);
                    },
                  ),
      ),
    );
  }
}