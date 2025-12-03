import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/announcement_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/api_service.dart';

class AnnouncementFormDialog extends StatefulWidget {
  final String courseId;
  
  const AnnouncementFormDialog({super.key, required this.courseId});

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _groups = [];
  List<String> _selectedGroupIds = [];
  bool _selectAllGroups = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final apiService = ApiService();
      final groups = await apiService.getGroups(widget.courseId);
      setState(() {
        _groups = groups. cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Error loading groups: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

Future<void> _submit() async {
  if (! _formKey.currentState!. validate()) return;

  setState(() => _isLoading = true);

  try {
    final authProvider = context.read<AuthProvider>();
    final notificationService = NotificationService();
    final apiService = ApiService();  // CREATE INSTANCE DIRECTLY

    // Determine which groups to notify
    final groupIds = _selectAllGroups ? <String>[] : _selectedGroupIds;

    // Create announcement in Firestore
    final announcementData = await apiService.createAnnouncement({  // NOW IT WORKS
      'courseId': widget.courseId,
      'title': _titleController.text. trim(),
      'content': _contentController.text.trim(),
      'authorName': authProvider.user?. displayName ?? 'Instructor',
      'attachmentUrls': [],
      'groupIds': groupIds,
    });

    // Send in-app notifications to students
    await notificationService.notifyNewAnnouncement(
      courseId: widget.courseId,
      announcementId: announcementData['id'],
      announcementTitle: _titleController.text.trim(),
      groupIds: groupIds,
    );

    // Reload announcements
    await context.read<AnnouncementProvider>().loadAnnouncements(widget.courseId);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Announcement created & notifications sent!'),
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
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?. trim().isEmpty ?? true) {
                      return 'Title is required';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Content is required';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // Group Selection
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Notify Groups:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                
                CheckboxListTile(
                  title: const Text('All Groups'),
                  value: _selectAllGroups,
                  onChanged: _isLoading ? null : (value) {
                    setState(() {
                      _selectAllGroups = value ??  false;
                      if (_selectAllGroups) {
                        _selectedGroupIds. clear();
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                if (! _selectAllGroups && _groups.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey. shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _groups. length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        final groupId = group['id'] as String;
                        final groupName = group['name'] as String;

                        return CheckboxListTile(
                          title: Text(groupName),
                          subtitle: Text('${group['studentCount'] ?? 0} students'),
                          value: _selectedGroupIds. contains(groupId),
                          onChanged: _isLoading ? null : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedGroupIds.add(groupId);
                              } else {
                                _selectedGroupIds.remove(groupId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],

                if (! _selectAllGroups && _selectedGroupIds.isEmpty && _groups.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '⚠️ Please select at least one group',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],

                if (_isLoading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text(
                    'Creating announcement & sending notifications...',
                    style: TextStyle(fontSize: 14, color: Colors. blue),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading || (! _selectAllGroups && _selectedGroupIds.isEmpty) 
              ? null 
              : _submit,
          child: Text(_isLoading ? 'Creating...' : 'Create & Notify'),
        ),
      ],
    );
  }
}