import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/announcement_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/announcement_provider.dart';
import '../widgets/announcement_card.dart';
import '../../announcement/widgets/announcement_form_dialog.dart';

class StreamTab extends StatefulWidget {
  final String courseId;
  final bool isInstructor;

  const StreamTab({
    super. key,
    required this.courseId,
    required this.isInstructor,
  });

  @override
  State<StreamTab> createState() => _StreamTabState();
}

class _StreamTabState extends State<StreamTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnnouncements();
    });
  }

  Future<void> _loadAnnouncements() async {
    final provider = context.read<AnnouncementProvider>();
    await provider.loadAnnouncements(widget.courseId);
  }

  Future<void> _showAnnouncementDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnnouncementFormDialog(
        courseId: widget.courseId,
      ),
    );

    if (result == true) {
      await _loadAnnouncements();
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AnnouncementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.announcements. isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment. center,
                children: [
                  Icon(Icons.announcement_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (widget.isInstructor) ...[
                    const SizedBox(height: 16),
                    ElevatedButton. icon(
                      onPressed: _showAnnouncementDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Announcement'),
                    ),
                  ],
                ],
              ),
            );
          }

return RefreshIndicator(
            onRefresh: _loadAnnouncements,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.announcements.length,
              itemBuilder: (context, index) {
                return AnnouncementCard(
                  announcement: provider.announcements[index],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: widget.isInstructor
          ? FloatingActionButton. extended(
              onPressed: _showAnnouncementDialog,
              icon: const Icon(Icons. add),
              label: const Text('Announcement'),
            )
          : null,
    );
  }
}