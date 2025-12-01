import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../../../core/models/assignment_model.dart';
import '../../../core/models/submission_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/submission_provider.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final bool isInstructor;

  const AssignmentDetailScreen({
    super.key,
    required this. assignmentId,
    required this.isInstructor,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  AssignmentModel? _assignment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load assignment
      final doc = await FirebaseFirestore.instance
          .collection('assignments')
          .doc(widget.assignmentId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final now = DateTime.now();
        
        setState(() {
          _assignment = AssignmentModel. fromJson({
            'id': doc.id,
            'courseId': data['courseId'] ?? '',
            'groupIds': data['groupIds'] ??  [],
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'attachments': data['attachments'] ??  [],
            'startDate': (data['startDate'] as Timestamp?)?.toDate().toIso8601String() ?? now.toIso8601String(),
            'deadline': (data['deadline'] as Timestamp?)?.toDate(). toIso8601String() ??  now.add(Duration(days: 7)). toIso8601String(),
            'lateDeadline': (data['lateDeadline'] as Timestamp?)?.toDate().toIso8601String(),
            'allowLateSubmission': data['allowLateSubmission'] ?? false,
            'maxAttempts': data['maxAttempts'] ??  1,
            'allowedFileFormats': data['allowedFileFormats'] ?? ['pdf'],
            'maxFileSizeMB': (data['maxFileSizeMB'] ??  10).toDouble(),
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ?? now.toIso8601String(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ?? now.toIso8601String(),
          });
        });

        // Load submissions
        final authProvider = context.read<AuthProvider>();
        final submissionProvider = context.read<SubmissionProvider>();

        if (widget.isInstructor) {
          await submissionProvider.loadSubmissions(widget.assignmentId);
        } else {
          await submissionProvider.loadMySubmission(
            widget.assignmentId,
            authProvider.user?. id ?? '',
          );
        }
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading assignment: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_assignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assignment')),
        body: const Center(child: Text('Assignment not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_assignment!.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assignment!.title,
                      style: Theme.of(context). textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(_assignment!.description),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.calendar_today, 'Start', _formatDate(_assignment!.startDate)),
                    _buildInfoRow(Icons.event, 'Due', _formatDate(_assignment!. deadline)),
                    if (_assignment!.allowLateSubmission && _assignment!.lateDeadline != null)
                      _buildInfoRow(Icons.schedule, 'Late Until', _formatDate(_assignment!. lateDeadline! )),
                    _buildInfoRow(Icons.loop, 'Max Attempts', _assignment!.maxAttempts == -1 ? 'Unlimited' : '${_assignment!.maxAttempts}'),
                    _buildInfoRow(Icons.file_present, 'Allowed Formats', _assignment!.allowedFileFormats.join(', ')),
                    _buildInfoRow(Icons.file_upload, 'Max File Size', '${_assignment!.maxFileSizeMB} MB'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Role-based view
            if (widget.isInstructor)
              _buildInstructorView()
            else
              _buildStudentView(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets. symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors. grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour. toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInstructorView() {
    return Consumer<SubmissionProvider>(
      builder: (context, provider, child) {
        if (provider. isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.submissions.isEmpty) {
          return const Center(
            child: Text('No submissions yet'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submissions (${provider.submissions.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.submissions.length,
              itemBuilder: (context, index) {
                final submission = provider.submissions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: submission.grade != null ?  Colors.green : Colors.orange,
                      child: Icon(
                        submission.grade != null ? Icons.check : Icons.pending,
                        color: Colors. white,
                      ),
                    ),
                    title: Text(submission.studentName),
                    subtitle: Text('Submitted: ${_formatDate(submission.submittedAt)}'),
                    trailing: submission.grade != null
                        ?  Chip(label: Text('${submission.grade}'))
                        : const Text('Not graded'),
                    onTap: () => _showGradeDialog(submission),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentView() {
    return Consumer<SubmissionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.mySubmission != null) {
          final submission = provider.mySubmission! ;
          return Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons. check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Submitted',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Submitted at: ${_formatDate(submission. submittedAt)}'),
                  if (submission.grade != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Grade: ${submission.grade}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (submission.feedback != null) ...[
                      const SizedBox(height: 8),
                      Text('Feedback: ${submission.feedback}'),
                    ],
                  ] else
                    const Text('Waiting for grade... '),
                ],
              ),
            ),
          );
        }

        // Not submitted yet
        return Column(
          children: [
            const Text('You haven\'t submitted this assignment yet.'),
            const SizedBox(height: 16),
            ElevatedButton. icon(
              onPressed: () => _showSubmitDialog(),
              icon: const Icon(Icons.upload),
              label: const Text('Submit Assignment'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSubmitDialog() async {
    final authProvider = context.read<AuthProvider>();
    final submissionProvider = context.read<SubmissionProvider>();
    
    List<PlatformFile> selectedFiles = [];
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Submit Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Max ${_assignment!.maxFileSizeMB} MB per file'),
                Text('Allowed: ${_assignment!.allowedFileFormats.join(", ")}'),
                const SizedBox(height: 16),
                
                if (selectedFiles.isEmpty)
                  const Text('No files selected', style: TextStyle(fontStyle: FontStyle.italic))
                else
                  ...selectedFiles.map((file) => ListTile(
                    leading: const Icon(Icons.file_present),
                    title: Text(file.name),
                    subtitle: Text('${(file.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: isSubmitting ? null : () {
                        setDialogState(() => selectedFiles.remove(file));
                      },
                    ),
                  )),
                
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: isSubmitting ? null : () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      type: FileType.custom,
                      allowedExtensions: _assignment!.allowedFileFormats,
                    );
                    
                    if (result != null) {
                      for (var file in result.files) {
                        if (file.size / 1024 / 1024 <= _assignment!.maxFileSizeMB) {
                          setDialogState(() => selectedFiles.add(file));
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('${file.name} too large')),
                            );
                          }
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add Files'),
                ),
                
                if (isSubmitting) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const Text('Uploading...'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (isSubmitting || selectedFiles.isEmpty) ? null : () async {
                setDialogState(() => isSubmitting = true);
                
                try {
                  List<String> fileUrls = [];
                  final storage = FirebaseStorage.instance;
                  
                  for (var file in selectedFiles) {
                    final path = 'submissions/${widget.assignmentId}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
                    final ref = storage.ref().child(path);
                    
                    if (kIsWeb && file.bytes != null) {
                      await ref.putData(file.bytes!);
                    } else if (file.path != null) {
                      await ref.putFile(File(file.path!));
                    }
                    
                    fileUrls.add(await ref.getDownloadURL());
                  }
                  
                  await submissionProvider.submitAssignment(
                    widget.assignmentId,
                    authProvider.user?.id ?? '',
                    authProvider.user?.displayName ?? 'Student',
                    fileUrls,
                  );
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Submitted ${selectedFiles.length} file(s)!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isSubmitting = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGradeDialog(SubmissionModel submission) async {
    final gradeCtrl = TextEditingController(text: submission.grade?. toString() ?? '');
    final feedbackCtrl = TextEditingController(text: submission. feedback ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Grade ${submission.studentName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeCtrl,
              decoration: const InputDecoration(labelText: 'Grade (0-100)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackCtrl,
              decoration: const InputDecoration(labelText: 'Feedback'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final grade = double.tryParse(gradeCtrl.text);
              if (grade != null) {
                try {
                  await context.read<SubmissionProvider>().gradeSubmission(
                        submission.id,
                        widget.assignmentId,
                        grade,
                        feedbackCtrl.text. trim(). isEmpty ? null : feedbackCtrl.text.trim(),
                      );
                  if (ctx. mounted) {
                    Navigator. pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Submission graded!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
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