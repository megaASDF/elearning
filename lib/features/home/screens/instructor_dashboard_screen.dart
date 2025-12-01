import 'package:elearning_app/core/models/course_model.dart';
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
import '../../management/screens/manage_students_screen.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadUnreadMessageCount();
    });
  }

  Future<void> _loadData() async {
    if (! mounted) return;
    final semesterProvider = context.read<SemesterProvider>();
    await semesterProvider.loadSemesters();

    if (!mounted) return;
    if (semesterProvider.currentSemester != null) {
      final courseProvider = context.read<CourseProvider>();
      await courseProvider.loadCourses(semesterProvider.currentSemester!. id);
    }
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      
      final conversations = await apiService.getConversations(authProvider.user?.id ?? '');
      final unreadMessages = conversations.fold<int>(0, (sum, conv) => sum + (conv['unreadCount'] as int?  ?? 0));
      
      if (mounted) {
        setState(() {
          _unreadMessageCount = unreadMessages;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _createCourseDialog() async {
    final semesterProvider = context.read<SemesterProvider>();
    final currentSemester = semesterProvider. currentSemester;

    if (currentSemester == null) {
      if (! mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a semester first')),
      );
      return;
    }

    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    if (! mounted) return;
    final dialogContext = context;
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Course Code (e.g.  INT3123)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Course Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text. isNotEmpty && nameCtrl.text.isNotEmpty) {
                try {
                  final authProvider = dialogContext.read<AuthProvider>();
                  final course = CourseModel(
                    id: '',
                    semesterId: currentSemester. id,
                    code: codeCtrl.text. trim(),
                    name: nameCtrl.text.trim(),
                    description: descCtrl. text.trim(),
                    instructorName: authProvider.user?. displayName ?? 'Administrator',
                    numberOfSessions: 15,
                    groupCount: 0,
                    studentCount: 0,
                    createdAt: DateTime.now().toIso8601String(),
                  );

                  await dialogContext.read<CourseProvider>().createCourse(course);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Course created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (dialogContext.mounted) {
                    ScaffoldMessenger. of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.orange,
                    ),
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
        .fold<int>(0, (sum, course) => sum + course.groupCount);
    final totalStudents = courseProvider.courses
        .fold<int>(0, (sum, course) => sum + course.studentCount);

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
                Navigator. push(context, MaterialPageRoute(builder: (context) => const ManageSemestersScreen()));
              } else if (value == 'students') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageStudentsScreen()));
              } else if (value == 'reports') {
                if (courseProvider.courses. isNotEmpty) {
                  final firstCourse = courseProvider. courses. first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportsScreen(
                        courseId: firstCourse.id,
                        courseCode: firstCourse. code,
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
              if (context.mounted) context. go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: semesterProvider.currentSemester != null
          ? FloatingActionButton.extended(
              onPressed: _createCourseDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Course'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadData();
          await _loadUnreadMessageCount();
        },
        child: semesterProvider.isLoading || courseProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : semesterProvider.currentSemester == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment. center,
                      children: [
                        const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No semester selected'),
                        const SizedBox(height: 16),
                        ElevatedButton. icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ManageSemestersScreen()),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Semester'),
                        ),
                      ],
                    ),
                  )
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
                            DashboardCard(title: 'Groups', value: totalGroups.toString(), icon: Icons. groups, color: Colors.green),
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
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No courses for this semester',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _createCourseDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create First Course'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: courseProvider.courses. length,
                            itemBuilder: (context, index) {
                              final course = courseProvider.courses[index];
                              final colorIndex = course.code.hashCode. abs() % Colors.primaries.length;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.primaries[colorIndex],
                                    child: Text(
                                      course.code. length >= 2 
                                          ? course.code. substring(0, 2).toUpperCase() 
                                          : course. code.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(course.name),
                                  subtitle: Text('${course.code} • ${course.groupCount} groups • ${course.studentCount} students'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () {
                                    courseProvider.setSelectedCourse(course);
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