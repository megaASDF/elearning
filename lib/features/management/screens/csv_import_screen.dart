import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/services/csv_import_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/student_provider.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  String _selectedType = 'students';
  List<Map<String, dynamic>> _previewData = [];
  List<String> _importStatus = [];
  bool _isLoading = false;
  bool _showPreview = false;
  int _existingCount = 0;
  int _newCount = 0;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isLoading = true);
        
        final csvContent = String.fromCharCodes(result. files.single.bytes!);
        final data = await CsvImportService. parseCsv(csvContent);
        
        await _validateData(data);
        
        setState(() {
          _previewData = data;
          _showPreview = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _validateData(List<Map<String, dynamic>> data) async {
    _existingCount = 0;
    _newCount = 0;
    _importStatus = [];

    if (_selectedType == 'students') {
      final apiService = ApiService();
      final existingStudents = await apiService. getAllStudents();
      final existingEmails = existingStudents.map((s) => s['email']).toSet();

      for (var row in data) {
        final email = row['email'] ??  '';
        if (existingEmails.contains(email)) {
          _existingCount++;
          _importStatus. add('EXISTS');
        } else {
          _newCount++;
          _importStatus.add('NEW');
        }
      }
    } else {
      // For other types, assume all are new for now
      _newCount = data.length;
      _importStatus = List.filled(data.length, 'NEW');
    }
  }

  Future<void> _importData() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < _previewData.length; i++) {
        if (_importStatus[i] == 'EXISTS') continue; // Skip existing

        try {
          if (_selectedType == 'students') {
            await apiService.createStudent({
              'username': _previewData[i]['username'] ?? '',
              'displayName': _previewData[i]['displayName'] ?? '',
              'email': _previewData[i]['email'] ?? '',
              'studentId': _previewData[i]['studentId'] ?? '',
              'department': _previewData[i]['department'] ?? '',
            });
          } else if (_selectedType == 'semesters') {
            await apiService.createSemester({
              'code': _previewData[i]['code'] ?? '',
              'name': _previewData[i]['name'] ?? '',
              'startDate': _previewData[i]['startDate'] ??  '',
              'endDate': _previewData[i]['endDate'] ?? '',
              'isCurrent': _previewData[i]['isCurrent'] == 'true',
            });
          }
          // Add more types as needed

          successCount++;
          setState(() {
            _importStatus[i] = 'SUCCESS';
          });
        } catch (e) {
          failCount++;
          setState(() {
            _importStatus[i] = 'FAILED';
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        // Refresh data
        if (_selectedType == 'students') {
          await context.read<StudentProvider>().loadAllStudents();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed: $successCount success, $failCount failed, $_existingCount skipped',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadSample() {
    String sample = '';
    String filename = '';

    switch (_selectedType) {
      case 'students':
        sample = CsvImportService.generateSampleStudentsCsv();
        filename = 'sample_students.csv';
        break;
      case 'semesters':
        sample = CsvImportService.generateSampleSemestersCsv();
        filename = 'sample_semesters.csv';
        break;
      case 'courses':
        sample = CsvImportService.generateSampleCoursesCsv();
        filename = 'sample_courses.csv';
        break;
      case 'groups':
        sample = CsvImportService.generateSampleGroupsCsv();
        filename = 'sample_groups. csv';
        break;
    }

    Clipboard.setData(ClipboardData(text: sample));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample CSV copied to clipboard!  Save it as $filename'),
        backgroundColor: Colors. green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV Bulk Import'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selector
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Import Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'students', child: Text('Students')),
                DropdownMenuItem(value: 'semesters', child: Text('Semesters')),
                DropdownMenuItem(value: 'courses', child: Text('Courses')),
                DropdownMenuItem(value: 'groups', child: Text('Groups')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _showPreview = false;
                  _previewData = [];
                });
              },
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton. icon(
                    onPressed: _downloadSample,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Sample'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton. icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select CSV File'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Preview Section
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_showPreview) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preview (${_previewData.length} rows)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Chip(
                    label: Text('$_newCount new, $_existingCount existing'),
                    backgroundColor: Colors.blue. shade100,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: _previewData.length,
                    itemBuilder: (context, index) {
                      final row = _previewData[index];
                      final status = _importStatus[index];
                      
                      Color statusColor = Colors.green;
                      IconData statusIcon = Icons.add_circle;
                      
                      if (status == 'EXISTS') {
                        statusColor = Colors.orange;
                        statusIcon = Icons.info;
                      } else if (status == 'FAILED') {
                        statusColor = Colors.red;
                        statusIcon = Icons.error;
                      } else if (status == 'SUCCESS') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                      }

                      return ListTile(
                        leading: Icon(statusIcon, color: statusColor),
                        title: Text(
                          row. values.take(3).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          status == 'EXISTS' 
                              ? 'Already exists - will be skipped'
                              : status == 'NEW'
                                  ? 'Will be added'
                                  : status,
                          style: TextStyle(color: statusColor),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton. icon(
                  onPressed: _isLoading || _newCount == 0 ? null : _importData,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('Import $_newCount New Records'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_upload, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Select a CSV file to import',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download a sample CSV to see the required format',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}