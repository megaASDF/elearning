import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final data = await apiService.getConversations(authProvider.user?.id ?? '');
      
      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No messages yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      const Text('Start a conversation with your instructor'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final unreadCount = conversation['unreadCount'] ?? 0;
                      final lastMessageTime = DateTime.parse(conversation['lastMessageTime']);
                      
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(conversation['otherUserName'][0].toUpperCase()),
                        ),
                        title: Text(
                          conversation['otherUserName'],
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          conversation['lastMessage'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(lastMessageTime),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUserId: conversation['otherUserId'],
                                otherUserName: conversation['otherUserName'],
                              ),
                            ),
                          ).then((_) => _loadConversations());
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to instructor chat (for students)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(
                otherUserId: '1',
                otherUserName: 'Administrator',
              ),
            ),
          ).then((_) => _loadConversations());
        },
        icon: const Icon(Icons.message),
        label: const Text('Message Instructor'),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}