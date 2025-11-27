import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/semester_provider.dart';
import '../../../core/providers/course_provider.dart';
import '../../../core/services/api_service.dart';
import '../../profile/sceens/profile_screen.dart' show ProfileScreen;
import '../widgets/course_card.dart';
import '../widgets/semester_selector.dart';
import '../../notification/screens/notifications_screen.dart';
import '../../messaging/screens/conversations_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _unreadNotificationCount = 0;
  int _unreadMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCounts();
  }

  Future<void> _loadData() async {
    final semesterProvider = context.read<SemesterProvider>();
    await semesterProvider.loadSemesters();

    if (semesterProvider.currentSemester != null) {
      final courseProvider = context.read<CourseProvider>();
      await courseProvider.loadCourses(semesterProvider.currentSemester!.id);
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();

      // Load notifications
      final notifications =
          await apiService.getNotifications(authProvider.user?.id ?? '');
      final unreadNotifications =
          notifications.where((n) => !(n['isRead'] ?? true)).length;

      // Load messages
      final conversations =
          await apiService.getConversations(authProvider.user?.id ?? '');
      final unreadMessages = conversations.fold<int>(
          0, (sum, conv) => sum + (conv['unreadCount'] as int? ?? 0));

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadNotifications;
          _unreadMessageCount = unreadMessages;
        });
      }
    } catch (e) {
      // Silent fail - counts will remain 0
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
          // Notifications Icon
          IconButton(
            icon: Badge(
              label: Text('$_unreadNotificationCount'),
              isLabelVisible: _unreadNotificationCount > 0,
              child: const Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ).then((_) => _loadUnreadCounts());
            },
          ),
          // Messages Icon
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
              ).then((_) => _loadUnreadCounts());
            },
          ),
          // Profile Icon
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          // Logout Icon
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
        onRefresh: () async {
          await _loadData();
          await _loadUnreadCounts();
        },
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
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
