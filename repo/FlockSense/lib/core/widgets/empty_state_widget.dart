import 'package:flutter/material.dart';
import 'package:flock_sense/core/widgets/app_empty_state.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onButtonPressed,
    this.icon = Icons.agriculture,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onButtonPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onButtonPressed: onButtonPressed,
      icon: icon,
    );
  }
}
