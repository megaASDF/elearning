import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _offlineModeEnabled = true;

  @override
  Widget build(BuildContext context) {
    final connectivityService = ConnectivityService.instance;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Connectivity Status
          Container(
            padding: const EdgeInsets.all(16),
            color: connectivityService.isOnline ? Colors.green. shade50 : Colors.red.shade50,
            child: Row(
              children: [
                Icon(
                  connectivityService.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: connectivityService.isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Text(
                  connectivityService.isOnline ?  'Online' : 'Offline',
                  style: TextStyle(
                    color: connectivityService.isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight. bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Notifications Section
          const ListTile(
            title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive in-app notifications'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive notifications via email'),
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
          ),
          const Divider(),
          
          // Offline Mode Section
          const ListTile(
            title: Text('Offline Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Enable Offline Mode'),
            subtitle: const Text('Access content without internet'),
            value: _offlineModeEnabled,
            onChanged: (value) => setState(() => _offlineModeEnabled = value),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Offline Data'),
            subtitle: const Text('Download latest content for offline access'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              if (! connectivityService.isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No internet connection')),
                );
                return;
              }
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Syncing...'),
                    ],
                  ),
                ),
              );

              await Future.delayed(const Duration(seconds: 2));
              
              if (mounted) {
                Navigator. pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline data synced successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Clear Offline Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Free up storage space'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Offline Data? '),
                  content: const Text('This will delete all cached content for offline access. '),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await OfflineSyncService.instance.clearOfflineData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline data cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          const Divider(),
          
          // About Section
          const ListTile(
            title: Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show terms of service
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show privacy policy
            },
          ),
        ],
      ),
    );
  }
}