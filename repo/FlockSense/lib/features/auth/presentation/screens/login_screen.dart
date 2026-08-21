import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_text_field.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _googleLoading = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.login(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.mapAuthException(e));
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.mapAuthException(e));
    } catch (_) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top gradient hero ─────────────────────────────────────────
              Container(
                height: 230,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.farmGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.agriculture,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'FlockSense',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Smart poultry farm management',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form Card ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign in to your account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back, farmer!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      AppTextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        labelText: 'Email address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'Enter your email'
                            : (!v!.contains('@')
                                  ? 'Enter a valid email'
                                  : null),
                      ),
                      const SizedBox(height: 14),

                      AppTextField(
                        controller: _pass,
                        obscureText: !_showPass,
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        showObscureToggle: true,
                        validator: (v) =>
                            (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.forgotPassword,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      AppButton(
                        label: 'Sign In',
                        onPressed: _login,
                        isLoading: _loading,
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.large,
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      AppButton(
                        label: 'Continue with Google',
                        onPressed: _googleLogin,
                        isLoading: _googleLoading,
                        isDisabled: _loading,
                        variant: AppButtonVariant.outlined,
                        icon: Icons.g_mobiledata,
                        size: AppButtonSize.medium,
                      ),
                      const SizedBox(height: 10),

                      AppButton(
                        label: 'Create New Account',
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        variant: AppButtonVariant.outlined,
                        icon: Icons.person_add_outlined,
                        size: AppButtonSize.medium,
                      ),
                      const SizedBox(height: 28),

                      Center(
                        child: Text(
                          'By signing in, you agree to our Terms of Service\nand Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

