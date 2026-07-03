import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';
import 'package:flock_sense/features/auth/presentation/screens/create_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.contact,
    required this.isEmail,
    this.devCode,
    this.verificationId,
  });
  final String contact;
  final bool isEmail;
  final String? devCode;          // email OTP dev-mode preview
  final String? verificationId;  // phone OTP

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focuses     = List.generate(4, (_) => FocusNode());
  bool _verifying = false;
  bool _showDevCode = true;       // dev-mode OTP banner
  String? _error;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-fill dev code after 1 s for easy testing.
    if (widget.devCode != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        for (int i = 0; i < 4; i++) {
          _controllers[i].text = widget.devCode![i];
        }
        setState(() {});
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _resendSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focuses) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 4) { setState(() => _error = 'Enter the 4-digit code'); return; }
    setState(() { _verifying = true; _error = null; });
    try {
      bool ok = false;
      if (widget.isEmail) {
        ok = await AuthService.verifyEmailOtp(widget.contact, _otp);
      } else {
        ok = await AuthService.verifyPhoneOtp(widget.verificationId!, _otp);
      }
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CreatePasswordScreen(
            contact: widget.contact,
            isEmail: widget.isEmail,
          ),
        ));
      } else {
        setState(() => _error = 'Incorrect code. Please check and try again.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    if (widget.isEmail) {
      await AuthService.sendEmailOtp(widget.contact);
    }
    _startTimer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('A new code was sent to ${widget.contact}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final masked = widget.isEmail
        ? _maskEmail(widget.contact)
        : _maskPhone(widget.contact);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(children: [
                Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text('Back', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 48),

            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22)),
                child: Icon(widget.isEmail ? Icons.mark_email_read_outlined : Icons.sms_outlined,
                    size: 38, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Text('Verify it\'s you', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
            const SizedBox(height: 8),
            Center(child: Text('We sent a 4-digit code to\n$masked',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6))),

            // Dev-mode OTP banner (remove in production)
            if (widget.devCode != null && _showDevCode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade300)),
                child: Row(children: [
                  const Icon(Icons.developer_mode, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Dev mode — OTP: ${widget.devCode}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                  GestureDetector(onTap: () => setState(() => _showDevCode = false), child: const Icon(Icons.close, size: 16)),
                ]),
              ),
            ],

            const SizedBox(height: 40),

            // 4 OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (i) => _OtpBox(
                controller: _controllers[i],
                focus: _focuses[i],
                onChanged: (v) {
                  if (v.isNotEmpty && i < 3) {
                    FocusScope.of(context).requestFocus(_focuses[i + 1]);
                  } else if (v.isEmpty && i > 0) {
                    FocusScope.of(context).requestFocus(_focuses[i - 1]);
                  }
                  if (_otp.length == 4) _verify();
                },
                hasError: _error != null,
              )),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
              ]),
            ],

            const SizedBox(height: 36),
            FilledButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Verify Code'),
            ),
            const SizedBox(height: 20),
            Center(
              child: _resendSeconds > 0
                  ? Text('Resend code in ${_resendSeconds}s',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 13))
                  : TextButton(
                      onPressed: _resend,
                      child: const Text("Didn't receive it? Resend", style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  String _maskEmail(String e) {
    final parts = e.split('@');
    if (parts.length < 2) return e;
    final name = parts[0];
    final shown = name.length > 2 ? '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}' : name;
    return '$shown@${parts[1]}';
  }

  String _maskPhone(String p) {
    if (p.length < 4) return p;
    return '${p.substring(0, p.length - 4)}****';
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({required this.controller, required this.focus, required this.onChanged, required this.hasError});
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68, height: 68,
      child: TextFormField(
        controller: controller,
        focusNode: focus,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w900,
          color: hasError ? Colors.red.shade700 : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: hasError ? Colors.red.shade50 : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: hasError ? Colors.red : AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: hasError ? Colors.red : AppColors.primary, width: 2.5)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: hasError ? Colors.red.shade300 : AppColors.border)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
