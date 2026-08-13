import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';

/// Animated splash screen with security motif.
///
/// Auto-navigates to dashboard (if session exists) or login after a delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _animController.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
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
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        addOverlay: true,
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Shield icon
                  Transform.scale(
                    scale: _scaleAnim.value,
                    child: Opacity(
                      opacity: _fadeAnim.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00BFA6),
                              Color(0xFF00897B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BFA6).withAlpha(60),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // App name
                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Opacity(
                      opacity: _fadeAnim.value,
                      child: Text(
                        'GeoEvidence',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: Opacity(
                      opacity: _fadeAnim.value,
                      child: Text(
                        'Secure Field Evidence Capture',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF00BFA6),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Loading indicator
                  Opacity(
                    opacity: _fadeAnim.value,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: const Color(0xFF00BFA6).withAlpha(150),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
