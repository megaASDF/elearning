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
import '../widgets/assignment_tracking_table.dart';
import '../../../core/services/semester_protection_service.dart';

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
  final SemesterProtectionService _protectionService = SemesterProtectionService();
  
  AssignmentModel? _assignment;
  bool _isLoading = true;
  bool _isReadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _checkReadOnly();
    });
  }

  Future<void> _checkReadOnly() async {
    final readOnly = await _protectionService. isAssignmentReadOnly(widget.assignmentId);
    if (mounted) {
      setState(() => _isReadOnly = readOnly);
    }
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
            'courseId': data['courseId'] ??  '',
            'groupIds': data['groupIds'] ??  [],
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'attachments': data['attachments'] ?? [],
            'startDate':
                (data['startDate'] as Timestamp?)?.toDate(). toIso8601String() ??
                    now.toIso8601String(),
            'deadline':
                (data['deadline'] as Timestamp?)?.toDate().toIso8601String() ?? 
                    now.add(Duration(days: 7)).toIso8601String(),
            'lateDeadline': (data['lateDeadline'] as Timestamp?)
                ?.toDate()
                .toIso8601String(),
            'allowLateSubmission': data['allowLateSubmission'] ?? false,
            'maxAttempts': data['maxAttempts'] ?? 1,
            'allowedFileFormats': data['allowedFileFormats'] ?? ['pdf'],
            'maxFileSizeMB': (data['maxFileSizeMB'] ?? 10). toDouble(),
            'createdAt':
                (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
                    now.toIso8601String(),
            'updatedAt':
                (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ?? 
                    now.toIso8601String(),
          });
        });

        // Load submissions for students only (instructors use tracking table)
        if (! widget.isInstructor) {
          final authProvider = context.read<AuthProvider>();
          final submissionProvider = context.read<SubmissionProvider>();
          await submissionProvider.loadMySubmission(
            widget.assignmentId,
            authProvider.user?.id ?? '',
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
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(_assignment!.description),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.calendar_today, 'Start',
                        _formatDate(_assignment!.startDate)),
                    _buildInfoRow(
                        Icons.event, 'Due', _formatDate(_assignment!. deadline)),
                    if (_assignment!.allowLateSubmission &&
                        _assignment!.lateDeadline != null)
                      _buildInfoRow(Icons.schedule, 'Late Until',
                          _formatDate(_assignment!.lateDeadline!)),
                    _buildInfoRow(
                        Icons.loop,
                        'Max Attempts',
                        _assignment!.maxAttempts == -1
                            ? 'Unlimited'
                            : '${_assignment!.maxAttempts}'),
                    _buildInfoRow(Icons.file_present, 'Allowed Formats',
                        _assignment! .allowedFileFormats.join(', ')),
                    _buildInfoRow(Icons.file_upload, 'Max File Size',
                        '${_assignment!.maxFileSizeMB} MB'),
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
          Icon(icon, size: 16, color: Colors.grey[600]),
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
    return SizedBox(
      height: 600,
      child: AssignmentTrackingTable(
        assignmentId: widget.assignmentId,
        courseId: _assignment!.courseId,
        assignmentTitle: _assignment!.title,
      ),
    );
  }

  Widget _buildStudentView() {
    // Check if read-only first
    if (_isReadOnly) {
      return Card(
        color: Colors.orange,
        child: Padding(
          padding: const EdgeInsets. all(16),
          child: Row(
            children: const [
              Icon(Icons.lock, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Past Semester - Read Only',
                      style: TextStyle(
                        color: Colors. white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This assignment is from a past semester.  Submissions are disabled.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<SubmissionProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.mySubmission != null) {
          final submission = provider.mySubmission!;
          return Card(
            color: Colors. green. shade50,
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
            ElevatedButton.icon(
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
  String uploadStatus = '';
  double uploadProgress = 0.0;

  await showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing while uploading
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Max ${_assignment! .maxFileSizeMB} MB per file'),
              Text('Allowed: ${_assignment!.allowedFileFormats.join(", ")}'),
              const SizedBox(height: 16),
              
              // File list
              if (selectedFiles.isEmpty)
                const Text('No files selected', style: TextStyle(fontStyle: FontStyle.italic))
              else
                ... selectedFiles.map((file) => ListTile(
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
              
              // Add files button
              OutlinedButton. icon(
                onPressed: isSubmitting ? null : () async {
                  final result = await FilePicker.platform. pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: _assignment!.allowedFileFormats,
                  );

                  if (result != null) {
                    for (var file in result.files) {
                      final fileSizeMB = file.size / 1024 / 1024;
                      if (fileSizeMB <= _assignment!.maxFileSizeMB) {
                        setDialogState(() => selectedFiles. add(file));
                      } else {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('${file.name} is too large (${fileSizeMB.toStringAsFixed(1)} MB)')),
                          );
                        }
                      }
                    }
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Files'),
              ),
              
              // Upload progress
              if (isSubmitting) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: uploadProgress),
                const SizedBox(height: 8),
                Text(uploadStatus, style: const TextStyle(fontSize: 12, color: Colors.blue)),
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
              setDialogState(() {
                isSubmitting = true;
                uploadStatus = 'Starting upload...';
                uploadProgress = 0.0;
              });

              try {
                List<String> fileUrls = [];
                final storage = FirebaseStorage.instance;
                final userId = authProvider.user! .id;

                // Upload each file
                for (int i = 0; i < selectedFiles. length; i++) {
                  final file = selectedFiles[i];
                  
                  setDialogState(() {
                    uploadStatus = 'Uploading ${file.name} (${i + 1}/${selectedFiles.length})...';
                    uploadProgress = i / selectedFiles.length;
                  });

                  debugPrint('📤 Starting upload: ${file.name}');

                  try {
                    // Create unique path
                    final timestamp = DateTime.now().millisecondsSinceEpoch;
                    final safeName = file.name. replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
                    final path = 'submissions/${widget.assignmentId}/$userId/${timestamp}_$safeName';
                    
                    debugPrint('📁 Upload path: $path');
                    
                    final ref = storage.ref().child(path);

                    // Upload based on platform
                    if (kIsWeb && file.bytes != null) {
                      debugPrint('🌐 Web upload (${file.bytes! .length} bytes)');
                      final uploadTask = ref.putData(
                        file.bytes!,
                        SettableMetadata(contentType: _getContentType(file.name)),
                      );
                      
                      await uploadTask;
                    } else if (file.path != null) {
                      debugPrint('💻 Desktop upload');
                      final uploadTask = ref.putFile(
                        File(file.path! ),
                        SettableMetadata(contentType: _getContentType(file.name)),
                      );
                      
                      await uploadTask;
                    } else {
                      throw Exception('No valid file data');
                    }

                    final downloadUrl = await ref. getDownloadURL();
                    fileUrls.add(downloadUrl);
                    
                    debugPrint('✅ Upload complete: ${file.name}');
                    debugPrint('🔗 URL: $downloadUrl');
                  } catch (uploadError) {
                    debugPrint('❌ Upload failed: $uploadError');
                    throw Exception('Failed to upload ${file.name}: $uploadError');
                  }
                }

                // All files uploaded, now submit
                setDialogState(() {
                  uploadStatus = 'Submitting assignment...';
                  uploadProgress = 0.95;
                });

                debugPrint('📝 Submitting to Firestore with ${fileUrls.length} URLs');

                await submissionProvider. submitAssignment(
                  widget.assignmentId,
                  userId,
                  authProvider. user! .displayName,
                  fileUrls,
                );

                debugPrint('✅ Assignment submitted successfully');

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Submitted ${selectedFiles.length} file(s) successfully! '),
                      backgroundColor: Colors. green,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('❌ Submission error: $e');
                setDialogState(() {
                  isSubmitting = false;
                  uploadStatus = '';
                  uploadProgress = 0.0;
                });
                
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
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

// Helper to get content type
String _getContentType(String fileName) {
  final ext = fileName.split('.').last. toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'doc':
    case 'docx':
      return 'application/msword';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'txt':
      return 'text/plain';
    case 'zip':
      return 'application/zip';
    default:
      return 'application/octet-stream';
  }
}
}