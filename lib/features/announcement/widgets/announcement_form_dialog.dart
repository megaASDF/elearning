import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/announcement_provider.dart';

class AnnouncementFormDialog extends StatefulWidget {
  final String courseId;

  const AnnouncementFormDialog({
    super.key,
    required this. courseId,
  });

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<PlatformFile> _attachments = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _attachments. addAll(result.files);
      });
    }
  }

  Future<String> _uploadFile(PlatformFile file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('announcements/${widget.courseId}/$fileName');

    UploadTask uploadTask;

    if (file.bytes != null) {
      uploadTask = storageRef. putData(file.bytes!);
    } else if (file.path != null) {
      uploadTask = storageRef.putFile(File(file. path!));
    } else {
      throw Exception('No file data available');
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (! _formKey.currentState!. validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload attachments
      List<String> attachmentUrls = [];
      for (var file in _attachments) {
        final url = await _uploadFile(file);
        attachmentUrls.add(url);
      }

      // Create announcement
      final authProvider = context.read<AuthProvider>();
      final announcementProvider = context.read<AnnouncementProvider>();

      await announcementProvider.createAnnouncement(
        widget.courseId,
        _titleController.text. trim(),
        _contentController. text.trim(),
        authProvider.user?. displayName ?? 'Instructor',
        attachmentUrls,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors. red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Announcement'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value. trim().isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              if (_attachments.isNotEmpty) ...[
                const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._attachments.map((file) => ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(file.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _attachments.remove(file)),
                  ),
                  contentPadding: EdgeInsets.zero,
                )),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _isLoading ?  null : _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Attachments'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}