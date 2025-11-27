import 'package:flutter/material.dart';
import '../../../core/models/material_model.dart';
import '../../../core/services/api_service.dart';

class MaterialFormDialog extends StatefulWidget {
  final String courseId;
  final MaterialModel? material;

  const MaterialFormDialog({super.key, required this.courseId, this.material});

  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.material?.title ?? '');
    _descriptionController = TextEditingController(text: widget.material?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final data = {
        'courseId': widget.courseId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fileUrls': [],
        'links': [],
        'authorName': 'Administrator',
      };

      if (widget.material != null) {
        await apiService.updateMaterial(widget.material!.id, data);
      } else {
        await apiService.createMaterial(data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.material != null ? 'Material updated' : 'Material created'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.material != null ? 'Edit Material' : 'New Material', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
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
                maxLines: 3,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
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