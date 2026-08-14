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
      _showOfficerLogin = true;
      _usernameController.text = 'demo_officer';
      _passwordController.text = 'password123';
    });
  }

  void _autofillDemoSupervisor() {
    setState(() {
      _showOfficerLogin = true;
      _usernameController.text = 'demo_supervisor';
      _passwordController.text = 'password123';
    });
  }

  void _autofillDemoUser() {
    setState(() {
      _showOfficerLogin = true;
      _usernameController.text = 'demo_user';
      _passwordController.text = 'password123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      body: LoadingOverlay(
        isLoading: authService.isLoading,
<<<<<<< HEAD
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
=======
        message: 'Authenticating...',
        child: GradientBackground(
          addOverlay: true,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Secure Geo-Tag',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Google Sign In Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _handleGoogleLogin,
                            icon: const Icon(Icons.g_mobiledata, size: 32),
                            label: const Text('Continue with Google'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showOfficerLogin = !_showOfficerLogin;
                            });
                          },
                          child: Text(
                            _showOfficerLogin ? 'Hide Credential Login' : 'Credential Login',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),

                        if (_showOfficerLogin) ...[
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _usernameController,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'Username',
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: theme.textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: theme.colorScheme.primary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: FilledButton(
                                    onPressed: _handleOfficerLogin,
                                    child: const Text('Sign In with Credentials'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 48),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text('DEMO ACCOUNTS', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              label: const Text('Demo Officer'),
                              onPressed: _autofillDemoOfficer,
                              backgroundColor: Colors.white10,
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            ActionChip(
                              label: const Text('Demo Supervisor'),
                              onPressed: _autofillDemoSupervisor,
                              backgroundColor: Colors.white10,
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            ActionChip(
                              label: const Text('Demo User'),
                              onPressed: _autofillDemoUser,
                              backgroundColor: Colors.white10,
                              labelStyle: const TextStyle(color: Colors.white),
>>>>>>> origin/main
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
