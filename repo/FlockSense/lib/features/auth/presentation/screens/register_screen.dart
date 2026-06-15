import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';
import 'package:flock_sense/features/auth/presentation/widgets/auth_header.dart';
import 'package:flock_sense/shared/widgets/custom_button.dart';
import 'package:flock_sense/shared/widgets/custom_text_field.dart';
import 'package:flock_sense/shared/widgets/error_widget.dart';
import 'package:flock_sense/shared/widgets/loading_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Name is required.';
        _isLoading = false;
      });
      return;
    }

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

    if (confirmPassword != password) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    try {
      await AuthService.register(name: name, email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } on FirebaseAuthException catch (exception) {
      setState(() {
        _errorMessage = AuthService.mapAuthException(exception);
      });
    } on FirebaseException catch (exception) {
      setState(() {
        _errorMessage = AuthService.mapFirebaseException(exception);
      });
    } catch (error) {
      debugPrint('Register error: $error');
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
                  title: 'Create account',
                  subtitle: 'Start managing your poultry farm with FlockSense.',
                ),
                const SizedBox(height: 32),
                CustomTextField(controller: _nameController, hintText: 'Name'),
                const SizedBox(height: 16),
                CustomTextField(controller: _emailController, hintText: 'Email'),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  AppErrorWidget(message: _errorMessage!),
                if (_isLoading)
                  const LoadingWidget()
                else
                  CustomButton(label: 'Register', onPressed: _register),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Login'),
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
