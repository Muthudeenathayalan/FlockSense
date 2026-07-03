import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email   = TextEditingController();
  final _pass    = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading  = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.login(email: _email.text.trim(), password: _pass.text.trim());
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.initial, (_) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.mapAuthException(e));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top gradient hero ─────────────────────────────────────────
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 74, height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.agriculture, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Text('FlockSense',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Smart poultry farm management',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ]),
              ),

              // ── Card ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('Sign in to your account',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary, letterSpacing: -0.3)),
                    const SizedBox(height: 4),
                    const Text('Welcome back, farmer!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Enter your email'
                          : (!v!.contains('@') ? 'Enter a valid email' : null),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pass,
                      obscureText: !_showPass,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_showPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _showPass = !_showPass),
                        ),
                      ),
                      validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200)),
                        child: Row(children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                        ]),
                      ),
                      const SizedBox(height: 14),
                    ],

                    FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 20),

                    // Create account button — now navigates to OTP registration
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Create New Account'),
                    ),
                    const SizedBox(height: 32),

                    Center(
                      child: Text(
                        'By signing in, you agree to our Terms of Service\nand Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400, height: 1.6),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
