import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _fixDuplicateCurrentSemesters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('semesters')
        .where('isCurrent', isEqualTo: true)
        .get();

    if (snapshot.docs.length > 1) {
      final docs = snapshot.docs;
      docs.sort((a, b) => (b['startDate'] as Timestamp).compareTo(a['startDate'] as Timestamp));
      
      final batch = FirebaseFirestore.instance.batch();
      for (var i = 1; i < docs.length; i++) {
        batch.update(docs[i].reference, {'isCurrent': false});
      }
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Data fixed! Duplicates removed.')),
        );
        context.read<SemesterProvider>().loadSemesters();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data is already clean.')),
        );
      }
    }
  }

  // ✅ ADDED: Edit Dialog
  Future<void> _showSemesterDialog({SemesterModel? semester}) async {
    final isEditing = semester != null;
    final codeCtrl = TextEditingController(text: semester?.code ?? '');
    final nameCtrl = TextEditingController(text: semester?.name ?? '');
    DateTime startDate = semester?.startDate ?? DateTime.now();
    DateTime endDate = semester?.endDate ?? DateTime.now().add(const Duration(days: 120));
    bool isCurrent = semester?.isCurrent ?? false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Semester' : 'New Semester'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
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
                    if (date != null) setState(() => startDate = date);
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
                    if (date != null) setState(() => endDate = date);
                  },
                ),
                if (isEditing) // Only show checkbox if editing (optional)
                  SwitchListTile(
                    title: const Text('Set as Current Semester'),
                    value: isCurrent,
                    onChanged: (val) => setState(() => isCurrent = val),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          if (isEditing)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete Semester?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                
                if (confirm == true && mounted) {
                  await context.read<SemesterProvider>().deleteSemester(semester!.id);
                  Navigator.pop(ctx);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                final newSemester = SemesterModel(
                  id: semester?.id ?? '',
                  code: codeCtrl.text,
                  name: nameCtrl.text,
                  startDate: startDate,
                  endDate: endDate,
                  isCurrent: isCurrent,
                );

                if (isEditing) {
                  await context.read<SemesterProvider>().updateSemester(semester!.id, newSemester);
                } else {
                  await context.read<SemesterProvider>().createSemester(newSemester);
                }
                
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEditing ? 'Updated successfully' : 'Created successfully')),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
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
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Fix Duplicate "Current" Semesters',
            onPressed: _fixDuplicateCurrentSemesters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSemesterDialog(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<SemesterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.semesters.isEmpty) {
            return const Center(child: Text('No semesters yet. Create one!'));
          }

          return ListView.separated(
            itemCount: provider.semesters.length,
            separatorBuilder: (c, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final semester = provider.semesters[index];
              final isPast = DateTime.now().isAfter(semester.endDate);

              return ListTile(
                title: Text(semester.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${semester.code} • Ends: ${semester.endDate.day}/${semester.endDate.month}/${semester.endDate.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPast)
                      const Chip(
                        label: Text('Expired', style: TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: Colors.grey,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (semester.isCurrent) 
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: Text('Current', style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: Colors.green,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 20, color: Colors.grey),
                  ],
                ),
                onTap: () => _showSemesterDialog(semester: semester),
              );
            },
          );
        },
      ),
    );
  }
}