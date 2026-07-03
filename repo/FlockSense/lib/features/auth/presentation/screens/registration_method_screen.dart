import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';
import 'package:flock_sense/features/auth/presentation/screens/otp_verification_screen.dart';

/// Step 1 of registration: user enters email OR phone number and gets an OTP.
class RegistrationMethodScreen extends StatefulWidget {
  const RegistrationMethodScreen({super.key});
  @override
  State<RegistrationMethodScreen> createState() => _RegistrationMethodScreenState();
}

class _RegistrationMethodScreenState extends State<RegistrationMethodScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _loading    = false;
  String? _error;

  @override
  void dispose() { _tabs.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final isEmail = _tabs.index == 0;
      if (isEmail) {
        final email = _emailCtrl.text.trim();
        final code  = await AuthService.sendEmailOtp(email);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            contact: email, isEmail: true, devCode: code,
          ),
        ));
      } else {
        String phone = _phoneCtrl.text.trim();
        if (!phone.startsWith('+')) phone = '+91$phone'; // default India
        String? verificationId;
        await AuthService.sendPhoneOtp(
          phoneNumber: phone,
          onError: (e) => setState(() => _error = e),
        ).then((id) => verificationId = id);
        if (!mounted) return;
        if (verificationId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              contact: phone, isEmail: false, verificationId: verificationId,
            ),
          ));
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 32),

              // Back + header
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(children: [
                  Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Back to login', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 36),

              // Icon
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.person_add_outlined, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5))),
              const Center(child: Text('We\'ll send a 4-digit code to verify you', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
              const SizedBox(height: 32),

              // Tab bar
              Container(
                height: 48,
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
                child: TabBar(
                  controller: _tabs,
                  onTap: (_) => setState(() { _error = null; }),
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [Tab(text: 'Email'), Tab(text: 'Phone')],
                ),
              ),
              const SizedBox(height: 24),

              // Tab views
              SizedBox(
                height: 90,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    // Email tab
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'you@example.com',
                      ),
                      validator: (v) {
                        if (_tabs.index != 0) return null;
                        if (v?.trim().isEmpty ?? true) return 'Enter your email';
                        if (!v!.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    // Phone tab
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '9876543210',
                        prefixText: '+91  ',
                      ),
                      validator: (v) {
                        if (_tabs.index != 1) return null;
                        if ((v?.length ?? 0) < 10) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),

              FilledButton(
                onPressed: _loading ? null : _sendOtp,
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Send OTP'),
              ),

              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'A 4-digit code will be sent to verify your contact. Codes expire in 10 minutes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.6),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}
