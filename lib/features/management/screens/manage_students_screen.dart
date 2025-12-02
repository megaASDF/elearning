import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../profile/screens/student_profile_edit_screen.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  @override
  void initState() {
    super. initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>(). loadAllStudents();
    });
  }

  Future<void> _addStudentDialog() async {
    final usernameController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = ! obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Password must be at least 6 characters',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator. pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.trim().isEmpty ||
                    nameController.text. trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text. isEmpty) {
                  ScaffoldMessenger.of(context). showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                if (! emailController.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid email'),
                      backgroundColor: Colors. orange,
                    ),
                  );
                  return;
                }

                try {
                  // Save current auth state
                  final authProvider = context.read<AuthProvider>();
                  final currentUserEmail = authProvider.user?.email;
                  
                  await context.read<StudentProvider>().createStudent(
                    usernameController.text.trim(),
                    emailController.text.trim(),
                    nameController.text.trim(),
                    passwordController.text,
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    
                    // Show re-login dialog
                    _showReLoginDialog(currentUserEmail);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReLoginDialog(String?  email) async {
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Re-login Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Student created successfully! Please re-login to continue.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Your Password',
                border: const OutlineInputBorder(),
                hintText: email ?? '',
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<AuthProvider>().login(
                  'admin',
                  passwordController.text,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student created and you\'re logged back in!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Login failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons. refresh),
            onPressed: () {
              context.read<StudentProvider>().loadAllStudents();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton. extended(
        onPressed: _addStudentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider. isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No students yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click the button below to add students',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.students.length,
            itemBuilder: (context, index) {
              final student = provider.students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      (student.displayName.isNotEmpty ? student.displayName[0] : 'S'). toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(student.displayName),
                  subtitle: Text('${student.username} • ${student.email}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // EDIT BUTTON - NEW! 
                      IconButton(
                        icon: const Icon(Icons. edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentProfileEditScreen(
                                studentId: student.id,
                              ),
                            ),
                          );
                          
                          // Reload students if changes were made
                          if (result == true && mounted) {
                            provider. loadAllStudents();
                          }
                        },
                        tooltip: 'Edit Student',
                      ),
                      // DELETE BUTTON
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors. red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Student'),
                              content: Text('Are you sure you want to delete ${student.displayName}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator. pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors. red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            await provider.deleteStudent(student.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Student deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        tooltip: 'Delete Student',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}