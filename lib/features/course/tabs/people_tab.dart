import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/group_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class PeopleTab extends StatefulWidget {
  final String courseId;

  const PeopleTab({super.key, required this.courseId});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  List<GroupModel> _groups = [];
  Map<String, List<dynamic>> _studentsByGroup = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final groupsData = await apiService.getGroups(widget.courseId);
      final groups = groupsData.map((json) => GroupModel.fromJson(json)).toList();

      Map<String, List<dynamic>> studentsMap = {};
      for (var g in groups) {
        final students = await apiService.getStudents(widget.courseId, groupId: g.id);
        studentsMap[g.id] = students;
      }

      if (mounted) {
        setState(() {
          _groups = groups;
          _studentsByGroup = studentsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Create Group ---
  Future<void> _createGroupDialog() async {
    final nameCtrl = TextEditingController();
    bool isCreating = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Group Name (e.g. Group 1)'),
                enabled: !isCreating,
              ),
              if (isCreating) ...[
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Creating group...'),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a group name'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      setDialogState(() => isCreating = true);
                      
                      try {
                        await ApiService().createGroup({
                          'courseId': widget.courseId,
                          'name': nameCtrl.text.trim(),
                        });
                        
                        if (mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Group created successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadData(); // Refresh
                        }
                      } catch (e) {
                        setDialogState(() => isCreating = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating group: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Add Student to Group ---
  Future<void> _addStudentDialog(String groupId) async {
    // Fetch all students to pick from
    final allStudents = await ApiService().getAllStudents();
    
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Select Student to Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  final s = allStudents[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(s['displayName'][0])),
                    title: Text(s['displayName']),
                    subtitle: Text(s['username']),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: () async {
                        await ApiService().enrollStudent(s['id'], widget.courseId, groupId);
                        if (mounted) {
                          Navigator.pop(context); // Close sheet
                          _loadData(); // Refresh list
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is instructor
    final user = context.read<AuthProvider>().user;
    final isInstructor = user?.role == 'instructor';

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructor Actions
          if (isInstructor)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createGroupDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create New Group'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          const SizedBox(height: 16),

          // Groups List
          if (_groups.isEmpty)
            const Center(child: Text('No groups created yet.'))
          else
            ..._groups.map((group) => Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                leading: const Icon(Icons.groups),
                title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${_studentsByGroup[group.id]?.length ?? 0} Students'),
                children: [
                  if (isInstructor)
                    ListTile(
                      leading: const Icon(Icons.person_add, color: Colors.blue),
                      title: const Text('Add Student to this group'),
                      onTap: () => _addStudentDialog(group.id),
                    ),
                  ...(_studentsByGroup[group.id] ?? []).map((s) => ListTile(
                    leading: CircleAvatar(child: Text(s['displayName'][0] ?? 'S')),
                    title: Text(s['displayName'] ?? 'Unknown'),
                    subtitle: Text(s['email'] ?? ''),
                  )),
                ],
              ),
            )),
        ],
      ),
    );
  }
}