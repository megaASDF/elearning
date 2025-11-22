import 'package:flutter/material.dart';
import '../../../core/models/semester_model.dart';
import '../../../core/services/api_service.dart';

class SemesterFormDialog extends StatefulWidget {
  final SemesterModel? semester;

  const SemesterFormDialog({super.key, this.semester});

  @override
  State<SemesterFormDialog> createState() => _SemesterFormDialogState();
}

class _SemesterFormDialogState extends State<SemesterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.semester?.code ?? '');
    _nameController = TextEditingController(text: widget.semester?.name ?? '');
    _startDate = widget.semester?.startDate ?? DateTime.now();
    _endDate = widget.semester?.endDate ?? DateTime.now().add(const Duration(days: 120));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final data = {
        'code': _codeController.text,
        'name': _nameController.text,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
      };

      if (widget.semester != null) {
        await apiService.updateSemester(widget.semester!.id, data);
      } else {
        await apiService.createSemester(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.semester != null
                ? 'Semester updated successfully'
                : 'Semester created successfully'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.semester != null ? 'Edit Semester' : 'New Semester'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Semester Code',
                  hintText: 'e.g., HK1-2024',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter semester code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Semester Name',
                  hintText: 'e.g., Semester 1, 2024-2025',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter semester name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.semester != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}