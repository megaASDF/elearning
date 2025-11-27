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
      if (mounted) {
        setState(() {
          _semesters = data.map((json) => SemesterModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading semesters: $e')),
        );
      }
    }
  }

  Future<void> _showSemesterDialog({SemesterModel? semester}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SemesterFormDialog(semester: semester),
    );

    if (result == true) {
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
            const SnackBar(
              content: Text('Semester deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Semesters'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSemesterDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Semester'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _semesters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No semesters yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap the button below to create one'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSemesters,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _semesters.length,
                    itemBuilder: (context, index) {
                      final semester = _semesters[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                          title: Text(
                            semester.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${semester.code} • ${semester.startDate.day}/${semester.startDate.month}/${semester.startDate.year} - ${semester.endDate.day}/${semester.endDate.month}/${semester.endDate.year}'),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
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