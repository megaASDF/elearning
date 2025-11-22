import 'package:flutter/material.dart';
import '../../../core/models/semester_model.dart';
import '../../../core/services/api_service.dart';
import '../widgets/semester_form_dialog.dart';

class ManageSemestersScreen extends StatefulWidget {
  const ManageSemestersScreen({super.key});

  @override
  State<ManageSemestersScreen> createState() => _ManageSemestersScreenState();
}

class _ManageSemestersScreenState extends State<ManageSemestersScreen> {
  List<SemesterModel> _semesters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getSemesters();
      setState(() {
        _semesters = data.map((json) => SemesterModel.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSemesterDialog({SemesterModel? semester}) async {
    final result = await showDialog<SemesterModel>(
      context: context,
      builder: (context) => SemesterFormDialog(semester: semester),
    );

    if (result != null) {
      await _loadSemesters();
    }
  }

  Future<void> _deleteSemester(SemesterModel semester) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Semester'),
        content: Text('Are you sure you want to delete ${semester.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final apiService = ApiService();
        await apiService.deleteSemester(semester.id);
        await _loadSemesters();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semester deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Semesters'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSemesterDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Semester'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _semesters.isEmpty
              ? const Center(child: Text('No semesters yet'))
              : RefreshIndicator(
                  onRefresh: _loadSemesters,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _semesters.length,
                    itemBuilder: (context, index) {
                      final semester = _semesters[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: semester.isCurrent
                                ? Colors.green
                                : Colors.grey,
                            child: Icon(
                              semester.isCurrent
                                  ? Icons.check
                                  : Icons.calendar_today,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(semester.name),
                          subtitle: Text(
                            '${semester.code} • ${semester.startDate.year}',
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showSemesterDialog(semester: semester);
                              } else if (value == 'delete') {
                                _deleteSemester(semester);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}