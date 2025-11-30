import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class SubmissionForm extends StatefulWidget {
  final String assignmentId;
  final VoidCallback onSuccess;

  const SubmissionForm({
    super.key,
    required this.assignmentId,
    required this.onSuccess,
  });

  @override
  State<SubmissionForm> createState() => _SubmissionFormState();
}

class _SubmissionFormState extends State<SubmissionForm> {
  List<String> _files = [];
  bool _isLoading = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _files.addAll(result.paths.whereType<String>());
      });
    }
  }

  Future<void> _submit() async {
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please attach a file')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user!;
      await ApiService().submitAssignment(widget.assignmentId, {
        'studentId': user.id,
        'studentName': user.displayName,
        'files': _files,
        'submittedAt': DateTime.now().toIso8601String(),
      });
      
      widget.onSuccess();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turned in successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_files.isEmpty)
              const Text('No files attached', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ..._files.map((f) => ListTile(
              leading: const Icon(Icons.file_present),
              title: Text(f.split('/').last), // Simple file name
              trailing: IconButton(
                icon: const Icon(Icons.close), 
                onPressed: () => setState(() => _files.remove(f))
              ),
              contentPadding: EdgeInsets.zero,
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add File'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || _files.isEmpty ? null : _submit,
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Text('Turn In'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}