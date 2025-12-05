import 'package:flutter/material.dart';
import '../../../core/models/quiz_model.dart';
import '../../../core/services/api_service.dart';

class QuizFormDialog extends StatefulWidget {
  final String courseId;
  final QuizModel? quiz;

  const QuizFormDialog({super.key, required this.courseId, this.quiz});

  @override
  State<QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<QuizFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _easyController;
  late TextEditingController _mediumController;
  late TextEditingController _hardController;
  late DateTime _openTime;
  late DateTime _closeTime;
  int _maxAttempts = 1;
  bool _isLoading = false;

  // ✅ Group Selection State
  String? _selectedGroupId;
  List<dynamic> _availableGroups = [];
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz?.title ?? '');
    _descriptionController = TextEditingController(text: widget.quiz?.description ?? '');
    _durationController = TextEditingController(text: widget.quiz?.durationMinutes.toString() ?? '30');
    _easyController = TextEditingController(text: widget.quiz?.easyQuestions.toString() ?? '5');
    _mediumController = TextEditingController(text: widget.quiz?.mediumQuestions.toString() ?? '3');
    _hardController = TextEditingController(text: widget.quiz?.hardQuestions.toString() ?? '2');
    _openTime = widget.quiz?.openTime ?? DateTime.now();
    _closeTime = widget.quiz?.closeTime ?? DateTime.now().add(const Duration(days: 7));
    _maxAttempts = widget.quiz?.maxAttempts ?? 1;

    // Initialize selected group if editing
    if (widget.quiz != null && widget.quiz!.groupIds.isNotEmpty) {
      _selectedGroupId = widget.quiz!.groupIds.first;
    }

    _loadGroups(); // ✅ Load groups
  }

  // ✅ Fetch Groups from API
  Future<void> _loadGroups() async {
    try {
      final apiService = ApiService();
      final groups = await apiService.getGroups(widget.courseId);
      if (mounted) {
        setState(() {
          _availableGroups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading groups: $e');
      if (mounted) setState(() => _isLoadingGroups = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _easyController.dispose();
    _mediumController.dispose();
    _hardController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final data = {
        'courseId': widget.courseId,
        // ✅ Send selected group ID (or empty list for All Students)
        'groupIds': _selectedGroupId != null ? [_selectedGroupId] : [],
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'openTime': _openTime.toIso8601String(),
        'closeTime': _closeTime.toIso8601String(),
        'durationMinutes': int.parse(_durationController.text),
        'maxAttempts': _maxAttempts,
        'easyQuestions': int.parse(_easyController.text),
        'mediumQuestions': int.parse(_mediumController.text),
        'hardQuestions': int.parse(_hardController.text),
        'questionIds': [], // Logic for specific IDs can be added later
      };

      if (widget.quiz != null) {
        await apiService.updateQuiz(widget.quiz!.id, data);
      } else {
        await apiService.createQuiz(data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quiz != null ? 'Quiz updated successfully' : 'Quiz created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800), // Increased height slightly
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.quiz != null ? 'Edit Quiz' : 'New Quiz',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                        maxLines: 2,
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // ✅ Group Selection Dropdown
                      _isLoadingGroups
                          ? const Center(child: LinearProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _selectedGroupId,
                              decoration: const InputDecoration(
                                labelText: 'Assign to Group',
                                border: OutlineInputBorder(),
                                helperText: 'Leave empty for All Students',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Students (Default)'),
                                ),
                                ..._availableGroups.map((group) {
                                  return DropdownMenuItem<String>(
                                    value: group['id'],
                                    child: Text(group['name']),
                                  );
                                }),
                              ],
                              onChanged: _isLoading ? null : (val) => setState(() => _selectedGroupId = val),
                            ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _isLoading ? null : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _openTime,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  if (context.mounted) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(_openTime),
                                    );
                                    if (time != null) {
                                      setState(() => _openTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                                    }
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Open Time', border: OutlineInputBorder()),
                                child: Text('${_openTime.day}/${_openTime.month}/${_openTime.year} ${_openTime.hour.toString().padLeft(2, '0')}:${_openTime.minute.toString().padLeft(2, '0')}'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: _isLoading ? null : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _closeTime,
                                  firstDate: _openTime,
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  if (context.mounted) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(_closeTime),
                                    );
                                    if (time != null) {
                                      setState(() => _closeTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                                    }
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Close Time', border: OutlineInputBorder()),
                                child: Text('${_closeTime.day}/${_closeTime.month}/${_closeTime.year} ${_closeTime.hour.toString().padLeft(2, '0')}:${_closeTime.minute.toString().padLeft(2, '0')}'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(labelText: 'Duration (min)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                              enabled: !_isLoading,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _maxAttempts,
                              decoration: const InputDecoration(labelText: 'Max Attempts', border: OutlineInputBorder()),
                              items: [1, 2, 3, 5].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                              onChanged: _isLoading ? null : (v) => setState(() => _maxAttempts = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Question Structure (Auto-generated)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _easyController,
                              decoration: const InputDecoration(labelText: 'Easy', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                              enabled: !_isLoading,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _mediumController,
                              decoration: const InputDecoration(labelText: 'Medium', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                              enabled: !_isLoading,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _hardController,
                              decoration: const InputDecoration(labelText: 'Hard', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
                              enabled: !_isLoading,
                            ),
                          ),
                        ],
                      ),
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
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
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