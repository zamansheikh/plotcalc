import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Wraps a screen in the iPhone-like frame used in the design canvas.
class PhoneChrome extends StatelessWidget {
  final Widget child;
  const PhoneChrome({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: child,
      ),
    );
  }
}

class SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const SmallIconButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 14, color: AppColors.text),
      ),
    );
  }
}
