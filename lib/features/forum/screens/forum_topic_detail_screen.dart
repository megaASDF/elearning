import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/forum_topic_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/forum_provider.dart';
import '../../../core/services/api_service.dart';

class ForumTopicDetailScreen extends StatefulWidget {
  final String topicId;

  const ForumTopicDetailScreen({super.key, required this.topicId});

  @override
  State<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen> {
  ForumTopicModel? _topic;
  bool _isLoading = true;
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final forumProvider = context.read<ForumProvider>();

      // 1. Increment View Count (Fire and forget)
      try {
        apiService.incrementForumTopicView(widget.topicId);
      } catch (_) {}

      // 2. Load Topic Details (With Offline Support)
      try {
        // Try Server
        final doc = await FirebaseFirestore.instance
            .collection('forum_topics')
            .doc(widget.topicId)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
            
        if (doc.exists) {
          final data = doc.data()!;
          _topic = ForumTopicModel.fromJson({
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
          });
        }
      } catch (e) {
        // Fallback to Cache
        debugPrint('Offline: Loading topic detail from cache');
        final doc = await FirebaseFirestore.instance
            .collection('forum_topics')
            .doc(widget.topicId)
            .get(const GetOptions(source: Source.cache));

        if (doc.exists) {
          final data = doc.data()!;
          _topic = ForumTopicModel.fromJson({
            'id': doc.id,
            ...data,
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate().toIso8601String(),
            'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String(),
          });
        }
      }

      // 3. Load Replies via Provider
      await forumProvider.loadReplies(widget.topicId);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading forum topic: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    try {
      final authProvider = context.read<AuthProvider>();
      final forumProvider = context.read<ForumProvider>();
      final user = authProvider.user;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to reply')),
        );
        return;
      }

      await forumProvider.createReply(
        widget.topicId,
        _replyController.text.trim(),
        user.id,
        user.displayName,
      );

      _replyController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error posting reply: $e');
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

  // Helper to safely format any date
  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date) ?? DateTime.now();
    } else {
      return '';
    }
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUserId = authProvider.user?.id ?? '';

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Topic Not Found')),
        body: const Center(child: Text('Topic not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  child: Text(
                                    _topic!.authorName.isNotEmpty
                                        ? _topic!.authorName[0].toUpperCase()
                                        : 'U',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _topic!.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(_topic!.createdAt), // Topic uses String
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _topic!.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(_topic!.content),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Consumer<ForumProvider>(
                                  builder: (context, provider, _) {
                                    return Text(
                                      '${provider.replies.length} replies',
                                      style: TextStyle(color: Colors.grey[600]),
                                    );
                                  }
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.visibility,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${_topic!.viewCount} views',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Replies Section
                    Consumer<ForumProvider>(
                      builder: (context, provider, child) {
                        final replies = provider.replies;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Replies (${replies.length})',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            if (replies.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text('No replies yet. Be the first to reply!'),
                                ),
                              )
                            else
                              ...replies.map((reply) {
                                final isCurrentUser = reply.authorId == currentUserId;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: isCurrentUser ? Colors.blue.shade50 : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: isCurrentUser 
                                                  ? Colors.blue 
                                                  : Colors.grey,
                                              child: Text(
                                                reply.authorName.isNotEmpty
                                                    ? reply.authorName[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        reply.authorName,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (isCurrentUser) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: const Text(
                                                            'You',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  Text(
                                                    _formatDate(reply.createdAt), // Reply uses DateTime
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(reply.content),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Reply Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitReply,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}