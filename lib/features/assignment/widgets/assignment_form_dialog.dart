import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/models/assignment_model.dart';
import '../../../core/services/api_service.dart';

class AssignmentFormDialog extends StatefulWidget {
  final String courseId;
  final AssignmentModel? assignment;

  const AssignmentFormDialog({
    super.key,
    required this.courseId,
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
  List<String> _selectedFormats = ['pdf'];
  List<String> _attachments = [];
  bool _isLoading = false;

  final List<String> _availableFormats = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'jpg',
    'png',
    'zip'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.assignment?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.assignment?.description ?? '');
    _maxFileSizeController = TextEditingController(
        text: widget.assignment?.maxFileSizeMB.toString() ?? '10');
    _startDate = widget.assignment?.startDate ?? DateTime.now();
    _deadline = widget.assignment?.deadline ??
        DateTime.now().add(const Duration(days: 7));
    _lateDeadline = widget.assignment?.lateDeadline;
    _allowLateSubmission = widget.assignment?.allowLateSubmission ?? false;
    _maxAttempts = widget.assignment?.maxAttempts ?? 1;
    _selectedFormats = widget.assignment?.allowedFileFormats ?? ['pdf'];
    _attachments = widget.assignment?.attachments ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxFileSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files.map((file) => file.path ?? ''));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_deadline.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline must be after start date')),
      );
      return;
    }

    if (_allowLateSubmission && _lateDeadline != null) {
      if (_lateDeadline!.isBefore(_deadline)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Late deadline must be after deadline')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final data = {
        'courseId': widget.courseId,
        'groupIds': [], // Add group selection logic
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'attachments': _attachments,
        'startDate': _startDate.toIso8601String(),
        'deadline': _deadline.toIso8601String(),
        'lateDeadline': _lateDeadline?.toIso8601String(),
        'allowLateSubmission': _allowLateSubmission,
        'maxAttempts': _maxAttempts,
        'allowedFileFormats': _selectedFormats,
        'maxFileSizeMB': double.parse(_maxFileSizeController.text),
      };

      if (widget.assignment != null) {
        await apiService.updateAssignment(widget.assignment!.id, data);
      } else {
        await apiService.createAssignment(data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.assignment != null
                ? 'Assignment updated successfully'
                : 'Assignment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.assignment != null ? 'Edit Assignment' : 'New Assignment',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description *',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? 'Required' : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(_startDate),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _startDate = DateTime(
                                              picked.year,
                                              picked.month,
                                              picked.day,
                                              time.hour,
                                              time.minute,
                                            );
                                          });
                                        }
                                      }
                                    },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year} ${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _deadline,
                                        firstDate: _startDate,
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(_deadline),
                                        );
                                        if (time != null) {
                                          setState(() {
                                            _deadline = DateTime(
                                              picked.year,
                                              picked.month,
                                              picked.day,
                                              time.hour,
                                              time.minute,
                                            );
                                          });
                                        }
                                      }
                                    },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Deadline',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_deadline.day}/${_deadline.month}/${_deadline.year} ${_deadline.hour.toString().padLeft(2, '0')}:${_deadline.minute.toString().padLeft(2, '0')}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Allow Late Submission'),
                        value: _allowLateSubmission,
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _allowLateSubmission = v),
                      ),
                      if (_allowLateSubmission) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _isLoading
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _lateDeadline ?? _deadline.add(const Duration(days: 3)),
                                    firstDate: _deadline,
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(
                                          _lateDeadline ?? _deadline),
                                    );
                                    if (time != null) {
                                      setState(() {
                                        _lateDeadline = DateTime(
                                          picked.year,
                                          picked.month,
                                          picked.day,
                                          time.hour,
                                          time.minute,
                                        );
                                      });
                                    }
                                  }
                                },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Late Deadline',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _lateDeadline != null
                                  ? '${_lateDeadline!.day}/${_lateDeadline!.month}/${_lateDeadline!.year} ${_lateDeadline!.hour.toString().padLeft(2, '0')}:${_lateDeadline!.minute.toString().padLeft(2, '0')}'
                                  : 'Not set',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _maxAttempts,
                        decoration: const InputDecoration(
                          labelText: 'Max Attempts',
                          border: OutlineInputBorder(),
                        ),
                        items: [1, 2, 3, 5]
                            .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _maxAttempts = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxFileSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Max File Size (MB)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.trim().isEmpty ?? true) return 'Required';
                          if (double.tryParse(v!) == null) return 'Invalid number';
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _availableFormats.map((format) {
                          final selected = _selectedFormats.contains(format);
                          return FilterChip(
                            label: Text(format.toUpperCase()),
                            selected: selected,
                            onSelected: _isLoading
                                ? null
                                : (v) {
                                    setState(() {
                                      if (v) {
                                        _selectedFormats.add(format);
                                      } else {
                                        _selectedFormats.remove(format);
                                      }
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: Text('Add Attachments (${_attachments.length})'),
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._attachments.map((file) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(file.split('/').last),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() => _attachments.remove(file));
                                },
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}