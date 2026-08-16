import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/evidence_view_protection_service.dart';

class EvidenceViewProtectionOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback onTriggered;

  const EvidenceViewProtectionOverlay({
    Key? key,
    required this.child,
    required this.onTriggered,
  }) : super(key: key);

  @override
  State<EvidenceViewProtectionOverlay> createState() => _EvidenceViewProtectionOverlayState();
}

class _EvidenceViewProtectionOverlayState extends State<EvidenceViewProtectionOverlay> {
  ProtectionState _state = ProtectionState.safe;
  final EvidenceViewProtectionService _service = EvidenceViewProtectionService();

  @override
  void initState() {
    super.initState();
    _service.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _state = state;
      });
      if (state == ProtectionState.triggered) {
        widget.onTriggered();
      }
    });
    _service.startMonitoring();
  }

  @override
  void dispose() {
    _service.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == ProtectionState.triggered) {
      return Container(
        color: const Color(0xFF450A0A),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, color: Color(0xFFFCA5A5), size: 48),
              const SizedBox(height: 16),
              Text(
                'SECURITY ALERT',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFCA5A5),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unauthorized recording device detected.',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Evidence hidden for security.',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        widget.child,
        if (_state == ProtectionState.monitoring || _state == ProtectionState.suspicious)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _state == ProtectionState.suspicious 
                  ? const Color(0xFF7F1D1D).withOpacity(0.9)
                  : const Color(0xFF0F172A).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _state == ProtectionState.suspicious 
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFF334155)
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_red_eye, 
                    color: _state == ProtectionState.suspicious ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8), 
                    size: 14
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Protected Viewing • Monitoring Active',
                    style: GoogleFonts.inter(
                      color: _state == ProtectionState.suspicious ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
                      fontSize: 10,
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
