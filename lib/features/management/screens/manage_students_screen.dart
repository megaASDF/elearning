import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final data = await api.getAllStudents();
      if (mounted) {
        setState(() {
          _students = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addStudentDialog() async {
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username (Login ID)'),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty) {
                try {
                  await ApiService().createStudent({
                    'username': usernameController.text,
                    'displayName': nameController.text,
                    'email': emailController.text,
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _loadStudents(); // Refresh list
                  }
                } catch (e) {
                  // Handle error
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Students')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudentDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No students found. Add one!'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final s = _students[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          (s['displayName'] ?? 'U')[0].toUpperCase(),
                        ),
                      ),
                      title: Text(s['displayName'] ?? 'Unknown'),
                      subtitle: Text('${s['username']} • ${s['email']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await ApiService().deleteStudent(s['id']);
                          _loadStudents();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}