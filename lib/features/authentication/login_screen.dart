import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/login_request.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_overlay.dart';

/// Tactical GeoEvidence Login Screen matching the mobile device mockup.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'demo_officer');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleOfficerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final response = await authService.login(
      LoginRequest(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      ),
    );

    _handleResponse(response);
  }

  Future<void> _handleGoogleLogin(
      String email, String sub, String name) async {
    final authService = context.read<AuthService>();
    final response = await authService.googleLogin(email, sub, name);
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

  void _showMockGoogleDialog() {
    final emailController = TextEditingController(text: 'officer@geotag.com');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1322),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: Text(
          'Google Identity Sign In',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Google account email to sign in via verified SSO token:',
              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF060B14),
                hintText: 'user@example.com',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1E293B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                _handleGoogleLogin(email, 'google_sso_$email', email.split('@').first);
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: LoadingOverlay(
        isLoading: authService.isLoading,
        message: 'Verifying credentials...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1E36),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E3A5F)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF10B981),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE CONNECTION',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF60A5FA),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Main Heading
                Text(
                  'GeoEvidence',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Capture, protect and verify field evidence with trusted location and integrity metadata.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: const Color(0xFF8E9EB5),
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 26),

                // Form Card Container
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1322),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
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
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Username / Badge ID Field
                        TextFormField(
                          controller: _usernameController,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.5,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF060B14),
                            hintText: 'Username or Badge ID',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.5,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF060B14),
                            hintText: 'Password',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            suffixIcon: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  widthFactor: 1.0,
                                  child: Text(
                                    _obscurePassword ? 'Show' : 'Hide',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF60A5FA),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1E293B)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFF2563EB), width: 1.5),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Required' : null,
                        ),

                        const SizedBox(height: 18),

                        // Sign In as Officer Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleOfficerLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Sign In as Officer',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // OR Divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Color(0xFF1E293B), thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: Color(0xFF1E293B), thickness: 1),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Continue with Google Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _showMockGoogleDialog,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1322),
                      side: const BorderSide(color: Color(0xFF1E293B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGoogleIcon(),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // DEMO ACCESS Section Title
                Text(
                  'DEMO ACCESS',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 14),

                // Card 1: Officer
                _buildDemoCard(
                  title: 'Officer',
                  badgeLabel: 'OFFICER',
                  badgeBg: const Color(0xFF1E3A8A),
                  badgeTextColor: const Color(0xFF60A5FA),
                  description:
                      'Full administrative control over all evidence and users.',
                  onEnter: () {
                    _usernameController.text = 'demo_officer';
                    _passwordController.text = 'password123';
                    _handleOfficerLogin();
                  },
                ),

                const SizedBox(height: 12),

                // Card 2: Supervisor
                _buildDemoCard(
                  title: 'Supervisor',
                  badgeLabel: 'SUPERVISOR',
                  badgeBg: const Color(0xFF451A03),
                  badgeTextColor: const Color(0xFFF97316),
                  description:
                      'Team oversight, evidence review, own capture access.',
                  onEnter: () {
                    _handleGoogleLogin(
                      'demo.supervisor@gmail.com',
                      'demo_google_sup_123',
                      'Demo Supervisor',
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Card 3: Field User
                _buildDemoCard(
                  title: 'Field User',
                  badgeLabel: 'USER',
                  badgeBg: const Color(0xFF0C4A6E),
                  badgeTextColor: const Color(0xFF38BDF8),
                  description:
                      'Standard field operative capture, queueing, and upload.',
                  onEnter: () {
                    _handleGoogleLogin(
                      'demo.user1@gmail.com',
                      'demo_google_user_1',
                      'Demo User 1',
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeTextColor,
    required String description,
    required VoidCallback onEnter,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1322),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          color: badgeTextColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8E9EB5),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Enter Button
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: onEnter,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1E36),
                side: const BorderSide(color: Color(0xFF1E3A8A)),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Enter',
                style: GoogleFonts.inter(
                  color: const Color(0xFF60A5FA),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFFEA4335),
                  Color(0xFFFBBC05),
                  Color(0xFF34A853),
                ],
              ).createShader(const Rect.fromLTWH(0.0, 0.0, 20.0, 20.0)),
          ),
        ),
      ),
    );
  }
}
