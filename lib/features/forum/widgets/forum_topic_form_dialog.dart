import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class ForumTopicFormDialog extends StatefulWidget {
  final String courseId;

  const ForumTopicFormDialog({super.key, required this.courseId});

  @override
  State<ForumTopicFormDialog> createState() => _ForumTopicFormDialogState();
}

class _ForumTopicFormDialogState extends State<ForumTopicFormDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _selectedGroupIds = [];
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final apiService = ApiService();
      final groupsData = await apiService.getGroups(widget.courseId);
      if (mounted) {
        setState(() {
          _groups = groupsData. cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text. trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_selectedGroupIds.isEmpty) {
      ScaffoldMessenger. of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one group')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('User not logged in');
      }

      await ApiService().createForumTopic({
        'courseId': widget.courseId,
        'title': _titleController. text.trim(),
        'content': _contentController.text.trim(),
        'authorId': user.id,
        'authorName': user.displayName,
        'groupIds': _selectedGroupIds,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error creating topic: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Discussion Topic'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size. width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                enabled: ! _isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Groups',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_groups.isEmpty)
                const Text('No groups available')
              else
                ..._groups.map((group) {
                  final groupId = group['id'] as String;
                  final groupName = group['name'] as String;
                  return CheckboxListTile(
                    value: _selectedGroupIds. contains(groupId),
                    onChanged: _isLoading
                        ? null
                        : (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedGroupIds.add(groupId);
                              } else {
                                _selectedGroupIds.remove(groupId);
                              }
                            });
                          },
                    title: Text(groupName),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
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