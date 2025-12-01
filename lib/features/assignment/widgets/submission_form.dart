import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/submission_provider.dart';

class SubmissionForm extends StatefulWidget {
  final String assignmentId;
  final VoidCallback onSuccess;

  const SubmissionForm({
    super.key,
    required this.assignmentId,
    required this.onSuccess,
  });

  @override
  State<SubmissionForm> createState() => _SubmissionFormState();
}

class _SubmissionFormState extends State<SubmissionForm> {
  List<PlatformFile> _files = [];
  bool _isLoading = false;
  String _uploadProgress = '';
  double _progressValue = 0.0;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform. pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'txt'],
    );
    
    if (result != null) {
      setState(() {
        _files.addAll(result. files);
      });
    }
  }

  Future<String> _uploadFileToStorage(PlatformFile file, int index, int total) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('submissions/${widget.assignmentId}/$fileName');

      UploadTask uploadTask;
      
      if (kIsWeb && file.bytes != null) {
        // Web upload using bytes
        uploadTask = storageRef.putData(
          file.bytes!,
          SettableMetadata(contentType: _getContentType(file.name)),
        );
      } else if (file.path != null) {
        // Mobile/Desktop upload using file path
        uploadTask = storageRef.putFile(
          File(file.path!),
          SettableMetadata(contentType: _getContentType(file. name)),
        );
      } else {
        throw Exception('No file data available');
      }

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (mounted) {
          setState(() {
            _progressValue = ((index + progress) / total);
            _uploadProgress = 'Uploading ${file.name} (${(progress * 100).toStringAsFixed(0)}%)';
          });
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Uploaded: ${file.name} -> $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading ${file.name}: $e');
      rethrow;
    }
  }

  String _getContentType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd. openxmlformats-officedocument.wordprocessingml. document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _submit() async {
    if (_files.isEmpty) {
      ScaffoldMessenger. of(context).showSnackBar(
        const SnackBar(content: Text('Please attach at least one file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 'Starting upload...';
      _progressValue = 0.0;
    });

    try {
      // Upload all files
      List<String> fileUrls = [];
      for (int i = 0; i < _files.length; i++) {
        final url = await _uploadFileToStorage(_files[i], i, _files.length);
        fileUrls.add(url);
      }

      setState(() {
        _uploadProgress = 'Submitting assignment...';
        _progressValue = 1.0;
      });

      // Submit assignment with file URLs
      final user = context.read<AuthProvider>().user! ;
      final submissionProvider = context.read<SubmissionProvider>();
      
      await submissionProvider.submitAssignment(
        widget.assignmentId,
        user.id,
        user.displayName,
        fileUrls,
      );

      widget.onSuccess();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors. red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = '';
          _progressValue = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Work',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_files.isEmpty)
              const Text(
                'No files attached',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ..._files.map((f) => ListTile(
              leading: const Icon(Icons.file_present),
              title: Text(f. name),
              subtitle: Text('${(f.size / 1024).toStringAsFixed(2)} KB'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _files.remove(f)),
              ),
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              LinearProgressIndicator(value: _progressValue),
              const SizedBox(height: 8),
              Text(
                _uploadProgress,
                style: const TextStyle(fontSize: 14, color: Colors. blue),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add File'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _files.isEmpty ?  null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Turn In'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}