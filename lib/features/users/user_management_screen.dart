import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/secure_app_bar.dart';
import '../evidence/cloud_evidence_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final bool showBottomNav;

  const UserManagementScreen({super.key, this.showBottomNav = false});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser?.role == UserRole.user) {
      setState(() {
        _isLoading = false;
        _error = 'Access Denied: Standard users cannot view user lists.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final users = await apiService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _grantSupervisor(String userId) async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.grantSupervisor(userId);
      _showSnackBar('Supervisor access granted');
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Failed to grant access: $e');
    }
  }

  Future<void> _revokeSupervisor(String userId) async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.revokeSupervisor(userId);
      _showSnackBar('Supervisor access revoked');
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Failed to revoke access: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _viewUserEvidence(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CloudEvidenceScreen(
          title: "${user.name ?? 'User'}'s Evidence",
          userId: user.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.read<AuthService>().currentUser;

    if (currentUser?.role == UserRole.user) {
      return Scaffold(
        appBar: const SecureAppBar(title: 'Access Restricted'),
        body: GradientBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 54),
                const SizedBox(height: 16),
                Text('Access Restricted', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Standard users are not authorized to view team or user management.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isOfficer = currentUser?.role == UserRole.officer;

    Widget body = _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF00BFA6)))
        : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load users', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _fetchUsers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchUsers,
                color: const Color(0xFF00BFA6),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      color: const Color(0xFF1E2D4A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _viewUserEvidence(user),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00BFA6),
                          child: Text(
                            user.name?.isNotEmpty == true ? user.name!.substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user.name ?? user.email ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${user.email ?? 'No email'}\nRole: ${user.roleLabel}'),
                        isThreeLine: true,
                        trailing: isOfficer && user.userId != currentUser?.userId
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'grant') _grantSupervisor(user.userId);
                                  if (value == 'revoke') _revokeSupervisor(user.userId);
                                },
                                itemBuilder: (context) => [
                                  if (user.role != UserRole.supervisor && user.role != UserRole.officer)
                                    const PopupMenuItem(
                                      value: 'grant',
                                      child: Text('Grant Supervisor'),
                                    ),
                                  if (user.role == UserRole.supervisor)
                                    const PopupMenuItem(
                                      value: 'revoke',
                                      child: Text('Revoke Supervisor'),
                                    ),
                                ],
                              )
                            : const Icon(Icons.chevron_right, color: Colors.white54),
                      ),
                    );
                  },
                ),
              );

    return Scaffold(
      appBar: const SecureAppBar(title: 'User Management'),
      body: GradientBackground(child: body),
    );
  }
}
