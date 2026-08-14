import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';

/// Pixel-perfect animated Splash Screen matching the tactical GeoEvidence UI.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  int _statusIndex = 0;
  final List<String> _statusTexts = [
    'Initializing secure environment',
    'Verifying cryptographic keystore',
    'Establishing encrypted channel',
  ];
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );

    _statusTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (mounted && _statusIndex < _statusTexts.length - 1) {
        setState(() {
          _statusIndex++;
        });
      }
    });

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    final authService = context.read<AuthService>();
    final hasSession = await authService.tryAutoLogin();

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      hasSession ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: SafeArea(
        child: Stack(
          children: [
            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Title
                  Text(
                    'GeoEvidence',
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'SECURE FIELD EVIDENCE PLATFORM',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8),
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // Horizontal loading bar
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB)
                                  .withOpacity(0.5 + (_pulseAnim.value * 0.4)),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // Status text with glowing pulsing dot
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      key: ValueKey<int>(_statusIndex),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (context, child) {
                            return Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF38BDF8)
                                    .withOpacity(_pulseAnim.value),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38BDF8)
                                        .withOpacity(_pulseAnim.value * 0.8),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusTexts[_statusIndex],
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom security spec footer
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'v2.4.1  ·  AES-256-GCM',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF334155),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
