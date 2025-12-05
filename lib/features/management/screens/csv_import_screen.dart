import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Services
import '../../../core/services/csv_import_service.dart';
import '../../../core/services/api_service.dart';

// Providers
import '../../../core/providers/student_provider.dart';
import '../../../core/providers/course_provider.dart';
import '../../../core/providers/semester_provider.dart';
import '../../../core/providers/group_provider.dart'; // Added for completeness

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final ApiService _apiService = ApiService();
  
  String _selectedType = 'students';
  String? _selectedSemesterId; 
  List<dynamic> _availableSemesters = []; 
  
  List<Map<String, dynamic>> _previewData = [];
  List<String> _importStatus = [];
  bool _isLoading = false;
  bool _showPreview = false;
  int _existingCount = 0;
  int _newCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    try {
      final semesters = await _apiService.getSemesters();
      if (mounted) {
        setState(() {
          _availableSemesters = semesters;
          try {
            // Try to set current semester as default
            final current = semesters.firstWhere((s) => s['isCurrent'] == true);
            _selectedSemesterId = current['id'];
          } catch (_) {
            // Fallback to first available
            if (semesters.isNotEmpty) _selectedSemesterId = semesters.first['id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading semesters: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Ensure bytes are loaded
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() => _isLoading = true);
        
        // Decode bytes to string
        final csvContent = String.fromCharCodes(result.files.single.bytes!);
        final data = await CsvImportService.parseCsv(csvContent);
        
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
      final existingStudents = await _apiService.getAllStudents();
      final existingEmails = existingStudents.map((s) => s['email']).toSet();

      for (var row in data) {
        final email = row['email'] ?? '';
        if (existingEmails.contains(email)) {
          _existingCount++;
          _importStatus.add('EXISTS');
        } else {
          _newCount++;
          _importStatus.add('NEW');
        }
      }
    } 
    else if (_selectedType == 'semesters') {
      final existingSemesters = await _apiService.getSemesters();
      final existingCodes = existingSemesters.map((s) => s['code']).toSet();

      for (var row in data) {
        if (existingCodes.contains(row['code'])) {
          _existingCount++;
          _importStatus.add('EXISTS');
        } else {
          _newCount++;
          _importStatus.add('NEW');
        }
      }
    }
    else if (_selectedType == 'courses') {
      final allSemesters = await _apiService.getSemesters();
      Map<String, Set<String>> semesterCourseCodes = {};

      for (var row in data) {
        String targetSemesterId = _selectedSemesterId ?? '';

        // Check if CSV specifies a semester
        if (row.containsKey('semesterCode') && 
            row['semesterCode'].toString().isNotEmpty) {
          final semCode = row['semesterCode'];
          final foundSem = allSemesters
              .where((s) => s['code'] == semCode)
              .firstOrNull;
          
          if (foundSem != null) {
            targetSemesterId = foundSem['id'];
          }
        }

        if (targetSemesterId.isEmpty) {
          _newCount++; 
          _importStatus.add('NEW'); 
          continue;
        }

        // Cache course codes for this semester if not already cached
        if (!semesterCourseCodes.containsKey(targetSemesterId)) {
          final courses = await _apiService.getCourses(targetSemesterId);
          semesterCourseCodes[targetSemesterId] = 
              courses.map((c) => c['code'].toString()).toSet();
        }

        final code = row['code'] ?? '';
        if (semesterCourseCodes[targetSemesterId]!.contains(code)) {
          _existingCount++;
          _importStatus.add('EXISTS');
        } else {
          _newCount++;
          _importStatus.add('NEW');
        }
      }
    }
    else {
      // Default for Groups or others without specific pre-validation logic
      _newCount = data.length;
      _importStatus = List.filled(data.length, 'NEW');
    }
  }

  Future<void> _importData() async {
    if (_selectedType == 'courses' && _selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Target Semester first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int successCount = 0;
      int failCount = 0;

      final allSemesters = await _apiService.getSemesters();
      List<dynamic> allCourses = [];
      
      // Pre-fetch courses if we are importing groups
      if (_selectedType == 'groups') {
        for (var sem in allSemesters) {
          final courses = await _apiService.getCourses(sem['id']);
          allCourses.addAll(courses);
        }
      }

      for (int i = 0; i < _previewData.length; i++) {
        if (_importStatus[i] == 'EXISTS') continue; 

        try {
          if (_selectedType == 'students') {
            await _apiService.createStudent({
              'username': _previewData[i]['username'] ?? '',
              'displayName': _previewData[i]['displayName'] ?? '',
              'email': _previewData[i]['email'] ?? '',
              'studentId': _previewData[i]['studentId'] ?? '',
              'department': _previewData[i]['department'] ?? '',
            });
          } 
          else if (_selectedType == 'semesters') {
            final start = DateTime.tryParse(_previewData[i]['startDate'] ?? '') ?? DateTime.now();
            final end = DateTime.tryParse(_previewData[i]['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 120));

            await _apiService.createSemester({
              'code': _previewData[i]['code'] ?? '',
              'name': _previewData[i]['name'] ?? '',
              'startDate': Timestamp.fromDate(start),
              'endDate': Timestamp.fromDate(end),
              'isCurrent': _previewData[i]['isCurrent'].toString().toLowerCase() == 'true',
            });
          } 
          else if (_selectedType == 'courses') {
            String targetSemesterId = _selectedSemesterId!;

            if (_previewData[i].containsKey('semesterCode') && 
                _previewData[i]['semesterCode'].toString().isNotEmpty) {
              final semCode = _previewData[i]['semesterCode'];
              
              final foundSem = allSemesters
                  .where((s) => s['code'] == semCode)
                  .firstOrNull;
              
              if (foundSem != null) {
                targetSemesterId = foundSem['id'];
              } else {
                throw Exception('Semester code "$semCode" not found');
              }
            }

            await _apiService.createCourse({
              'semesterId': targetSemesterId,
              'code': _previewData[i]['code'] ?? '',
              'name': _previewData[i]['name'] ?? '',
              'description': _previewData[i]['description'] ?? '',
              'instructorName': _previewData[i]['instructorName'] ?? 'Administrator',
              'numberOfSessions': int.tryParse(_previewData[i]['numberOfSessions'] ?? '15') ?? 15,
            });
          }
          else if (_selectedType == 'groups') {
            final courseCode = _previewData[i]['courseCode'];
            
            final course = allCourses
                .where((c) => c['code'] == courseCode)
                .firstOrNull;

            if (course != null) {
              await _apiService.createGroup({
                'courseId': course['id'],
                'name': _previewData[i]['name'] ?? 'Group',
                'maxStudents': int.tryParse(_previewData[i]['maxStudents'] ?? '30') ?? 30,
              });
            } else {
              throw Exception('Course code "$courseCode" not found');
            }
          }

          successCount++;
          setState(() {
            _importStatus[i] = 'SUCCESS';
          });
        } catch (e) {
          failCount++;
          debugPrint('Import row failed: $e');
          setState(() {
            _importStatus[i] = 'FAILED';
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        // REFRESH PROVIDERS BASED ON IMPORT TYPE
        if (_selectedType == 'students') {
          await context.read<StudentProvider>().loadAllStudents();
        } else if (_selectedType == 'semesters') {
          await context.read<SemesterProvider>().loadSemesters();
        } else if (_selectedType == 'courses' || _selectedType == 'groups') {
          // For courses and groups, refresh current semester data if active
          final semesterProvider = context.read<SemesterProvider>();
          if (semesterProvider.currentSemester != null) {
            await context.read<CourseProvider>().loadCourses(semesterProvider.currentSemester!.id);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import completed: $successCount success, $failCount failed',
            ),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Critical Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
        // Updated sample to include optional semesterCode
        sample = '''code,name,description,instructorName,numberOfSessions,semesterCode
INT3123,Mobile App Dev,Flutter course,Dr. Manh,15,HK1-2025
INT3401,AI Basics,Intro to AI,Prof. AI,15,''';
        filename = 'sample_courses.csv';
        break;
      case 'groups':
        sample = CsvImportService.generateSampleGroupsCsv();
        filename = 'sample_groups.csv';
        break;
    }

    Clipboard.setData(ClipboardData(text: sample));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample CSV copied to clipboard! Save it as $filename'),
        backgroundColor: Colors.green,
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
                  _importStatus = [];
                });
              },
            ),
            const SizedBox(height: 16),

            if (_selectedType == 'courses') ...[
              DropdownButtonFormField<String>(
                value: _selectedSemesterId,
                decoration: const InputDecoration(
                  labelText: 'Target Semester (Default)',
                  border: OutlineInputBorder(),
                  helperText: 'Used if "semesterCode" is missing in CSV',
                ),
                items: _availableSemesters.map((s) {
                  return DropdownMenuItem<String>(
                    value: s['id'],
                    child: Text('${s['code']} - ${s['name']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSemesterId = value);
                },
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _downloadSample,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Sample CSV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select CSV File'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
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
                    backgroundColor: Colors.blue.shade100,
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
                      // Use safe access for status in case index is out of bounds
                      final status = index < _importStatus.length ? _importStatus[index] : 'UNKNOWN';
                      
                      Color statusColor = Colors.grey;
                      IconData statusIcon = Icons.help;
                      
                      if (status == 'EXISTS') {
                        statusColor = Colors.orange;
                        statusIcon = Icons.info;
                      } else if (status == 'FAILED') {
                        statusColor = Colors.red;
                        statusIcon = Icons.error;
                      } else if (status == 'SUCCESS') {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                      } else if (status == 'NEW') {
                        statusColor = Colors.blue;
                        statusIcon = Icons.new_releases;
                      }

                      return ListTile(
                        leading: Icon(statusIcon, color: statusColor),
                        title: Text(
                          row.values.take(2).join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          status == 'EXISTS' 
                              ? 'Already exists - will be skipped'
                              : status == 'NEW'
                                  ? 'Ready to import'
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
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _newCount == 0 ? null : _importData,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('Import $_newCount New Records'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
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
                        'Select a CSV file to import $_selectedType',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use "Copy Sample CSV" to get the correct format',
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