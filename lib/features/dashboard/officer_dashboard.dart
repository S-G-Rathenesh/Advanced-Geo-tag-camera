import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/evidence_service.dart';
import '../evidence/cloud_evidence_screen.dart';
import '../profile/profile_screen.dart';
import '../users/user_management_screen.dart';

class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({super.key});

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  int _currentIndex = 0;
  final GlobalKey<CloudEvidenceScreenState> _allEvidenceKey = GlobalKey<CloudEvidenceScreenState>();

  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, AppRoutes.secureCamera);
      return;
    }
    
    if (index == 2 && _currentIndex != 2) {
      debugPrint('[evidence_navigation] role=officer destination=all_evidence isMyEvidence=false');
      _allEvidenceKey.currentState?.fetchEvidence();
    }
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final evidenceService = context.watch<EvidenceService>();

    final List<Widget> pages = [
      _buildHomeSummary(user, evidenceService),
      const SizedBox.shrink(), // Capture placeholder
      CloudEvidenceScreen(
        key: _allEvidenceKey,
        title: 'All Evidence',
        showBottomNav: true,
      ),
      const UserManagementScreen(showBottomNav: true),
      const ProfileScreen(showBottomNav: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF060B14),
            border: Border(
              top: BorderSide(color: Color(0xFF1E293B), width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            backgroundColor: const Color(0xFF060B14),
            selectedItemColor: const Color(0xFF38BDF8),
            unselectedItemColor: const Color(0xFF64748B),
            selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt_rounded),
                label: 'Capture',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_rounded),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'Evidence',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined),
                activeIcon: Icon(Icons.group_rounded),
                label: 'Users',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeSummary(user, EvidenceService evidenceService) {
    final hour = DateTime.now().hour;
    String greeting = 'Good afternoon';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    final officerName = user?.name?.isNotEmpty == true ? user!.name! : 'Officer';
    final badgeId = user?.department?.isNotEmpty == true ? user!.department! : 'OFF-4021';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Greeting + Name & Officer Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8E9EB5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      officerName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'OFFICER',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF60A5FA),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badgeId,
                      style: GoogleFonts.jetBrainsMono(
                        color: const Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Card 1: Evidence Overview
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Evidence Overview',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'System Secure',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF10B981),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Metrics Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem('6', 'Total', Colors.white),
                      Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                      _buildMetricItem('3', 'Synced', const Color(0xFF10B981)),
                      Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                      _buildMetricItem('2', 'Pending', const Color(0xFFF59E0B)),
                      Container(width: 1, height: 28, color: const Color(0xFF1E293B)),
                      _buildMetricItem('4', 'Verified', const Color(0xFF38BDF8)),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Responsive Action Buttons
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final myEvidenceBtn = SizedBox(
                        height: 44,
                        width: constraints.maxWidth < 300 ? double.infinity : null,
                        child: OutlinedButton(
                          onPressed: () {
                            debugPrint('[evidence_navigation] role=officer destination=my_evidence isMyEvidence=true');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CloudEvidenceScreen(
                                  title: 'My Evidence',
                                  isMyEvidence: true,
                                  showBottomNav: false,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F1E36),
                            side: const BorderSide(color: Color(0xFF1E3A5F)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'My Evidence',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      );

                      final allEvidenceBtn = SizedBox(
                        height: 44,
                        width: constraints.maxWidth < 300 ? double.infinity : null,
                        child: OutlinedButton(
                          onPressed: () => _onTabTapped(2),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F1E36),
                            side: const BorderSide(color: Color(0xFF1E3A5F)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'All Evidence',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      );

                      if (constraints.maxWidth < 300) {
                        return Column(
                          children: [
                            myEvidenceBtn,
                            const SizedBox(height: 12),
                            allEvidenceBtn,
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: myEvidenceBtn),
                            const SizedBox(width: 12),
                            Expanded(child: allEvidenceBtn),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Section: ACTIONS
            Text(
              'ACTIONS',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Actions 2 Cards Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(3),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1322),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Users',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '5 registered accounts',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E9EB5),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.syncStatus);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1322),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sync Evidence',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '2 pending uploads',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF8E9EB5),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Section: Security Status Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Status',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSecurityRow('Encryption', 'Active', const Color(0xFF10B981)),
                  _buildSecurityRow('Integrity', 'Verified', const Color(0xFF10B981)),
                  _buildSecurityRow('Cloud Sync', 'Connected', const Color(0xFF10B981)),
                  _buildSecurityRow('Database', 'Connected', const Color(0xFF10B981)),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Section: RECENT ACTIVITY
            Text(
              'RECENT ACTIVITY',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Evidence captured',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '10:42 AM',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF8E9EB5),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            status,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
