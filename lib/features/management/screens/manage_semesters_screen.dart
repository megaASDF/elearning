import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/semester_provider.dart';

class ManageSemestersScreen extends StatefulWidget {
  const ManageSemestersScreen({super.key});

  @override
  State<ManageSemestersScreen> createState() => _ManageSemestersScreenState();
}

class _ManageSemestersScreenState extends State<ManageSemestersScreen> {
  List<dynamic> _semesters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().getSemesters();
      if (mounted) {
        setState(() {
          _semesters = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addSemesterDialog() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Semester'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g. HK2-24)')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.isNotEmpty) {
                await ApiService().createSemester({
                  'code': codeCtrl.text, 
                  'name': nameCtrl.text,
                  'isCurrent': false // Default
                });
                
                if (mounted) {
                  // Refresh global provider and local list
                  await context.read<SemesterProvider>().loadSemesters();
                  Navigator.pop(context);
                  _loadSemesters(); 
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Semesters')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSemesterDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _semesters.length,
            itemBuilder: (context, index) {
              final s = _semesters[index];
              return ListTile(
                title: Text(s['name']),
                subtitle: Text(s['code']),
                trailing: s['isCurrent'] == true ? const Chip(label: Text('Current')) : null,
              );
            },
          ),
    );
  }
}