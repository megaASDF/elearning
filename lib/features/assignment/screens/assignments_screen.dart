import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/providers/assignment_provider.dart';
import '../widgets/assignment_form_dialog.dart';
import 'assignment_detail_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  final String courseId;
  final bool isInstructor;

  const AssignmentsScreen({
    super.key,
    required this.courseId,
    required this.isInstructor,
  });

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<AssignmentModel> _assignments = [];
  List<AssignmentModel> _filteredAssignments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'created'; // created, title, deadline

  @override
  void initState() {
    super.initState();
    WidgetsBinding. instance.addPostFrameCallback((_) {
      _loadAssignments();
    });
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    final provider = context.read<AssignmentProvider>();
    await provider. loadAssignments(widget.courseId);
    
    if (mounted) {
      setState(() {
        _assignments = provider.assignments;
        _filteredAssignments = _assignments;
        _filterAndSort();
        _isLoading = false;
      });
    }
  }

  void _filterAndSort() {
    setState(() {
      // Filter
      if (_searchQuery.isEmpty) {
        _filteredAssignments = List.from(_assignments);
      } else {
        _filteredAssignments = _assignments.where((a) {
          return a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // Sort
      if (_sortBy == 'deadline') {
        _filteredAssignments.sort((a, b) => a.deadline.compareTo(b. deadline));
      } else if (_sortBy == 'title') {
        _filteredAssignments.sort((a, b) => a.title.compareTo(b.title));
      } else if (_sortBy == 'created') {
        _filteredAssignments.sort((a, b) => b.createdAt.compareTo(a. createdAt));
      }
    });
  }

  Future<void> _showAssignmentDialog({AssignmentModel? assignment}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AssignmentFormDialog(
        courseId: widget.courseId,
        assignment: assignment,
      ),
    );

    if (result == true) {
      await _loadAssignments();
    }
  }

  Future<void> _deleteAssignment(AssignmentModel assignment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.title}"?'),
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
        await context.read<AssignmentProvider>().deleteAssignment(assignment. id, widget.courseId);
        if (mounted) {
          ScaffoldMessenger.of(context). showSnackBar(
            const SnackBar(
              content: Text('Assignment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger. of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusChip(AssignmentModel assignment) {
    if (assignment. isPastDeadline) {
      return Chip(
        label: const Text('Closed', style: TextStyle(color: Colors. white)),
        backgroundColor: Colors. red,
        visualDensity: VisualDensity. compact,
      );
    } else if (assignment.isActive) {
      return Chip(
        label: const Text('Active', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        visualDensity: VisualDensity.compact,
      );
    } else {
      return Chip(
        label: const Text('Upcoming', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        visualDensity: VisualDensity.compact,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _filterAndSort();
              });
            },
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'deadline',
                checked: _sortBy == 'deadline',
                child: const Text('Sort by Deadline'),
              ),
              CheckedPopupMenuItem(
                value: 'title',
                checked: _sortBy == 'title',
                child: const Text('Sort by Title'),
              ),
              CheckedPopupMenuItem(
                value: 'created',
                checked: _sortBy == 'created',
                child: const Text('Sort by Created'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: widget.isInstructor
          ?  FloatingActionButton. extended(
              onPressed: () => _showAssignmentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Assignment'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search assignments...',
                prefixIcon: const Icon(Icons. search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterAndSort();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAssignments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No assignments yet'
                                  : 'No assignments found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAssignments,
                        child: ListView. builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAssignments.length,
                          itemBuilder: (context, index) {
                            final assignment = _filteredAssignments[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AssignmentDetailScreen(
                                        assignmentId: assignment.id,
                                        isInstructor: widget.isInstructor,
                                      ),
                                    ),
                                  ). then((_) => _loadAssignments());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              assignment.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          _buildStatusChip(assignment),
                                          if (widget.isInstructor) ...[
                                            const SizedBox(width: 8),
                                            PopupMenuButton(
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
                                                      Icon(Icons.delete,
                                                          size: 20, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete',
                                                          style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _showAssignmentDialog(assignment: assignment);
                                                } else if (value == 'delete') {
                                                  _deleteAssignment(assignment);
                                                }
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        assignment.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Due: ${assignment.deadline.day}/${assignment.deadline.month}/${assignment.deadline.year} ${assignment.deadline.hour. toString().padLeft(2, '0')}:${assignment.deadline.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                          if (assignment.attachments.isNotEmpty) ...[
                                            const SizedBox(width: 16),
                                            Icon(Icons.attach_file,
                                                size: 16, color: Colors. grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${assignment.attachments.length} file(s)',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}