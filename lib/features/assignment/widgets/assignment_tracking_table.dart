import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Required for opening files
import '../../../core/services/csv_export_service.dart';
import '../../../core/models/submission_model.dart';
import '../../../core/providers/submission_provider.dart';

class AssignmentTrackingTable extends StatefulWidget {
  final String assignmentId;
  final String courseId;
  final String assignmentTitle;

  const AssignmentTrackingTable({
    super.key,
    required this.assignmentId,
    required this.courseId,
    required this.assignmentTitle,
  });

  @override
  State<AssignmentTrackingTable> createState() =>
      _AssignmentTrackingTableState();
}

class _AssignmentTrackingTableState extends State<AssignmentTrackingTable> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _filterStatus = 'all'; // all, submitted, not_submitted, late, graded
  String _filterGroup = 'all';
  String _sortBy = 'name'; // name, status, time, grade

  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load groups
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      _groups = groupsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Load all enrolled students
      final enrollmentsSnapshot = await _firestore
          .collection('enrollments')
          .where('courseId', isEqualTo: widget.courseId)
          .get();

      final studentIds = enrollmentsSnapshot.docs
          .map((doc) => doc.data()['studentId'] as String)
          .toSet()
          .toList();

      _allStudents = [];
      for (var studentId in studentIds) {
        final studentDoc =
            await _firestore.collection('users').doc(studentId).get();
        if (studentDoc.exists) {
          final enrollment = enrollmentsSnapshot.docs.firstWhere(
            (e) => e.data()['studentId'] == studentId,
          );

          _allStudents.add({
            'id': studentDoc.id,
            ...studentDoc.data()!,
            'groupId': enrollment.data()['groupId'],
          });
        }
      }

      // Load submissions
      final submissionsSnapshot = await _firestore
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.assignmentId)
          .get();

      _submissions = submissionsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
                'submittedAt':
                    (doc.data()['submittedAt'] as Timestamp?)?.toDate(),
              })
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    var filtered = _allStudents.where((student) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final name = student['displayName']?.toString().toLowerCase() ?? '';
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }

      // Group filter
      if (_filterGroup != 'all' && student['groupId'] != _filterGroup) {
        return false;
      }

      // Status filter
      final submission = _submissions
          .where((s) => s['studentId'] == student['id'])
          .firstOrNull;

      if (_filterStatus == 'submitted' && submission == null) return false;
      if (_filterStatus == 'not_submitted' && submission != null) return false;
      if (_filterStatus == 'late' &&
          (submission == null || submission['isLate'] != true)) return false;
      if (_filterStatus == 'graded' &&
          (submission == null || submission['grade'] == null)) return false;

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return (a['displayName'] ?? '').compareTo(b['displayName'] ?? '');
        case 'status':
          final aSubmitted = _submissions.any((s) => s['studentId'] == a['id']);
          final bSubmitted = _submissions.any((s) => s['studentId'] == b['id']);
          return aSubmitted == bSubmitted ? 0 : (aSubmitted ? -1 : 1);
        case 'time':
          final aSub =
              _submissions.where((s) => s['studentId'] == a['id']).firstOrNull;
          final bSub =
              _submissions.where((s) => s['studentId'] == b['id']).firstOrNull;
          if (aSub == null && bSub == null) return 0;
          if (aSub == null) return 1;
          if (bSub == null) return -1;
          return (bSub['submittedAt'] as DateTime)
              .compareTo(aSub['submittedAt'] as DateTime);
        case 'grade':
          final aSub =
              _submissions.where((s) => s['studentId'] == a['id']).firstOrNull;
          final bSub =
              _submissions.where((s) => s['studentId'] == b['id']).firstOrNull;
          final aGrade = aSub?['grade'] ?? 0.0;
          final bGrade = bSub?['grade'] ?? 0.0;
          return bGrade.compareTo(aGrade);
        default:
          return 0;
      }
    });

    return filtered;
  }

  String _getGroupName(String? groupId) {
    if (groupId == null) return 'No Group';
    final group = _groups.where((g) => g['id'] == groupId).firstOrNull;
    return group?['name'] ?? 'Unknown';
  }

  Future<void> _exportToCSV() async {
    try {
      final submissions = _filteredStudents.map((student) {
        final submission = _submissions
            .where((s) => s['studentId'] == student['id'])
            .firstOrNull;

        return SubmissionModel(
          id: submission?['id'] ?? '',
          assignmentId: widget.assignmentId,
          studentId: student['id'],
          studentName: student['displayName'] ?? '',
          studentEmail: student['email'] ?? '',
          files: submission != null
              ? List<String>.from(submission['fileUrls'] ?? [])
              : [],
          submittedAt: submission?['submittedAt'] ?? DateTime.now(),
          attemptNumber: submission?['attemptNumber'] ?? 0,
          isLate: submission?['isLate'] ?? false,
          grade: submission?['grade']?.toDouble(),
          feedback: submission?['feedback'],
          gradedAt: submission?['gradedAt'] != null
              ? (submission?['gradedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();

      final filePath = await CsvExportService.exportSubmissions(
        submissions: submissions,
        assignmentTitle: widget.assignmentTitle,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  void _showSubmissionDetails(
      Map<String, dynamic> submission, Map<String, dynamic> student) {
    final fileUrls = List<String>.from(submission['fileUrls'] ?? []);
    final gradeController =
        TextEditingController(text: submission['grade']?.toString() ?? '');
    final feedbackController =
        TextEditingController(text: submission['feedback']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submission: ${student['displayName']}'),
        content: SizedBox(
          width: 500, // Fixed width for better layout on desktop
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Submission Time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Submitted: ${_formatDate(submission['submittedAt'])}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (submission['isLate'] == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LATE',
                          style: TextStyle(
                              color: Colors.red.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Files List
                const Text('Attached Files:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (fileUrls.isEmpty)
                  const Text('No files attached.',
                      style: TextStyle(fontStyle: FontStyle.italic))
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: fileUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final url = entry.value;
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.file_present,
                              color: Colors.blue),
                          title: Text('Attachment ${index + 1}'),
                          subtitle: Text(
                            'Click to view',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'Open File',
                            onPressed: () => _launchUrl(url),
                          ),
                          onTap: () => _launchUrl(url),
                        );
                      }).toList(),
                    ),
                  ),

                const Divider(height: 32),

                // Grading Section
                const Text('Grade & Feedback',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: gradeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Grade (0-100)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grade),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Feedback (Optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Grade'),
            onPressed: () async {
              final grade = double.tryParse(gradeController.text);
              if (grade == null || grade < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid positive grade')),
                );
                return;
              }

              try {
                // Use SubmissionProvider to grade
                await Provider.of<SubmissionProvider>(context, listen: false)
                    .gradeSubmission(
                  submission['id'],
                  widget.assignmentId,
                  grade,
                  feedbackController.text,
                );

                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  _loadData(); // Refresh table data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grade saved successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error saving grade: $e'),
                      backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final submittedCount = _allStudents.where((s) {
      return _submissions.any((sub) => sub['studentId'] == s['id']);
    }).length;

    final notSubmittedCount = _allStudents.length - submittedCount;
    final lateCount = _submissions.where((s) => s['isLate'] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('$submittedCount',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Submitted'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('$notSubmittedCount',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Not Submitted'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('$lateCount',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const Text('Late'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Filters
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _filterGroup,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Groups')),
                ..._groups.map((g) => DropdownMenuItem(
                      value: g['id'],
                      child: Text(g['name']),
                    )),
              ],
              onChanged: (value) => setState(() => _filterGroup = value!),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _filterStatus,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                DropdownMenuItem(
                    value: 'not_submitted', child: Text('Not Submitted')),
                DropdownMenuItem(value: 'late', child: Text('Late')),
                DropdownMenuItem(value: 'graded', child: Text('Graded')),
              ],
              onChanged: (value) => setState(() => _filterStatus = value!),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportToCSV,
              tooltip: 'Export to CSV',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                sortColumnIndex:
                    _sortBy == 'name' ? 0 : (_sortBy == 'status' ? 2 : null),
                sortAscending: true,
                columns: [
                  DataColumn(
                    label: const Text('Student Name'),
                    onSort: (_, __) => setState(() => _sortBy = 'name'),
                  ),
                  const DataColumn(label: Text('Group')),
                  DataColumn(
                    label: const Text('Status'),
                    onSort: (_, __) => setState(() => _sortBy = 'status'),
                  ),
                  DataColumn(
                    label: const Text('Submitted At'),
                    onSort: (_, __) => setState(() => _sortBy = 'time'),
                  ),
                  const DataColumn(label: Text('Attempt')),
                  DataColumn(
                    label: const Text('Grade'),
                    onSort: (_, __) => setState(() => _sortBy = 'grade'),
                  ),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: _filteredStudents.map((student) {
                  final submission = _submissions
                      .where((s) => s['studentId'] == student['id'])
                      .firstOrNull;
                  final hasSubmitted = submission != null;
                  final isLate = submission?['isLate'] == true;
                  final grade = submission?['grade'];

                  return DataRow(
                    cells: [
                      DataCell(Text(student['displayName'] ?? 'Unknown')),
                      DataCell(Text(_getGroupName(student['groupId']))),
                      DataCell(
                        Chip(
                          label: Text(
                            hasSubmitted
                                ? (isLate ? 'Late' : 'Submitted')
                                : 'Not Submitted',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: hasSubmitted
                              ? (isLate ? Colors.orange : Colors.green)
                              : Colors.red,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(Text(
                        _formatDate(submission != null
                            ? submission['submittedAt']
                            : null),
                      )),
                      DataCell(Text(hasSubmitted
                          ? '${submission['attemptNumber'] ?? 1}'
                          : '-')),
                      DataCell(Text(grade != null ? '$grade' : '-')),
                      DataCell(
                        hasSubmitted
                            ? IconButton(
                                icon: const Icon(Icons.visibility, size: 20),
                                color: Colors.blue,
                                tooltip: 'View & Grade',
                                onPressed: () {
                                  _showSubmissionDetails(submission, student);
                                },
                              )
                            : const Text('-'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}