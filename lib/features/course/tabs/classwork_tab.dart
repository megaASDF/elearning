import 'package:flutter/material.dart';
import '../../assignment/screens/assignments_screen.dart';
import '../../quiz/screens/quizzes_screen.dart';
import '../../material/screens/materials_screen.dart';
import '../../forum/screens/forum_screen.dart';

class ClassworkTab extends StatelessWidget {
  final String courseId;
  final bool isInstructor;

  const ClassworkTab({
    super.key,
    required this.courseId,
    this.isInstructor = false,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
              Tab(icon: Icon(Icons.quiz), text: 'Quizzes'),
              Tab(icon: Icon(Icons.folder), text: 'Materials'),
              Tab(icon: Icon(Icons.forum), text: 'Forum'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                AssignmentsScreen(courseId: courseId, isInstructor: isInstructor),
                QuizzesScreen(courseId: courseId, isInstructor: isInstructor),
                MaterialsScreen(courseId: courseId, isInstructor: isInstructor),
                ForumScreen(courseId: courseId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}