import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/models/submission_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/submission_form.dart'; // Import the new widget

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
  List<SubmissionModel> _submissions = []; // For Instructor
  SubmissionModel? _mySubmission;          // For Student
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final user = context.read<AuthProvider>().user;

      // 1. Fetch Assignment Details correctly
      final assignmentData = await api.getAssignmentById(widget.assignmentId);
      
      if (widget.isInstructor) {
        // Instructor: Load ALL submissions
        final subsData = await api.getSubmissions(widget.assignmentId);
        if (mounted) {
          setState(() {
            _assignment = AssignmentModel.fromJson(assignmentData);
            _submissions = subsData.map((j) => SubmissionModel.fromJson(j)).toList();
            _isLoading = false;
          });
        }
      } else {
        // Student: Load ONLY my submission
        final myData = await api.getMySubmissions(widget.assignmentId, user?.id ?? '');
        if (mounted) {
          setState(() {
            _assignment = AssignmentModel.fromJson(assignmentData);
            _mySubmission = myData.isNotEmpty 
                ? SubmissionModel.fromJson(myData.first) 
                : null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_assignment == null) return const Scaffold(body: Center(child: Text('Assignment not found')));

    return Scaffold(
      appBar: AppBar(title: Text(_assignment!.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Assignment Info ---
            Text('Due: ${_assignment!.deadline.toString().split('.')[0]}', 
                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(_assignment!.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),

            // --- Role Based View ---
            if (widget.isInstructor) 
              _buildInstructorView()
            else 
              _buildStudentView(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Student Submissions (${_submissions.length})', 
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (_submissions.isEmpty)
          const Text('No students have submitted yet.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _submissions.length,
            itemBuilder: (context, index) {
              final sub = _submissions[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(sub.studentName[0])),
                  title: Text(sub.studentName),
                  subtitle: Text('Submitted: ${sub.submittedAt.toString().split(' ')[0]}'),
                  trailing: sub.grade != null 
                      ? Text('${sub.grade}/100', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                      : IconButton(
                          icon: const Icon(Icons.rate_review),
                          onPressed: () => _gradeDialog(sub),
                        ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStudentView() {
    if (_mySubmission != null) {
      // Already Submitted View
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Handed In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ]),
            const SizedBox(height: 8),
            Text('Submitted on ${_mySubmission!.submittedAt.toString().split('.')[0]}'),
            if (_mySubmission!.grade != null) ...[
              const Divider(),
              Text('Grade: ${_mySubmission!.grade}/100', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              if (_mySubmission!.feedback != null)
                Text('Feedback: "${_mySubmission!.feedback}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      );
    }

    // Not Submitted Yet - Show Form
    return SubmissionForm(
      assignmentId: widget.assignmentId,
      onSuccess: _loadData, // Reload page to show "Handed In" state
    );
  }

  Future<void> _gradeDialog(SubmissionModel sub) async {
    final gradeCtrl = TextEditingController();
    final feedbackCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${sub.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grade (0-100)'), keyboardType: TextInputType.number),
            TextField(controller: feedbackCtrl, decoration: const InputDecoration(labelText: 'Feedback')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (gradeCtrl.text.isNotEmpty) {
                await ApiService().gradeSubmission(sub.id, double.parse(gradeCtrl.text), feedbackCtrl.text);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            child: const Text('Save Grade'),
          ),
        ],
      ),
    );
  }
}