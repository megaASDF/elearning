import 'package:flutter/material.dart';

class ClassworkTab extends StatelessWidget {
  final String courseId;

  const ClassworkTab({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No assignments yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('Check back later for new classwork'),
        ],
      ),
    );
  }
}