import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.isBusy = false,
    this.variant = PrimaryButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool isBusy;
  final PrimaryButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final child = isBusy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll<Size>(
        Size(expanded ? double.infinity : 0, 54),
      ),
      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevation: const WidgetStatePropertyAll<double>(0),
    );

    switch (variant) {
      case PrimaryButtonVariant.filled:
        return FilledButton(
          style: style.copyWith(
            backgroundColor: const WidgetStatePropertyAll<Color>(
              AppColors.primary,
            ),
            foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
          ),
          onPressed: isBusy ? null : onPressed,
          child: child,
        );
      case PrimaryButtonVariant.outline:
        return OutlinedButton(
          style: style.copyWith(
            side: const WidgetStatePropertyAll<BorderSide>(
              BorderSide(color: AppColors.border),
            ),
            foregroundColor: const WidgetStatePropertyAll<Color>(
              AppColors.text,
            ),
          ),
          onPressed: isBusy ? null : onPressed,
          child: child,
        );
    }
  }
}

enum PrimaryButtonVariant { filled, outline }
