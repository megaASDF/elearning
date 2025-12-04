import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ ADDED THIS IMPORT
import '../../../core/providers/semester_provider.dart';
import '../../../core/models/semester_model.dart';

class ManageSemestersScreen extends StatefulWidget {
  const ManageSemestersScreen({super.key});

  @override
  State<ManageSemestersScreen> createState() => _ManageSemestersScreenState();
}

class _ManageSemestersScreenState extends State<ManageSemestersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SemesterProvider>().loadSemesters());
  }

  // ✅ The fix function
  Future<void> _fixDuplicateCurrentSemesters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('semesters')
        .where('isCurrent', isEqualTo: true)
        .get();

    if (snapshot.docs.length > 1) {
      // Sort by date so we keep the newest one
      final docs = snapshot.docs;
      docs.sort((a, b) => (b['startDate'] as Timestamp).compareTo(a['startDate'] as Timestamp));
      
      // Keep the first one (newest), uncheck the rest
      final batch = FirebaseFirestore.instance.batch();
      for (var i = 1; i < docs.length; i++) {
        batch.update(docs[i].reference, {'isCurrent': false});
      }
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data fixed! Duplicates removed.')),
        );
        context.read<SemesterProvider>().loadSemesters(); // Refresh UI
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data is already clean (No duplicates found).')),
        );
      }
    }
  }

  Future<void> _addSemesterDialog() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 120));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Semester'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code (e.g. HK2-24)'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text('${startDate.day}/${startDate.month}/${startDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => startDate = date);
                  }
                },
              ),
              ListTile(
                title: const Text('End Date'),
                subtitle: Text('${endDate.day}/${endDate.month}/${endDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => endDate = date);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                final semester = SemesterModel(
                  id: '',
                  code: codeCtrl.text,
                  name: nameCtrl.text,
                  startDate: startDate,
                  endDate: endDate,
                  isCurrent: false, // Default to false to be safe
                );

                await context.read<SemesterProvider>().createSemester(semester);
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semester created successfully')),
                  );
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
      appBar: AppBar(
        title: const Text('Manage Semesters'),
        actions: [
          // ✅ ADDED: Button to run the fix manually
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Fix Duplicate "Current" Semesters',
            onPressed: _fixDuplicateCurrentSemesters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSemesterDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<SemesterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.semesters.isEmpty) {
            return const Center(
              child: Text('No semesters yet. Create one!'),
            );
          }

          return ListView.builder(
            itemCount: provider.semesters.length,
            itemBuilder: (context, index) {
              final semester = provider.semesters[index];
              return ListTile(
                title: Text(semester.name),
                subtitle: Text(semester.code),
                trailing: semester.isCurrent 
                  ? const Chip(label: Text('Current'), backgroundColor: Colors.greenAccent) 
                  : null,
                onTap: () {
                  // Optional: Add edit functionality or "Set as Current" here
                },
              );
            },
          );
        },
      ),
    );
  }
}