import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../evidence/cloud_evidence_screen.dart';

/// Tactical User Management screen matching the mockup.
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
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Officer', 'Supervisor', 'User'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser?.role == UserRole.user) {
      setState(() {
        _isLoading = false;
        _error = 'Access Denied: Standard users cannot manage accounts.';
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
      _showSnackBar('Supervisor privileges granted');
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Failed: $e');
    }
  }

  Future<void> _revokeSupervisor(String userId) async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.revokeSupervisor(userId);
      _showSnackBar('Supervisor privileges revoked');
      _fetchUsers();
    } catch (e) {
      _showSnackBar('Failed: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      if (_selectedFilter == 'Officer' && user.role != UserRole.officer) return false;
      if (_selectedFilter == 'Supervisor' && user.role != UserRole.supervisor) return false;
      if (_selectedFilter == 'User' && user.role != UserRole.user) return false;

      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final name = (user.name ?? '').toLowerCase();
        final email = (user.email ?? '').toLowerCase();
        if (!name.contains(query) && !email.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      appBar: widget.showBottomNav
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF060B14),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'User Management',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUsers,
          color: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFF0B1322),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screen Title
                      Text(
                        'User Management',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1322),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 13.5,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _filters.map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF0B1322),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  child: Text(
                                    filter,
                                    style: GoogleFonts.inter(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF8E9EB5),
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  ),
                )
              else if (_error != null && _users.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield_outlined, size: 48, color: Color(0xFF64748B)),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filteredUsers.isEmpty && _users.isEmpty)
                // Demo fallback cards matching mockup
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildDemoUserCard(
                        name: 'James Harrington',
                        role: 'OFFICER',
                        email: 'j.harrington@geoevidence.gov',
                        status: 'Active · 2 min ago',
                        actionType: null,
                        onAction: () {},
                      ),
                      const SizedBox(height: 12),
                      _buildDemoUserCard(
                        name: 'Priya Sharma',
                        role: 'SUPERVISOR',
                        email: 'p.sharma@geoevidence.gov',
                        status: 'Active · 18 min ago',
                        actionType: 'Revoke Supervisor',
                        onAction: () {},
                      ),
                      const SizedBox(height: 12),
                      _buildDemoUserCard(
                        name: 'Marcus Webb',
                        role: 'USER',
                        email: 'm.webb@geoevidence.gov',
                        status: 'Active · 1 hr ago',
                        actionType: 'Grant Supervisor',
                        onAction: () {},
                      ),
                      const SizedBox(height: 12),
                      _buildDemoUserCard(
                        name: 'Fatima Al-Rashid',
                        role: 'USER',
                        email: 'f.alrashid@geoevidence.gov',
                        status: 'Active · 3 hr ago',
                        actionType: 'Grant Supervisor',
                        onAction: () {},
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _filteredUsers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildLiveUserCard(user),
                        );
                      },
                      childCount: _filteredUsers.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveUserCard(UserModel user) {
    final initials = user.name?.isNotEmpty == true
        ? user.name!.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'US';

    final isOfficer = user.role == UserRole.officer;
    final isSupervisor = user.role == UserRole.supervisor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1322),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E36),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E3A5F)),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF60A5FA),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name ?? 'Unknown',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(user.role.name.toUpperCase()),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email ?? 'no email',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8E9EB5),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Active · 2 min ago',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isOfficer) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () {
                  if (isSupervisor) {
                    _revokeSupervisor(user.userId);
                  } else {
                    _grantSupervisor(user.userId);
                  }
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: isSupervisor ? const Color(0xFF1C1318) : const Color(0xFF1E180A),
                  side: BorderSide(
                    color: isSupervisor ? const Color(0xFF7F1D1D) : const Color(0xFF78350F),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  isSupervisor ? 'Revoke Supervisor' : 'Grant Supervisor',
                  style: GoogleFonts.inter(
                    color: isSupervisor ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoUserCard({
    required String name,
    required String role,
    required String email,
    required String status,
    required String? actionType,
    required VoidCallback onAction,
  }) {
    final initials = name.split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    final isRevoke = actionType == 'Revoke Supervisor';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1322),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E36),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E3A5F)),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF60A5FA),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(role),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8E9EB5),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (actionType != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  backgroundColor: isRevoke ? const Color(0xFF1C1318) : const Color(0xFF1E180A),
                  side: BorderSide(
                    color: isRevoke ? const Color(0xFF7F1D1D) : const Color(0xFF78350F),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  actionType,
                  style: GoogleFonts.inter(
                    color: isRevoke ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg = const Color(0xFF1E3A8A);
    Color text = const Color(0xFF60A5FA);

    if (role == 'SUPERVISOR') {
      bg = const Color(0xFF451A03);
      text = const Color(0xFFF97316);
    } else if (role == 'USER') {
      bg = const Color(0xFF0C4A6E);
      text = const Color(0xFF38BDF8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: GoogleFonts.inter(
          color: text,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
