import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
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
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Helper function to format file size
          String formatFileSize(int bytes) {
            if (bytes < 1024) return '$bytes B';
            if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
            return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
          }

          // Validate files against assignment requirements
          String? validateFiles(List<PlatformFile> files) {
            if (files.isEmpty) return 'Please select at least one file';
            
            final allowedFormats = _assignment!.allowedFileFormats;
            final maxSizeMB = _assignment!.maxFileSizeMB;
            final maxSizeBytes = (maxSizeMB * 1024 * 1024).toInt();

            for (final file in files) {
              // Check file extension
              final extension = file.extension?.toLowerCase() ?? '';
              if (allowedFormats.isNotEmpty && !allowedFormats.contains(extension)) {
                return 'File "${file.name}" has invalid format. Allowed: ${allowedFormats.join(", ")}';
              }
              
              // Check file size
              if (file.size > maxSizeBytes) {
                return 'File "${file.name}" (${formatFileSize(file.size)}) exceeds maximum size of ${maxSizeMB} MB';
              }
            }
            return null;
          }

          Future<void> pickFiles() async {
            try {
              final hasAllowedFormats = _assignment!.allowedFileFormats.isNotEmpty;
              final result = await FilePicker.platform.pickFiles(
                allowMultiple: true,
                type: hasAllowedFormats ? FileType.custom : FileType.any,
                allowedExtensions: hasAllowedFormats
                    ? _assignment!.allowedFileFormats
                    : null,
              );

              if (result != null && result.files.isNotEmpty) {
                setDialogState(() {
                  selectedFiles = [...selectedFiles, ...result.files];
                  errorMessage = validateFiles(selectedFiles);
                });
              }
            } catch (e) {
              setDialogState(() {
                errorMessage = 'Error picking files: $e';
              });
            }
          }

          void removeFile(int index) {
            setDialogState(() {
              selectedFiles = List.from(selectedFiles)..removeAt(index);
              errorMessage = selectedFiles.isEmpty ? null : validateFiles(selectedFiles);
            });
          }

          Future<void> submitFiles() async {
            final validationError = validateFiles(selectedFiles);
            if (validationError != null) {
              setDialogState(() => errorMessage = validationError);
              return;
            }

            setDialogState(() {
              isSubmitting = true;
              errorMessage = null;
            });

            try {
              // For now, we'll submit with file names as URLs (in a real app, you'd upload to storage first)
              final fileUrls = selectedFiles.map((f) => f.name).toList();
              
              await submissionProvider.submitAssignment(
                widget.assignmentId,
                authProvider.user?.id ?? '',
                authProvider.user?.displayName ?? 'Student',
                fileUrls,
              );

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Assignment submitted with ${selectedFiles.length} file(s)!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              setDialogState(() {
                isSubmitting = false;
                errorMessage = 'Error submitting: $e';
              });
            }
          }

          return AlertDialog(
            title: const Text('Submit Assignment'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File requirements info
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'File Requirements',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Allowed formats: ${_assignment!.allowedFileFormats.isEmpty ? "Any" : _assignment!.allowedFileFormats.join(", ")}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Max file size: ${_assignment!.maxFileSizeMB} MB',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // File picker button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isSubmitting ? null : pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select Files'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Selected files list
                  if (selectedFiles.isNotEmpty) ...[
                    const Text(
                      'Selected Files:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = selectedFiles[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                _getFileIcon(file.extension ?? ''),
                                color: Colors.blue,
                              ),
                              title: Text(
                                file.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                formatFileSize(file.size),
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: isSubmitting ? null : () => removeFile(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No files selected',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Error message
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // Upload progress
                  if (isSubmitting) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text('Submitting...', style: TextStyle(fontSize: 12)),
                    ),
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
                onPressed: isSubmitting || selectedFiles.isEmpty ? null : submitFiles,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
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