import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/evidence_record.dart';
import '../../models/sync_status.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/secure_evidence_image.dart';

/// All Evidence Screen matching the tactical mobile UI design.
class CloudEvidenceScreen extends StatefulWidget {
  final String title;
  final String? userId;
  final bool isMyEvidence;
  final bool showBottomNav;

  const CloudEvidenceScreen({
    super.key,
    required this.title,
    this.userId,
    this.isMyEvidence = false,
    this.showBottomNav = false,
  });

  @override
  State<CloudEvidenceScreen> createState() => _CloudEvidenceScreenState();
}

class _CloudEvidenceScreenState extends State<CloudEvidenceScreen> {
  List<EvidenceRecord> _evidenceList = [];
  Map<String, String> _userNames = {};
  Map<String, String> _userRoles = {};
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['All', 'Verified', 'Pending', 'Synced', 'Failed'];

  @override
  void initState() {
    super.initState();
    _fetchEvidence();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvidence() async {
    final currentUser = context.read<AuthService>().currentUser;
    if (currentUser?.role == UserRole.user && !widget.isMyEvidence) {
      setState(() {
        _isLoading = false;
        _error = 'Access Restricted: Users are only permitted to view their own evidence.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      List<EvidenceRecord> list;
      Map<String, String> userNames = {};
      Map<String, String> userRoles = {};

      if (widget.isMyEvidence) {
        list = await apiService.getMyEvidence();
        userNames[currentUser!.userId] = currentUser.name ?? currentUser.email ?? 'Unknown User';
        userRoles[currentUser.userId] = currentUser.role.name.toUpperCase();
      } else if (widget.userId != null) {
        list = await apiService.getUserEvidence(widget.userId!);
        if (currentUser?.role != UserRole.user) {
          final users = await apiService.getUsers();
          for (var u in users) {
            userNames[u.userId] = u.name ?? u.email ?? 'User';
            userRoles[u.userId] = u.role.name.toUpperCase();
          }
        }
      } else {
        list = await apiService.getAllEvidence();
        if (currentUser?.role != UserRole.user) {
          final users = await apiService.getUsers();
          for (var u in users) {
            userNames[u.userId] = u.name ?? u.email ?? 'User';
            userRoles[u.userId] = u.role.name.toUpperCase();
          }
        }
      }

      setState(() {
        _evidenceList = list;
        _userNames = userNames;
        _userRoles = userRoles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<EvidenceRecord> get _filteredEvidence {
    return _evidenceList.where((item) {
      // Filter tab
      if (_selectedFilter == 'Verified' && item.sha256Hash.isEmpty) return false;
      if (_selectedFilter == 'Pending' && item.syncStatus == SyncStatus.synced) return false;
      if (_selectedFilter == 'Synced' && item.syncStatus != SyncStatus.synced) return false;
      if (_selectedFilter == 'Failed' && item.syncStatus != SyncStatus.failed) return false;

      // Search query
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final idMatch = item.captureId.toLowerCase().contains(query);
        final locMatch = (item.address ?? '').toLowerCase().contains(query);
        final ownerName = (_userNames[item.userId] ?? '').toLowerCase();
        final ownerMatch = ownerName.contains(query);
        if (!idMatch && !locMatch && !ownerMatch) return false;
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
                widget.title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchEvidence,
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
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Search Input
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
                            hintText: 'Search by owner, location, ID...',
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
                                    horizontal: 16,
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

              // Content State
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  ),
                )
              else if (_error != null && _evidenceList.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 48, color: Color(0xFF64748B)),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchEvidence,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_filteredEvidence.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Color(0xFF64748B)),
                          const SizedBox(height: 12),
                          Text(
                            'No evidence found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final evidence = _filteredEvidence[index];
                        final ownerName = _userNames[evidence.userId] ?? 'Unknown User';
                        final role = _userRoles[evidence.userId] ?? 'OFFICER';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildEvidenceCard(evidence, ownerName, role),
                        );
                      },
                      childCount: _filteredEvidence.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceRecord evidence, String ownerName, String role) {
    final initials = ownerName.isNotEmpty
        ? ownerName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.evidenceDetails,
          arguments: evidence,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0B1322),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview Header
            Stack(
              children: [
                Container(
                  height: 170,
                  width: double.infinity,
                  color: const Color(0xFF070E1B),
                  child: SecureEvidenceImage(
                    record: evidence,
                    fit: BoxFit.cover,
                    errorPlaceholder: _buildPlaceholderImage(),
                  ),
                ),

                // Top Left ID Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060B14).withAlpha(200),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Text(
                      evidence.captureId.length > 8 ? evidence.captureId.substring(0, 8) : evidence.captureId,
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Top Right Integrity Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF052E16).withAlpha(220),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Integrity Verified',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF10B981),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner Row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF1E3A8A),
                        child: Text(
                          initials,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF60A5FA),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          ownerName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: role == 'OFFICER' ? const Color(0xFF1E3A8A) : const Color(0xFF0C4A6E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          style: GoogleFonts.inter(
                            color: role == 'OFFICER' ? const Color(0xFF60A5FA) : const Color(0xFF38BDF8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF8E9EB5)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          evidence.address ?? 'Bengaluru, India',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF8E9EB5),
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Date & Timestamp
                  Text(
                    '14 Aug 2026 • 10:42 AM',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Footer: Accuracy & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GPS ±${evidence.accuracy.toStringAsFixed(0)}m',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _buildStatusPill(evidence.syncStatus == SyncStatus.synced),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isSynced) {
    if (isSynced) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_done_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              'Synced',
              style: GoogleFonts.inter(
                color: const Color(0xFF10B981),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFF451A03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Pending',
              style: GoogleFonts.inter(
                color: const Color(0xFFF59E0B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1E36), Color(0xFF070E1B)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Color(0xFF334155),
          size: 40,
        ),
      ),
    );
  }
}
