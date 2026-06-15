import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';
import 'package:flock_sense/shared/widgets/custom_button.dart';
import 'package:flock_sense/shared/widgets/custom_text_field.dart';
import 'package:flock_sense/shared/widgets/error_widget.dart';
import 'package:flock_sense/shared/widgets/loading_widget.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _message = 'Please enter a valid email address.';
        _isLoading = false;
      });
      return;
    }

    try {
      await AuthService.sendPasswordReset(email: email);
      setState(() {
        _message = 'Password reset link sent. Check your email.';
      });
    } on FirebaseAuthException catch (exception) {
      setState(() {
        _message = AuthService.mapAuthException(exception);
      });
    } catch (error) {
      setState(() {
        _message = 'Something went wrong. Please try again.';
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
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Enter your email to receive a password reset link.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                CustomTextField(controller: _emailController, hintText: 'Email'),
                const SizedBox(height: 24),
                if (_message != null) AppErrorWidget(message: _message!),
                if (_isLoading)
                  const LoadingWidget()
                else
                  CustomButton(label: 'Send reset email', onPressed: _sendResetEmail),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
