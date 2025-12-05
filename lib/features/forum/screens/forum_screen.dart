import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart'; // Import AuthProvider
import '../../../core/providers/forum_provider.dart'; // Import ForumProvider
import '../widgets/forum_topic_form_dialog.dart';
import 'forum_topic_detail_screen.dart';

class ForumScreen extends StatefulWidget {
  final String courseId;

  const ForumScreen({super.key, required this.courseId});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTopics();
    });
  }

  Future<void> _loadTopics() async {
    // 🛑 UPDATED LOGIC HERE 🛑
    final provider = context.read<ForumProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    await provider.loadTopics(
      widget.courseId,
      studentId: user?.role == 'student' ? user?.id : null,
    );
  }

  Future<void> _showTopicDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ForumTopicFormDialog(courseId: widget.courseId),
    );
    if (result == true) await _loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Course Forum')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTopicDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Topic'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search topics...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: Consumer<ForumProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter locally by search query
                final filteredTopics = provider.topics
                    .where((t) => t.title
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (filteredTopics.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No topics yet'
                              : 'No topics found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        const Text('Start a discussion!'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadTopics,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredTopics.length,
                    itemBuilder: (context, index) {
                      final topic = filteredTopics[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(topic.authorName[0].toUpperCase()),
                          ),
                          title: Text(
                            topic.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                topic.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${topic.authorName} • ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  Text(
                                    ' ${topic.replyCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.visibility,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  Text(
                                    ' ${topic.viewCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForumTopicDetailScreen(
                                  topicId: topic.id,
                                ),
                              ),
                            ).then((_) => _loadTopics());
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}