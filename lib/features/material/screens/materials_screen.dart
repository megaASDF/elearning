import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    super. initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaterials();
    });
  }

  Future<void> _loadMaterials() async {
    final provider = context.read<MaterialProvider>();
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
        content: Text('Are you sure you want to delete "${material.title}"?'),
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
        await context.read<MaterialProvider>().deleteMaterial(material.id, widget.courseId);
        if (mounted) {
          ScaffoldMessenger.of(context). showSnackBar(
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

void _showMaterialDetailsDialog(MaterialModel material, MaterialProvider provider) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: SelectableText(
        material.title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (material.description. isNotEmpty) ...[
              SelectableText(
                material. description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
            ],
            if (material.fileUrls.isNotEmpty) ...[
              const SelectableText(
                'Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...material.fileUrls.map((url) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: Colors. blue),
                  title: SelectableText(
                    url,
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
            if (material.links. isNotEmpty) ...[
              const SelectableText(
                'Links:',
                style: TextStyle(fontWeight: FontWeight. bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...material.links.map((link) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.link, color: Colors.green),
                  title: SelectableText(
                    link,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard! '),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors. grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: SelectableText(
                    'Author: ${material.authorName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.visibility, size: 16, color: Colors. grey[600]),
                const SizedBox(width: 4),
                SelectableText(
                  'Views: ${material.viewCount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.download, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                SelectableText(
                  'Downloads: ${material.downloadCount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  
  // Increment view count
  provider.incrementViewCount(material.id);
}

  IconData _getIconForMaterial(MaterialModel material) {
    if (material.fileUrls.isNotEmpty) {
      final url = material.fileUrls. first. toLowerCase();
      if (url.endsWith('.pdf')) return Icons.picture_as_pdf;
      if (url.endsWith('.mp4') || url.endsWith('.mov')) return Icons.video_library;
      if (url.endsWith('. doc') || url.endsWith('. docx')) return Icons.description;
      if (url.endsWith('.jpg') || url.endsWith('.png')) return Icons.image;
      return Icons.insert_drive_file;
    } else if (material.links.isNotEmpty) {
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
      floatingActionButton: widget.isInstructor
          ?  FloatingActionButton. extended(
              onPressed: () => _showMaterialDialog(),
              icon: const Icon(Icons.add),
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
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No materials yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
                final material = provider.materials[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(
                        _getIconForMaterial(material),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(material.title),
                    subtitle: Text(
                      material.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: widget.isInstructor
                        ? PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons. edit, size: 20),
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
                    onTap: () => _showMaterialDetailsDialog(material, provider),
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