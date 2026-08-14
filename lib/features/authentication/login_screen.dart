import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/login_request.dart';
import '../../services/auth_service.dart';

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

  Future<void> _handleGoogleLogin() async {
    final authService = context.read<AuthService>();
    final response = await authService.googleLogin();
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

  void _autofillDemoOfficer() {
    setState(() {
      _usernameController.text = 'demo_officer';
      _passwordController.text = 'password123';
    });
  }

  void _autofillDemoSupervisor() {
    setState(() {
      _usernameController.text = 'demo_supervisor';
      _passwordController.text = 'password123';
    });
  }

  void _autofillDemoUser() {
    setState(() {
      _usernameController.text = 'demo_user';
      _passwordController.text = 'password123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Top Secure Connection Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF052E16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SECURE CONNECTION',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. App Icon & Title
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1322),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withAlpha(50),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_rounded,
                      color: Color(0xFF38BDF8),
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'GeoEvidence',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SECURE FIELD EVIDENCE PLATFORM',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF38BDF8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // 3. Login Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1322),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Username Field
                        Text(
                          'Username or Badge ID',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF8E9EB5),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usernameController,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF060B14),
                            hintText: 'Enter username',
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
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
                              borderSide:
                                  const BorderSide(color: Color(0xFF2563EB)),
                            ),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Username required' : null,
                        ),

                        const SizedBox(height: 14),

                        // Password Field
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Password',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8E9EB5),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Text(
                                _obscurePassword ? 'Show' : 'Hide',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF38BDF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF060B14),
                            hintText: '••••••••••••',
                            hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF64748B)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
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
                              borderSide:
                                  const BorderSide(color: Color(0xFF2563EB)),
                            ),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Password required' : null,
                        ),

                        const SizedBox(height: 20),

                        // Sign In as Officer Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: authService.isLoading
                                ? null
                                : _handleOfficerLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: authService.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign In with Credentials',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // OR Divider
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(
                                    color: Color(0xFF1E293B), height: 1)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'OR',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(
                                    color: Color(0xFF1E293B), height: 1)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Continue with Google Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: authService.isLoading
                                ? null
                                : _handleGoogleLogin,
                            icon: const Icon(
                              Icons.g_mobiledata,
                              size: 24,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Continue with Google',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFF060B14),
                              side: const BorderSide(color: Color(0xFF1E293B)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. DEMO ACCESS Header
                Text(
                  'DEMO ACCESS',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                // 5. 3 Demo Access Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildDemoCard(
                        role: 'Officer',
                        name: 'James Harrington',
                        badgeColor: const Color(0xFF1E3A8A),
                        textColor: const Color(0xFF60A5FA),
                        onTap: _autofillDemoOfficer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDemoCard(
                        role: 'Supervisor',
                        name: 'Priya Sharma',
                        badgeColor: const Color(0xFF451A03),
                        textColor: const Color(0xFFF97316),
                        onTap: _autofillDemoSupervisor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDemoCard(
                        role: 'Field User',
                        name: 'Marcus Webb',
                        badgeColor: const Color(0xFF0C4A6E),
                        textColor: const Color(0xFF38BDF8),
                        onTap: _autofillDemoUser,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 6. Security Specs Footer
                Text(
                  'GeoEvidence v2.4.1 · AES-256-GCM · SHA-256 Verified',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoCard({
    required String role,
    required String name,
    required Color badgeColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1322),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                role.toUpperCase(),
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '1-Tap Autofill',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
