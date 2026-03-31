import 'package:flutter/material.dart';

enum ImjangButtonVariant { primary, secondary }

class ImjangButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final ImjangButtonVariant variant;

  const ImjangButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.variant = ImjangButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == ImjangButtonVariant.secondary) {
      return OutlinedButton(
        onPressed: (isEnabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      );
    }

    return ElevatedButton(
      onPressed: (isEnabled && !isLoading) ? onPressed : null,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
