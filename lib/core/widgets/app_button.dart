import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool outlined;
  final double height;
  final double radius;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.outlined = false,
    this.height = 50,
    this.radius = 14,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon ?? const SizedBox(),
          label: Text(text),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(
              color: AppColors.primary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon ?? const SizedBox(),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}