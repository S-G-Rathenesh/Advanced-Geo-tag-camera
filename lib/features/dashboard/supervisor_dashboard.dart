import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/evidence_service.dart';
import '../../services/sync_service.dart';
import '../../widgets/gradient_background.dart';

/// Officer home screen with quick stats and action cards.
class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Load evidence data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EvidenceService>().loadEvidence();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final evidenceService = context.watch<EvidenceService>();
    final syncService = context.watch<SyncService>();
    final user = authService.currentUser;

    return Scaffold(
      body: GradientBackground(
        addOverlay: true,
        child: SafeArea(
          child: FadeTransition(
            opacity: _animController,
            child: CustomScrollView(
              slivers: [
                // Welcome header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              (user?.name?.isNotEmpty == true) ? user!.name!.substring(0, 1).toUpperCase() : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                user?.name ?? 'Officer',
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BFA6).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00BFA6).withAlpha(50),
                            ),
                          ),
                          child: Text(
                            user?.department ?? 'SUPERVISOR',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF00BFA6),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        _StatTile(
                          label: 'Total',
                          value: '${evidenceService.evidenceList.length}',
                          icon: Icons.photo_camera_rounded,
                          color: const Color(0xFF3D8BFF),
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          label: 'Pending',
                          value: '${evidenceService.pendingCount}',
                          icon: Icons.schedule_rounded,
                          color: AppTheme.statusPending,
                        ),
                        const SizedBox(width: 12),
                        _StatTile(
                          label: 'Synced',
                          value: '${evidenceService.syncedCount}',
                          icon: Icons.cloud_done_rounded,
                          color: AppTheme.statusSynced,
                        ),
                      ],
                    ),
                  ),
                ),

                // Last sync indicator
                if (syncService.lastSyncTime != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Last sync: ${DateFormat('HH:mm').format(syncService.lastSyncTime!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Action cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildListDelegate([
                      _ActionCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'New Capture',
                        subtitle: 'Take evidence photo',
                        gradient: AppTheme.accentGradient,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.secureCamera),
                      ),
                      _ActionCard(
                        icon: Icons.folder_rounded,
                        title: 'My Evidence',
                        subtitle: 'View captured records',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3D8BFF), Color(0xFF1565C0)],
                        ),
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.myEvidence),
                      ),
                      _ActionCard(
                        icon: Icons.sync_rounded,
                        title: 'Sync Status',
                        subtitle: 'Upload queue',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFAB00), Color(0xFFFF8F00)],
                        ),
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.syncStatus),
                      ),
                      _ActionCard(
                        icon: Icons.person_rounded,
                        title: 'Profile',
                        subtitle: 'Account & settings',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFF651FFF)],
                        ),
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.profile),
                      ),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              break; // Already on dashboard
            case 1:
              Navigator.pushNamed(context, AppRoutes.secureCamera);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.myEvidence);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Capture',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_rounded),
            label: 'Evidence',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Stat tile widget ──────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2940),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withAlpha(40),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF6B7A8D),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action card widget ────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2940),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6B7A8D),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
