import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key, required this.contact, required this.isEmail});
  final String contact;
  final bool isEmail;
  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _loading   = false;
  bool _showPass  = false;
  bool _showConf  = false;
  String? _error;

  int get _strength {
    final p = _passCtrl.text;
    int s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(p)) s++;
    return s;
  }

  Color get _strengthColor => [Colors.red, Colors.orange, Colors.yellow.shade700, Colors.lightGreen, Colors.green][_strength];
  String get _strengthLabel => ['', 'Weak', 'Fair', 'Good', 'Strong'][_strength];

  @override
  void dispose() { _nameCtrl.dispose(); _passCtrl.dispose(); _confCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (widget.isEmail) {
        await AuthService.createAccount(name: _nameCtrl.text.trim(), email: widget.contact, password: _passCtrl.text.trim());
      } else {
        // Phone auth already signed in — just update display name and user doc.
        final user = FirebaseAuth.instance.currentUser;
        await user?.updateDisplayName(_nameCtrl.text.trim());
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.initial, (_) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = AuthService.mapAuthException(e));
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(children: [
                  Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Back', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                ]),
              ),
              const SizedBox(height: 36),
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(22)),
                  child: const Icon(Icons.lock_open_outlined, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Center(child: Text('Almost done!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary))),
              const Center(child: Text('Set your name and a strong password', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
              const SizedBox(height: 32),

              // Verified contact chip
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(widget.contact, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),

              if (widget.isEmail) ...[
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPass,
                  decoration: InputDecoration(
                    labelText: 'Create password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                ),
                if (_passCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    ...List.generate(4, (i) => Expanded(child: Container(
                      height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i < _strength ? _strengthColor : AppColors.divider,
                      ),
                    ))),
                    const SizedBox(width: 8),
                    Text(_strengthLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _strengthColor)),
                  ]),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confCtrl,
                  obscureText: !_showConf,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_showConf ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showConf = !_showConf),
                    ),
                  ),
                  validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 28),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Create My Account'),
              ),

              const SizedBox(height: 16),
              const Center(
                child: Text('By creating an account you agree to our\nTerms of Service and Privacy Policy.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.6)),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }
}
