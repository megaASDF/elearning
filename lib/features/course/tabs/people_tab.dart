import 'package:flutter/material.dart';
import '../../../core/models/group_model.dart';
import '../../../core/services/api_service.dart';

class PeopleTab extends StatefulWidget {
  final String courseId;

  const PeopleTab({super.key, required this.courseId});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getGroups(widget.courseId);
      setState(() {
        _groups = data.map((json) => GroupModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groups.isEmpty) {
      return const Center(child: Text('No groups found'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: const Text('Administrator'),
            subtitle: const Text('Instructor'),
            trailing: IconButton(
              icon: const Icon(Icons.email),
              onPressed: () {
                // Send message to instructor
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Students',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ..._groups.map((group) => _buildGroupCard(group)),
      ],
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.groups),
        title: Text(group.name),
        subtitle: Text('${group.studentCount} students'),
        children: [
          ListTile(
            title: const Text('View all students'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              // Navigate to group students list
            },
          ),
        ],
      ),
    );
  }
}