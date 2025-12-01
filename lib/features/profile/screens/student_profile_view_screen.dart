import 'package:flutter/material.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/services/api_service.dart';

class StudentProfileViewScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentProfileViewScreen({
    super.key,
    required this. studentId,
    required this. studentName,
  });

  @override
  State<StudentProfileViewScreen> createState() => _StudentProfileViewScreenState();
}

class _StudentProfileViewScreenState extends State<StudentProfileViewScreen> {
  UserProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final data = await apiService.getUserProfile(widget.studentId);
      
      if (mounted) {
        setState(() {
          _profile = UserProfileModel.fromJson(data);
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
        title: Text(widget.studentName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Avatar Section
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _profile!.avatarUrl != null
                              ? NetworkImage(_profile!.avatarUrl!)
                              : null,
                          child: _profile!.avatarUrl == null
                              ? Text(
                                  _profile! .displayName[0]. toUpperCase(),
                                  style: const TextStyle(fontSize: 40),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _profile!. displayName,
                          style: Theme.of(context).textTheme.headlineSmall?. copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Student',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        // Info Cards
                        _buildInfoCard(Icons.email, 'Email', _profile! .email),
                        _buildInfoCard(Icons.phone, 'Phone', _profile!.phoneNumber ??  'Not set'),
                        if (_profile!.studentId != null)
                          _buildInfoCard(Icons.badge, 'Student ID', _profile!.studentId!),
                        _buildInfoCard(Icons.business, 'Department', _profile!.department ?? 'Not set'),
                        if (_profile!.bio != null)
                          _buildInfoCard(Icons.info, 'Bio', _profile!.bio!),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}