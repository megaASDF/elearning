import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/material_model.dart';
import '../../../core/providers/material_provider.dart';
import '../widgets/material_form_dialog.dart';

class MaterialsScreen extends StatefulWidget {
  final String courseId;
  final bool isInstructor;

  const MaterialsScreen({
    super.key,
    required this.courseId,
    required this.isInstructor,
  });

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaterials();
    });
  }

  Future<void> _loadMaterials() async {
    final provider = context. read<MaterialProvider>();
    await provider.loadMaterials(widget.courseId);
  }

  Future<void> _showMaterialDialog({MaterialModel? material}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MaterialFormDialog(
        courseId: widget.courseId,
        material: material,
      ),
    );

    if (result == true) {
      await _loadMaterials();
    }
  }

  Future<void> _deleteMaterial(MaterialModel material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material. title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context. read<MaterialProvider>().deleteMaterial(material.id, widget. courseId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getIconForMaterial(MaterialModel material) {
    if (material.fileUrls.isNotEmpty) {
      final url = material.fileUrls.first.toLowerCase();
      if (url.endsWith('.pdf')) return Icons.picture_as_pdf;
      if (url.endsWith('.mp4') || url. endsWith('.mov')) return Icons. video_library;
      if (url.endsWith('.doc') || url.endsWith('.docx')) return Icons.description;
      if (url.endsWith('.jpg') || url.endsWith('.png')) return Icons.image;
      return Icons.insert_drive_file;
    } else if (material. links.isNotEmpty) {
      return Icons.link;
    }
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials'),
      ),
      floatingActionButton: widget. isInstructor
          ?  FloatingActionButton. extended(
              onPressed: () => _showMaterialDialog(),
              icon: const Icon(Icons. add),
              label: const Text('Add Material'),
            )
          : null,
      body: Consumer<MaterialProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.materials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors. grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No materials yet',
                    style: TextStyle(fontSize: 18, color: Colors. grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadMaterials,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.materials.length,
              itemBuilder: (context, index) {
                final material = provider. materials[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        _getIconForMaterial(material),
                        color: Colors. white,
                      ),
                    ),
                    title: Text(material.title),
                    subtitle: Text(material.description),
                    trailing: widget.isInstructor
                        ? PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showMaterialDialog(material: material);
                              } else if (value == 'delete') {
                                _deleteMaterial(material);
                              }
                            },
                          )
                        : null,
                    onTap: () {
                      // Handle material view/download
                      provider. incrementViewCount(material.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}