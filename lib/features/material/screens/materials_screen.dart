import 'package:flutter/material.dart';
import '../../../core/models/material_model.dart';
import '../../../core/services/api_service.dart';
import '../widgets/material_form_dialog.dart';

class MaterialsScreen extends StatefulWidget {
  final String courseId;
  final bool isInstructor;

  const MaterialsScreen({super.key, required this.courseId, required this.isInstructor});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  List<MaterialModel> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getMaterials(widget.courseId);
      if (mounted) {
        setState(() {
          _materials = data.map((json) => MaterialModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showMaterialDialog({MaterialModel? material}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MaterialFormDialog(courseId: widget.courseId, material: material),
    );
    if (result == true) await _loadMaterials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Materials')),
      floatingActionButton: widget.isInstructor
          ? FloatingActionButton.extended(
              onPressed: () => _showMaterialDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Material'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No materials yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadMaterials,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _materials.length,
                    itemBuilder: (context, index) {
                      final material = _materials[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.insert_drive_file)),
                          title: Text(material.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(material.description),
                              const SizedBox(height: 4),
                              Text('${material.fileUrls.length} file(s) • ${material.viewCount} views', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}