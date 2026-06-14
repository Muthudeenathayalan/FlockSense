import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController(text: '+91');
  final _smsCodeController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (error) {
      _errorMessage = 'Google sign-in failed: ${error.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a valid phone number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (exception) {
          setState(() {
            _errorMessage = 'Phone verification failed: ${exception.message}';
          });
        },
        codeSent: (verificationId, _) {
          setState(() {
            _codeSent = true;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (error) {
      setState(() {
        _errorMessage = 'Failed to send verification code: ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifySmsCode() async {
    final smsCode = _smsCodeController.text.trim();
    if (_verificationId == null || smsCode.isEmpty) {
      setState(() {
        _errorMessage = 'Enter the 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (error) {
      setState(() {
        _errorMessage = 'Code verification failed: ${error.toString()}';
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
      appBar: AppBar(
        title: const Text('Sign in to FlockSense'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Continue with Google or mobile number to access Firestore data.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+919999999999',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_codeSent) ...[
                TextField(
                  controller: _smsCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Verification code',
                    hintText: '123456',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifySmsCode,
                  child: const Text('Verify SMS code'),
                ),
                const SizedBox(height: 12),
              ] else ...[
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: const Text('Send verification code'),
                ),
                const SizedBox(height: 12),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 24),
              const Text(
                'Privacy note: phone and Google sign-in are used only to authenticate you to Firebase. No data is shared outside FlockSense.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
