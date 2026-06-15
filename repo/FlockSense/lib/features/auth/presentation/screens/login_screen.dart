import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';
import 'package:flock_sense/shared/widgets/custom_button.dart';
import 'package:flock_sense/shared/widgets/custom_text_field.dart';
import 'package:flock_sense/shared/widgets/error_widget.dart';
import 'package:flock_sense/shared/widgets/loading_widget.dart';
import 'package:flock_sense/features/auth/presentation/widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
        _isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
        _isLoading = false;
      });
      return;
    }

    try {
      await AuthService.login(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } on FirebaseAuthException catch (exception) {
      setState(() {
        _errorMessage = AuthService.mapAuthException(exception);
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Welcome back',
                  subtitle: 'Sign in to continue to your poultry management dashboard.',
                ),
                const SizedBox(height: 32),
                CustomTextField(controller: _emailController, hintText: 'Email'),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  AppErrorWidget(message: _errorMessage!),
                if (_isLoading)
                  const LoadingWidget()
                else
                  CustomButton(label: 'Login', onPressed: _login),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
