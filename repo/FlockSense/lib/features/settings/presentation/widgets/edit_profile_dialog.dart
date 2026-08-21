import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_dialog.dart';
import 'package:flock_sense/core/widgets/app_text_field.dart';
import 'package:flock_sense/features/settings/data/services/settings_service.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentPhone;

  const EditProfileDialog({
    super.key,
    required this.currentName,
    required this.currentPhone,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await SettingsService.updateProfile(
        displayName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Edit Account Profile',
      icon: Icons.person_outline_rounded,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              labelText: 'Full Name',
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _phoneController,
              labelText: 'Phone Number',
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
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
          label: 'Save Profile',
          onPressed: _isLoading ? null : _save,
          isLoading: _isLoading,
          variant: AppButtonVariant.primary,
          size: AppButtonSize.small,
        ),
      ],
    );
  }
}

