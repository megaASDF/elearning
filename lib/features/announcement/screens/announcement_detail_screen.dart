import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/announcement_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/tracking_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AnnouncementModel? _announcement;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      
      
      // Get announcement details
      final announcementDoc = await _firestore
          .collection('announcements')
          .doc(widget.announcementId)
          .get();
      
      if (announcementDoc.exists) {
        final data = announcementDoc.data()!;
        _announcement = AnnouncementModel.fromJson({
          'id': announcementDoc.id,
          ... data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate(). toIso8601String() ?? 
              DateTime.now().toIso8601String(),
        });
      }

      // Get comments
      final commentsSnapshot = await _firestore
          .collection('announcementComments')
          . where('announcementId', isEqualTo: widget.announcementId)
          .orderBy('createdAt', descending: false)
          .get();

      _comments = commentsSnapshot.docs. map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      // Track view
      final authProvider = context.read<AuthProvider>();
      final trackingService = TrackingService();
      await trackingService.trackAnnouncementView(
        announcementId: widget.announcementId,
        userId: authProvider. user!.id,
        userName: authProvider.user!.displayName,
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      await _firestore.collection('announcementComments').add({
        'announcementId': widget. announcementId,
        'userId': authProvider.user!. id,
        'userName': authProvider.user!.displayName,
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment comment count
      await _firestore
          .collection('announcements')
          .doc(widget.announcementId)
          .update({'commentCount': FieldValue. increment(1)});

      _commentController.clear();
      await _loadData();
      
      setState(() => _isSubmitting = false);
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestore. collection('announcementComments'). doc(commentId).delete();
      
      await _firestore
          .collection('announcements')
          .doc(widget. announcementId)
          . update({'commentCount': FieldValue.increment(-1)});

      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          const SnackBar(content: Text('Comment deleted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors. red),
        );
      }
    }
  }

  Future<void> _showTrackingDialog() async {
    final trackingService = TrackingService();
    final viewers = await trackingService.getAnnouncementViewers(widget. announcementId);
    final downloaders = await trackingService. getAnnouncementDownloaders(widget.announcementId);

    if (! mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Announcement Tracking'),
        content: SizedBox(
          width: 500,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Viewers'),
                    Tab(text: 'Downloads'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      // Viewers
                      viewers.isEmpty
                          ? const Center(child: Text('No views yet'))
                          : ListView. builder(
                              itemCount: viewers.length,
                              itemBuilder: (context, index) {
                                final viewer = viewers[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(viewer['userName'][0]. toUpperCase()),
                                  ),
                                  title: Text(viewer['userName']),
                                  subtitle: Text(
                                    'Viewed: ${viewer['viewedAt']. day}/${viewer['viewedAt']. month}/${viewer['viewedAt'].year}',
                                  ),
                                );
                              },
                            ),
                      // Downloaders
                      downloaders. isEmpty
                          ? const Center(child: Text('No downloads yet'))
                          : ListView. builder(
                              itemCount: downloaders.length,
                              itemBuilder: (context, index) {
                                final download = downloaders[index];
                                return ListTile(
                                  leading: const Icon(Icons.download),
                                  title: Text(download['userName']),
                                  subtitle: Text(
                                    '${download['fileName']}\n${download['downloadedAt'].day}/${download['downloadedAt']. month}/${download['downloadedAt'].year}',
                                  ),
                                  isThreeLine: true,
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
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
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_announcement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcement')),
        body: const Center(child: Text('Announcement not found')),
      );
    }

    final authProvider = context.watch<AuthProvider>();
    final isInstructor = authProvider.user?.role == 'instructor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
      ),
      body: Column(
        children: [
          // Announcement Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      child: Text(_announcement!.authorName[0].toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _announcement!.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _announcement!.timeAgo,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  _announcement!.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Content
                Text(
                  _announcement!. content,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Attachments
                if (_announcement!.attachmentUrls.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Attachments:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._announcement! .attachmentUrls.map((url) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(url. split('/').last),
                      trailing: const Icon(Icons.download),
                      onTap: () {
                        // Track download
                        final trackingService = TrackingService();
                        trackingService.trackAnnouncementDownload(
                          announcementId: widget.announcementId,
                          userId: authProvider.user!.id,
                          userName: authProvider.user!.displayName,
                          fileName: url.split('/').last,
                        );
                        // TODO: Implement actual download
                      },
                    ),
                  )),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 16),
                const Divider(),

                // Stats
                Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${_announcement!.viewCount} views'),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${_comments.length} comments'),
                  ],
                ),

                if (isInstructor) ...[
                  const SizedBox(height: 8),
                  TextButton. icon(
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('View Tracking'),
                    onPressed: _showTrackingDialog,
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(),

                // Comments Section
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (_comments.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No comments yet. Be the first to comment!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),

                // Comments List
                ..._comments.map((comment) {
                  final isMyComment = comment['userId'] == authProvider.user?. id;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                child: Text(comment['userName'][0].toUpperCase()),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comment['userName'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _formatTime(comment['createdAt']),
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMyComment || isInstructor)
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteComment(comment['id']),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(comment['content']),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    enabled: !_isSubmitting,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSubmitting ? null : _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}