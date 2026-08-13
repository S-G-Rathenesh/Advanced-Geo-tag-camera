import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/login_request.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showOfficerLogin = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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

  Future<void> _handleGoogleLogin(String email, String sub, String name) async {
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
          content: Text(response.error ?? 'Login failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
    // According to instructions, autofill only, user must click login.
  }

  void _autofillDemoSupervisor() {
    // For Google mock, we can just trigger it since there is no form field for it normally.
    _handleGoogleLogin('demo.supervisor@gmail.com', 'demo_google_sup_123', 'Demo Supervisor');
  }

  void _autofillDemoUser() {
    _handleGoogleLogin('demo.user1@gmail.com', 'demo_google_user_1', 'Demo User 1');
  }

  void _showMockGoogleDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Mock Google Login"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: "Enter Gmail address"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                // Create a mock sub based on email to make it deterministic
                _handleGoogleLogin(email, 'mock_sub_$email', 'Mock User');
              }
            },
            child: const Text("Sign In"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();

    return Scaffold(
      body: LoadingOverlay(
        isLoading: authService.isLoading,
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
                          'GeoEvidence',
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
                            onPressed: _showMockGoogleDialog,
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
                            _showOfficerLogin ? 'Hide Officer Login' : 'Officer Login',
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
                                    child: const Text('Sign In as Officer'),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
