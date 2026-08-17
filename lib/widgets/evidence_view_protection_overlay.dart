import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/evidence_view_protection_service.dart';

class EvidenceViewProtectionOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTriggered;

  const EvidenceViewProtectionOverlay({
    super.key,
    required this.child,
    this.onTriggered,
  });

  @override
  State<EvidenceViewProtectionOverlay> createState() => _EvidenceViewProtectionOverlayState();
}

class _EvidenceViewProtectionOverlayState extends State<EvidenceViewProtectionOverlay>
    with SingleTickerProviderStateMixin {
  ProtectionState _state = ProtectionState.safe;
  final EvidenceViewProtectionService _service = EvidenceViewProtectionService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _service.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _state = state;
      });
      if (state == ProtectionState.triggered || state == ProtectionState.occluded) {
        widget.onTriggered?.call();
      }
    });
    _service.startMonitoring();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _service.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTriggered = _state == ProtectionState.triggered;
    final isOccluded = _state == ProtectionState.occluded;
    final isShielded = isTriggered || isOccluded;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Base evidence content
        widget.child,

        // 🚨 High-Security Anti-Surveillance Shield
        if (isShielded)
          Positioned.fill(
            child: Container(
              color: const Color(0xF2090D16),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOccluded ? const Color(0x33F59E0B) : const Color(0x33EF4444),
                        border: Border.all(
                          color: isOccluded ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isOccluded ? const Color(0x44F59E0B) : const Color(0x44EF4444),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isOccluded ? Icons.visibility_off_rounded : Icons.no_photography_rounded,
                        color: isOccluded ? const Color(0xFFFCD34D) : const Color(0xFFFCA5A5),
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isOccluded ? 'CAMERA SENSOR BLOCKED' : 'ANTI-SURVEILLANCE SHIELD ACTIVE',
                    style: GoogleFonts.inter(
                      color: isOccluded ? const Color(0xFFFCD34D) : const Color(0xFFFCA5A5),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isOccluded
                        ? 'The front camera is covered or obscured.'
                        : 'External camera or phone detected (${_service.lastThreatName}).',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE2E8F0),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOccluded
                        ? 'To protect evidence integrity, the camera must have a clear view. Uncover the lens to resume.'
                        : 'Screen is shielded to prevent photos. Lower the external device to resume viewing.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _service.resetShield();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      'Resume Viewing',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8), width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 🛡️ Active Monitoring Indicator Pill
        if (!isShielded && (_state == ProtectionState.monitoring || _state == ProtectionState.suspicious))
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _state == ProtectionState.suspicious
                    ? const Color(0xE67F1D1D)
                    : const Color(0xCC0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _state == ProtectionState.suspicious
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF334155),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _state == ProtectionState.suspicious
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      boxShadow: [
                        BoxShadow(
                          color: _state == ProtectionState.suspicious
                              ? const Color(0x88EF4444)
                              : const Color(0x8810B981),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _state == ProtectionState.suspicious
                        ? 'Threat Scanning Active'
                        : 'Anti-Surveillance Active',
                    style: GoogleFonts.inter(
                      color: _state == ProtectionState.suspicious
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
