import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/providers/assignment_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentFormDialog extends StatefulWidget {
  final String courseId;
  final AssignmentModel? assignment;

  const AssignmentFormDialog({
    super.key,
    required this. courseId,
    this.assignment,
  });

  @override
  State<AssignmentFormDialog> createState() => _AssignmentFormDialogState();
}

class _AssignmentFormDialogState extends State<AssignmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxFileSizeController;
  
  late DateTime _startDate;
  late DateTime _deadline;
  DateTime? _lateDeadline;
  bool _allowLateSubmission = false;
  int _maxAttempts = 1;
  bool _unlimitedAttempts = false;
  List<String> _selectedFormats = ['pdf'];
  bool _isLoading = false;

  final List<String> _availableFormats = [
    'pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'zip', 'rar'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    
    _titleController = TextEditingController(text: widget.assignment?. title ?? '');
    _descriptionController = TextEditingController(text: widget.assignment?.description ??  '');
    _maxFileSizeController = TextEditingController(
      text: widget.assignment?.maxFileSizeMB. toString() ?? '10'
    );
    
    _startDate = widget.assignment?.startDate ??  now;
    _deadline = widget.assignment?.deadline ?? now.add(Duration(days: 7));
    _lateDeadline = widget.assignment?.lateDeadline;
    _allowLateSubmission = widget.assignment?. allowLateSubmission ?? false;
    _maxAttempts = widget.assignment?.maxAttempts ?? 1;
    _unlimitedAttempts = _maxAttempts == -1;
    _selectedFormats = widget.assignment?.allowedFileFormats ?? ['pdf'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController. dispose();
    _maxFileSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDeadline) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDeadline ? _deadline : _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isDeadline ? _deadline : _startDate),
      );
      
      if (timePicked != null) {
        setState(() {
          final newDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
          
          if (isDeadline) {
            _deadline = newDateTime;
          } else {
            _startDate = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _selectLateDeadline(BuildContext context) async {
    final DateTime?  picked = await showDatePicker(
      context: context,
      initialDate: _lateDeadline ?? _deadline. add(Duration(days: 3)),
      firstDate: _deadline,
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_lateDeadline ?? _deadline),
      );
      
      if (timePicked != null) {
        setState(() {
          _lateDeadline = DateTime(
            picked.year,
            picked. month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      if (widget.assignment == null) {
        // Create new
        await firestore.collection('assignments').add({
          'courseId': widget.courseId,
          'groupIds': [],
          'title': _titleController.text. trim(),
          'description': _descriptionController.text.trim(),
          'attachments': [],
          'startDate': Timestamp. fromDate(_startDate),
          'deadline': Timestamp.fromDate(_deadline),
          'lateDeadline': _lateDeadline != null ? Timestamp.fromDate(_lateDeadline!) : null,
          'allowLateSubmission': _allowLateSubmission,
          'maxAttempts': _unlimitedAttempts ? -1 : _maxAttempts,
          'allowedFileFormats': _selectedFormats,
          'maxFileSizeMB': double.tryParse(_maxFileSizeController.text) ?? 10.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue. serverTimestamp(),
        });
      } else {
        // Update existing
        await firestore.collection('assignments').doc(widget.assignment!.id).update({
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'startDate': Timestamp.fromDate(_startDate),
          'deadline': Timestamp.fromDate(_deadline),
          'lateDeadline': _lateDeadline != null ? Timestamp.fromDate(_lateDeadline!) : null,
          'allowLateSubmission': _allowLateSubmission,
          'maxAttempts': _unlimitedAttempts ? -1 : _maxAttempts,
          'allowedFileFormats': _selectedFormats,
          'maxFileSizeMB': double.tryParse(_maxFileSizeController.text) ?? 10.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Reload assignments
      if (mounted) {
        await context.read<AssignmentProvider>().loadAssignments(widget. courseId);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.assignment == null
                ? 'Assignment created successfully'
                : 'Assignment updated successfully'),
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
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.assignment == null ? 'Create Assignment' : 'Edit Assignment'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets. all(24),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  enabled: ! _isLoading,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // Start Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start Date'),
                  subtitle: Text(
                    '${_startDate.day}/${_startDate.month}/${_startDate.year} '
                    '${_startDate.hour. toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}'
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _isLoading ? null : () => _selectDate(context, false),
                  ),
                ),

                // Deadline
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Deadline *'),
                  subtitle: Text(
                    '${_deadline. day}/${_deadline.month}/${_deadline.year} '
                    '${_deadline.hour.toString().padLeft(2, '0')}:${_deadline.minute.toString().padLeft(2, '0')}'
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _isLoading ? null : () => _selectDate(context, true),
                  ),
                ),
                const SizedBox(height: 16),

                // Allow Late Submission
                SwitchListTile(
                  contentPadding: EdgeInsets. zero,
                  title: const Text('Allow Late Submission'),
                  value: _allowLateSubmission,
                  onChanged: _isLoading ? null : (value) {
                    setState(() => _allowLateSubmission = value);
                  },
                ),

                // Late Deadline (if enabled)
                if (_allowLateSubmission) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Late Deadline'),
                    subtitle: Text(_lateDeadline != null
                        ? '${_lateDeadline! .day}/${_lateDeadline!.month}/${_lateDeadline!.year} '
                          '${_lateDeadline!.hour.toString().padLeft(2, '0')}:${_lateDeadline! .minute.toString().padLeft(2, '0')}'
                        : 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _isLoading ? null : () => _selectLateDeadline(context),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Max Attempts
                Row(
                  children: [
                    Expanded(
                      child: Text('Max Attempts', style: Theme.of(context).textTheme.titleMedium),
                    ),
                    Checkbox(
                      value: _unlimitedAttempts,
                      onChanged: _isLoading ? null : (value) {
                        setState(() => _unlimitedAttempts = value ??  false);
                      },
                    ),
                    const Text('Unlimited'),
                  ],
                ),
                if (! _unlimitedAttempts)
                  Slider(
                    value: _maxAttempts.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_maxAttempts',
                    onChanged: _isLoading ? null : (value) {
                      setState(() => _maxAttempts = value. toInt());
                    },
                  ),
                const SizedBox(height: 16),

                // Allowed File Formats
                Text('Allowed File Formats', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableFormats.map((format) {
                    final isSelected = _selectedFormats. contains(format);
                    return FilterChip(
                      label: Text(format. toUpperCase()),
                      selected: isSelected,
                      onSelected: _isLoading ? null : (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFormats. add(format);
                          } else {
                            _selectedFormats.remove(format);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Max File Size
                TextFormField(
                  controller: _maxFileSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Max File Size (MB)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value. trim().isEmpty) {
                      return 'Please enter max file size';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ?  null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(widget.assignment == null ? 'Create Assignment' : 'Update Assignment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}