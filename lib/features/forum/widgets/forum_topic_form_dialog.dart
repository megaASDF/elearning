import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ForumTopicFormDialog extends StatefulWidget {
  final String courseId;

  const ForumTopicFormDialog({super.key, required this.courseId});

  @override
  State<ForumTopicFormDialog> createState() => _ForumTopicFormDialogState();
}

class _ForumTopicFormDialogState extends State<ForumTopicFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final data = {
        'courseId': widget.courseId,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'authorId': '2', // Replace with actual user ID
        'authorName': 'Current User',
        'attachments': [],
      };

      await apiService.createForumTopic(data);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topic created successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Topic', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content *', border: OutlineInputBorder()),
                maxLines: 5,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}