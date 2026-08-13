import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/evidence_service.dart';
import '../../widgets/gradient_background.dart';
import '../profile/profile_screen.dart';
import '../evidence/cloud_evidence_screen.dart';
import '../users/user_management_screen.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.secureCamera);
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthService>().currentUser;
    final evidenceService = context.watch<EvidenceService>();

    final List<Widget> pages = [
      // 0: Home (Dashboard Summary)
      _buildHomeSummary(theme, user, evidenceService),
      // 1: Placeholder for Capture
      const SizedBox.shrink(),
      // 2: All Evidence (Cloud)
      const CloudEvidenceScreen(title: 'All Evidence', showBottomNav: true),
      // 3: Users/Admin
      const UserManagementScreen(showBottomNav: true),
      // 4: Profile
      const ProfileScreen(showBottomNav: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF00BFA6),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_rounded), label: 'Capture'),
          BottomNavigationBarItem(icon: Icon(Icons.all_inbox_rounded), label: 'All Evidence'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeSummary(ThemeData theme, user, EvidenceService evidenceService) {
    return GradientBackground(
      addOverlay: true,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF00BFA6),
                      child: Text(
                        user?.name?.isNotEmpty == true ? user!.name!.substring(0, 1).toUpperCase() : 'O',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: theme.textTheme.bodySmall),
                        Text(user?.name ?? 'Officer', style: theme.textTheme.titleLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OFFICER CONTROL CENTER', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.5, color: Colors.redAccent)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'User Admin',
                            value: 'Manage',
                            icon: Icons.admin_panel_settings,
                            color: Colors.redAccent,
                            onTap: () => _onTabTapped(3),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'New Capture',
                            value: '+',
                            icon: Icons.add_a_photo,
                            color: const Color(0xFF00BFA6),
                            onTap: () => _onTabTapped(1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2D4A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(20)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
