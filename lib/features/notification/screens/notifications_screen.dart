import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      final data = await apiService.getNotifications(authProvider.user?.id ?? '');
      
      if (mounted) {
        setState(() {
          _notifications = data.map((json) => NotificationModel.fromJson(json)).toList();
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

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      final apiService = ApiService();
      await apiService.markNotificationAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      await apiService.markAllNotificationsAsRead(authProvider.user?.id ?? '');
      await _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All marked as read'), backgroundColor: Colors.green),
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

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      final apiService = ApiService();
      await apiService.deleteNotification(notification.id);
      await _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted'), backgroundColor: Colors.green),
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

  List<NotificationModel> get _filteredNotifications {
    if (_filter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, color: Colors.white),
              label: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'all',
                checked: _filter == 'all',
                child: const Text('All'),
              ),
              CheckedPopupMenuItem(
                value: 'unread',
                checked: _filter == 'unread',
                child: const Text('Unread only'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _filter == 'unread' ? 'No unread notifications' : 'No notifications',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return Card(
                        elevation: notification.isRead ? 0 : 2,
                        color: notification.isRead ? Colors.grey[100] : Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.isRead ? Colors.grey : Colors.blue,
                            child: Icon(notification.icon, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(notification.message),
                              const SizedBox(height: 4),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              if (!notification.isRead)
                                const PopupMenuItem(
                                  value: 'read',
                                  child: Row(
                                    children: [
                                      Icon(Icons.done, size: 20),
                                      SizedBox(width: 8),
                                      Text('Mark as read'),
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
                              if (value == 'read') {
                                _markAsRead(notification);
                              } else if (value == 'delete') {
                                _deleteNotification(notification);
                              }
                            },
                          ),
                          onTap: () {
                            if (!notification.isRead) {
                              _markAsRead(notification);
                            }
                            // TODO: Navigate to related screen based on relatedType
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}