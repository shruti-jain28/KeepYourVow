// lib/features/auth/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../../../shared/theme/app_theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KYVColors.pale,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo / Title ──
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: KYVColors.sky.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.verified_outlined,
                      color: KYVColors.sky, size: 44),
                ),
                const SizedBox(height: 20),
                Text("KeepYourVow", style: KYVText.display(context)),
                const SizedBox(height: 6),
                Text(
                  _isSignUp
                      ? "Create your account"
                      : "Welcome back",
                  style: KYVText.body(context),
                ),
                const SizedBox(height: 36),

                // ── Form ──
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username field
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: _inputDecoration(
                          label: "Username",
                          icon: Icons.person_outline,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (val.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val.trim())) {
                            return 'Letters, numbers, and underscores only';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submitForm(),
                        decoration: _inputDecoration(
                          label: "Password",
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: KYVColors.darkGray,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // ── Error message ──
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFE74C3C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: KYVText.caption(context).copyWith(
                              color: const Color(0xFFE74C3C),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Submit button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isSignUp ? "Sign Up" : "Sign In"),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Divider ──
                Row(
                  children: [
                    Expanded(child: Divider(color: KYVColors.darkGray.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("or",
                          style: KYVText.caption(context).copyWith(fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: KYVColors.darkGray.withValues(alpha: 0.3))),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Google Sign-In ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text("Continue with Google"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KYVColors.slate,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: KYVColors.light, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Toggle sign-in / sign-up ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp
                          ? "Already have an account?"
                          : "Don't have an account?",
                      style: KYVText.caption(context),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _error = null;
                        });
                      },
                      child: Text(
                        _isSignUp ? "Sign In" : "Sign Up",
                        style: KYVText.caption(context).copyWith(
                          color: KYVColors.sky,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Skip button ──
                TextButton(
                  onPressed: _isLoading ? null : _skipLogin,
                  child: Text(
                    "Skip for now",
                    style: KYVText.caption(context).copyWith(
                      color: KYVColors.darkGray,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: KYVText.caption(context),
      prefixIcon: Icon(icon, color: KYVColors.sky, size: 20),
      filled: true,
      fillColor: KYVColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KYVColors.light, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KYVColors.light, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KYVColors.sky, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final notifier = ref.read(authNotifierProvider.notifier);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    String? error;
    if (_isSignUp) {
      error = await notifier.signUpWithUsername(
          username: username, password: password);
    } else {
      error = await notifier.signInWithUsername(
          username: username, password: password);
    }

    if (mounted) {
      if (error == null) {
        context.go('/');
      } else {
        setState(() {
          _isLoading = false;
          _error = error;
        });
      }
    }
  }

  Future<void> _skipLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skipped_auth', true);
    if (mounted) context.go('/');
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final error =
        await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    if (mounted) {
      if (error == null) {
        context.go('/');
      } else {
        setState(() {
          _isLoading = false;
          _error = error;
        });
      }
    }
  }
}
