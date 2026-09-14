import 'package:flutter/material.dart';

/// Clean, reusable Hen icon for FlockSense poultry navigation and facilities.
class HenIcon extends StatelessWidget {
  const HenIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ImageIcon(
      const AssetImage('assets/images/hen_icon.png'),
      size: size,
      color: color,
    );
  }
}
