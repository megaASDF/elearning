import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/semester_provider.dart';
import '../../../core/providers/course_provider.dart';
import '../../../core/services/api_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/semester_selector.dart';
import '../../management/screens/manage_semesters_screen.dart';
import '../../management/screens/manage_students_screen.dart'; // Ensure this import exists
import '../../messaging/screens/conversations_screen.dart';
import '../../reports/screens/reports_screen.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadMessageCount();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final semesterProvider = context.read<SemesterProvider>();
    await semesterProvider.loadSemesters();

    if (!mounted) return;
    if (semesterProvider.currentSemester != null) {
      final courseProvider = context.read<CourseProvider>();
      await courseProvider.loadCourses(semesterProvider.currentSemester!.id);
    }
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      
      final conversations = await apiService.getConversations(authProvider.user?.id ?? '');
      final unreadMessages = conversations.fold<int>(0, (sum, conv) => sum + (conv['unreadCount'] as int? ?? 0));
      
      if (mounted) {
        setState(() {
          _unreadMessageCount = unreadMessages;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  // --- NEW: Function to Create Course ---
  Future<void> _createCourseDialog() async {
    final semesterProvider = context.read<SemesterProvider>();
    final currentSemester = semesterProvider.currentSemester;

    if (currentSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a semester first')),
      );
      return;
    }

    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Course Code (e.g. INT3123)'),
            ),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Course Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                try {
                  await ApiService().createCourse({
                    'code': codeCtrl.text,
                    'name': nameCtrl.text,
                    'semesterId': currentSemester.id,
                    'sessions': 15, // Default requirement
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    // Refresh the course list
                    context.read<CourseProvider>().loadCourses(currentSemester.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Course created successfully')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
            icon: Badge(
              label: Text('$_unreadMessageCount'),
              isLabelVisible: _unreadMessageCount > 0,
              child: const Icon(Icons.message),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationsScreen(),
                ),
              ).then((_) => _loadUnreadMessageCount());
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.settings),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'semesters',
                child: Row(
                  children: [Icon(Icons.calendar_today), SizedBox(width: 8), Text('Manage Semesters')],
                ),
              ),
              const PopupMenuItem(
                value: 'students',
                child: Row(
                  children: [Icon(Icons.people), SizedBox(width: 8), Text('Manage Students')],
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: Row(
                  children: [Icon(Icons.bar_chart), SizedBox(width: 8), Text('Reports & Export')],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'semesters') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSemestersScreen()));
              } else if (value == 'students') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsScreen()));
              } else if (value == 'reports') {
                if (courseProvider.courses.isNotEmpty) {
                  final firstCourse = courseProvider.courses.first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportsScreen(
                        courseId: firstCourse.id,
                        courseCode: firstCourse.code,
                        courseName: firstCourse.name,
                      ),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      // --- NEW: FAB to Create Course ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCourseDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
          await _loadUnreadMessageCount();
        },
        child: courseProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Section
                    Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        DashboardCard(title: 'Courses', value: totalCourses.toString(), icon: Icons.book, color: Colors.blue),
                        DashboardCard(title: 'Groups', value: totalGroups.toString(), icon: Icons.groups, color: Colors.green),
                        DashboardCard(title: 'Students', value: totalStudents.toString(), icon: Icons.people, color: Colors.orange),
                        DashboardCard(title: 'Messages', value: _unreadMessageCount.toString(), icon: Icons.message, color: Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Quick Actions
                    Text('Quick Actions', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSemestersScreen())),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Manage Semesters'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsScreen())),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Manage Students'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Course List
                    Text('My Courses', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    if (courseProvider.courses.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No courses for this semester\nTap "+ New Course" to create one', textAlign: TextAlign.center)))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courseProvider.courses.length,
                        itemBuilder: (context, index) {
                          final course = courseProvider.courses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.primaries[course.code.hashCode % Colors.primaries.length],
                                child: Text(course.code.substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(course.name),
                              subtitle: Text(course.code),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('${course.studentCount ?? 0}'),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              onTap: () {
                                context.push('/course/${course.id}');
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