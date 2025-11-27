import 'package:flutter/material.dart';
import '../../../core/models/forum_reply_model.dart';
import '../../../core/services/api_service.dart';

class ForumTopicDetailScreen extends StatefulWidget {
  final String topicId;

  const ForumTopicDetailScreen({super.key, required this.topicId});

  @override
  State<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen> {
  List<ForumReplyModel> _replies = [];
  bool _isLoading = true;
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReplies() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getForumReplies(widget.topicId);
      if (mounted) {
        setState(() {
          _replies = data.map((json) => ForumReplyModel.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postReply() async {
    if (_replyController.text.trim().isEmpty) return;

    try {
      final apiService = ApiService();
      await apiService.createForumReply(widget.topicId, {
        'content': _replyController.text.trim(),
        'authorId': '2',
        'authorName': 'Current User',
        'attachments': [],
      });

      _replyController.clear();
      await _loadReplies();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply posted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topic Discussion')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _replies.length,
                    itemBuilder: (context, index) {
                      final reply = _replies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    child: Text(reply.authorName[0].toUpperCase()),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(
                                    '${reply.createdAt.hour}:${reply.createdAt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(reply.content),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      hintText: 'Write a reply...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _postReply,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}