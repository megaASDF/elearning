import 'package:flutter/material.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/models/submission_model.dart';
import '../../../core/services/api_service.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final bool isInstructor;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.isInstructor,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  AssignmentModel? _assignment;
  List<SubmissionModel> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      // Load assignment details
      final assignmentData = await apiService.getAssignments(''); // Filter by ID
      // Load submissions
      final submissionsData = await apiService.getSubmissions(widget.assignmentId);

      if (mounted) {
        setState(() {
          // _assignment = ... parse assignment
          _submissions = submissionsData
              .map((json) => SubmissionModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _assignment?.title ?? 'Assignment',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(_assignment?.description ?? ''),
                  const SizedBox(height: 24),
                  if (widget.isInstructor) ...[
                    Text(
                      'Submissions (${_submissions.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _submissions.length,
                      itemBuilder: (context, index) {
                        final submission = _submissions[index];
                        return Card(
                          child: ListTile(
                            title: Text(submission.studentName),
                            subtitle: Text(
                              'Submitted: ${submission.submittedAt.day}/${submission.submittedAt.month}/${submission.submittedAt.year}',
                            ),
                            trailing: submission.isGraded
                                ? Chip(
                                    label: Text('${submission.grade}/100'),
                                    backgroundColor: Colors.green,
                                  )
                                : const Chip(label: Text('Not Graded')),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}