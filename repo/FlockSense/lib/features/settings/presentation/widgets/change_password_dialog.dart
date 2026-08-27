import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_text_field.dart';
import 'package:flock_sense/features/settings/data/services/settings_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await SettingsService.changePassword(_passController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Change Password',
      icon: Icons.lock_reset_rounded,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _passController,
              obscureText: true,
              showObscureToggle: true,
              labelText: 'New Password',
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'Min 6 characters',
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _confirmController,
              obscureText: true,
              showObscureToggle: true,
              labelText: 'Confirm New Password',
              validator: (v) =>
                  v == _passController.text ? null : 'Passwords do not match',
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          variant: AppButtonVariant.text,
          size: AppButtonSize.small,
        ),
        const SizedBox(width: 10),
        AppButton(
          label: 'Update Password',
          onPressed: _isLoading ? null : _submit,
          isLoading: _isLoading,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.small,
        ),
      ],
    );
  }
}
