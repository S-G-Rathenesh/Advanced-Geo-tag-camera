import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../services/auth_service.dart';
import '../../models/login_request.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  
  // Staggered Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleOpacity;
  
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleOpacity;
  
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  
  late Animation<Offset> _googleSlide;
  late Animation<double> _googleOpacity;
  
  late Animation<double> _demoHeaderOpacity;
  
  late Animation<Offset> _officerSlide;
  late Animation<double> _officerOpacity;
  
  late Animation<Offset> _supervisorSlide;
  late Animation<double> _supervisorOpacity;
  
  late Animation<Offset> _fieldSlide;
  late Animation<double> _fieldOpacity;
  
  late Animation<double> _footerOpacity;

  @override
  void initState() {
    super.initState();
    
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 0.0 - 0.3: Logo
    _logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)));

    // 0.1 - 0.4: Title
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.1, 0.4, curve: Curves.easeOut)));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.1, 0.4, curve: Curves.easeOut)));

    // 0.15 - 0.45: Subtitle
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.15, 0.45, curve: Curves.easeOut)));
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.15, 0.45, curve: Curves.easeOut)));

    // 0.25 - 0.55: Login Card
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic)));
    _cardScale = Tween<double>(begin: 0.98, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic)));
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.25, 0.55, curve: Curves.easeOut)));

    // 0.4 - 0.7: Google Button
    _googleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)));
    _googleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)));

    // 0.5 - 0.8: Demo Header
    _demoHeaderOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.5, 0.8, curve: Curves.easeOut)));

    // 0.55 - 0.85: Officer
    _officerSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.55, 0.85, curve: Curves.easeOut)));
    _officerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.55, 0.85, curve: Curves.easeOut)));

    // 0.65 - 0.95: Supervisor
    _supervisorSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.65, 0.95, curve: Curves.easeOut)));
    _supervisorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.65, 0.95, curve: Curves.easeOut)));

    // 0.75 - 1.0: Field User
    _fieldSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.75, 1.0, curve: Curves.easeOut)));
    _fieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.75, 1.0, curve: Curves.easeOut)));

    // 0.8 - 1.0: Footer
    _footerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entranceController, curve: const Interval(0.8, 1.0, curve: Curves.easeOut)));

    // Start animation if mounted
    if (mounted) {
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleLogin() async {
    final authService = context.read<AuthService>();
    final response = await authService.googleLogin();
    _handleResponse(response);
  }

  Future<void> _handleDemoLogin(String username) async {
    final authService = context.read<AuthService>();
    if (username == 'demo_officer') {
      final response = await authService.login(LoginRequest(email: 'demo_officer', password: 'password123'));
      _handleResponse(response);
      return;
    }
    final response = await authService.demoLogin(username);
    _handleResponse(response);
  }

  void _handleResponse(dynamic response) {
    if (!mounted) return;
    if (response.success) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error ?? 'Authentication failed'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF040914),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Secure Connection
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF022C22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF064E3B)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SECURE CONNECTION',
                              style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Logo
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 72, height: 72,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1322),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF1E293B)),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Title
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleOpacity,
                        child: Text(
                          'Capturovert',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Subtitle
                    SlideTransition(
                      position: _subtitleSlide,
                      child: FadeTransition(
                        opacity: _subtitleOpacity,
                        child: Text(
                          'Trusted evidence. Verified location.',
                          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Login Card
                    SlideTransition(
                      position: _cardSlide,
                      child: ScaleTransition(
                        scale: _cardScale,
                        child: FadeTransition(
                          opacity: _cardOpacity,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1322),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFF1E293B)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sign in securely', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 20),
                                
                                // Google Button
                                SlideTransition(
                                  position: _googleSlide,
                                  child: FadeTransition(
                                    opacity: _googleOpacity,
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: _AnimatedGoogleButton(
                                        isLoading: authService.isLoading,
                                        onPressed: authService.isLoading ? null : _handleGoogleLogin,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Demo Header
                    FadeTransition(
                      opacity: _demoHeaderOpacity,
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFF1E293B))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('DEMO ACCESS', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                          ),
                          const Expanded(child: Divider(color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Demo Cards
                    Row(
                      children: [
                        Expanded(
                          child: SlideTransition(
                            position: _officerSlide,
                            child: FadeTransition(
                              opacity: _officerOpacity,
                              child: _AnimatedDemoCard(
                                roleTitle: 'Officer Demo', icon: Icons.security_rounded, badgeText: 'OFFICER', badgeColor: const Color(0xFF1E3A8A), textColor: const Color(0xFF60A5FA), semanticsLabel: 'Login as Demo Officer',
                                onTap: () => _handleDemoLogin('demo_officer'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SlideTransition(
                            position: _supervisorSlide,
                            child: FadeTransition(
                              opacity: _supervisorOpacity,
                              child: _AnimatedDemoCard(
                                roleTitle: 'Supervisor Demo', icon: Icons.people_alt_rounded, badgeText: 'SUPERVISOR', badgeColor: const Color(0xFF451A03), textColor: const Color(0xFFF97316), semanticsLabel: 'Login as Demo Supervisor',
                                onTap: () => _handleDemoLogin('demo_supervisor'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SlideTransition(
                            position: _fieldSlide,
                            child: FadeTransition(
                              opacity: _fieldOpacity,
                              child: _AnimatedDemoCard(
                                roleTitle: 'Field User Demo', icon: Icons.person_pin_circle_rounded, badgeText: 'FIELD USER', badgeColor: const Color(0xFF0C4A6E), textColor: const Color(0xFF38BDF8), semanticsLabel: 'Login as Demo Field User',
                                onTap: () => _handleDemoLogin('demo_user1'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Footer
                    FadeTransition(
                      opacity: _footerOpacity,
                      child: Text('v2.4.1 · AES-256-GCM · SHA-256 Verified', style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGoogleButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _AnimatedGoogleButton({required this.isLoading, required this.onPressed});

  @override
  State<_AnimatedGoogleButton> createState() => _AnimatedGoogleButtonState();
}

class _AnimatedGoogleButtonState extends State<_AnimatedGoogleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Continue with Google',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => widget.onPressed != null ? _controller.forward() : null,
          onTapUp: (_) {
            if (widget.onPressed != null) {
              _controller.reverse();
              widget.onPressed!();
            }
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isHovered && widget.onPressed != null
                    ? [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 12, spreadRadius: 1)]
                    : [],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    widget.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                        : const Icon(Icons.g_mobiledata, size: 28, color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      widget.isLoading ? 'Signing in...' : 'Continue with Google',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDemoCard extends StatefulWidget {
  final String roleTitle;
  final IconData icon;
  final String badgeText;
  final Color badgeColor;
  final Color textColor;
  final VoidCallback onTap;
  final String semanticsLabel;

  const _AnimatedDemoCard({
    required this.roleTitle, required this.icon, required this.badgeText,
    required this.badgeColor, required this.textColor, required this.onTap, required this.semanticsLabel,
  });

  @override
  State<_AnimatedDemoCard> createState() => _AnimatedDemoCardState();
}

class _AnimatedDemoCardState extends State<_AnimatedDemoCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: _isHovered ? (Matrix4.identity()..translate(0.0, -2.0)) : Matrix4.identity(),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1322),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isHovered ? widget.textColor.withOpacity(0.5) : const Color(0xFF1E293B)),
                boxShadow: _isHovered
                    ? [BoxShadow(color: widget.textColor.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: widget.textColor, size: 24),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: widget.badgeColor, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      widget.badgeText,
                      style: GoogleFonts.inter(color: widget.textColor, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.roleTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1-Tap Login',
                    style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 9.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
