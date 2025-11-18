import 'package:flutter/material.dart';
import '../../../core/models/semester_model.dart';

class SemesterSelector extends StatelessWidget {
  final SemesterModel currentSemester;
  final List<SemesterModel> semesters;
  final Function(SemesterModel) onChanged;

  const SemesterSelector({
    super.key,
    required this.currentSemester,
    required this.semesters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SemesterModel>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Text(
              currentSemester.code,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) {
        return semesters.map((semester) {
          return PopupMenuItem<SemesterModel>(
            value: semester,
            child: Row(
              children: [
                if (semester.id == currentSemester.id)
                  const Icon(Icons.check, size: 20),
                if (semester.id == currentSemester.id)
                  const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester.code,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      semester.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: onChanged,
    );
  }
}