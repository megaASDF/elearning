import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/course_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../tabs/stream_tab.dart';
import '../tabs/classwork_tab.dart';
import '../tabs/people_tab.dart';
import '../../chatbot/screens/ai_chatbot_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CourseModel? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourseDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetails() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getCourseDetails(widget.courseId);
      setState(() {
        _course = CourseModel.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Course not found')),
      );
    }

    // Get user role from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isInstructor = authProvider.user?.role == 'instructor';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                title: Text(
                  _course!.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.primaries[
                            _course!.code.hashCode % Colors.primaries.length],
                        Colors.primaries[
                                _course!.code.hashCode % Colors.primaries.length]
                            .shade700,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 60),
                        Text(
                          _course!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _course!.instructorName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Stream'),
                  Tab(text: 'Classwork'),
                  Tab(text: 'People'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            StreamTab(courseId: widget.courseId, isInstructor: isInstructor),
            ClassworkTab(courseId: widget.courseId, isInstructor: isInstructor),
            PeopleTab(courseId: widget.courseId),
          ],
        ),
      ),
      // ✅ CHANGED: Only show AI Assistant if NOT instructor
      floatingActionButton: isInstructor
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIChatbotScreen(
                      courseId: widget.courseId,
                      courseName: _course!.name,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.smart_toy),
              label: const Text('AI Assistant'),
              backgroundColor: Colors.purple,
            ),
    );
  }
}