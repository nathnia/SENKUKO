import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final IconData? icon;
  final FocusNode? focusNode;

  /// false = icon kiri (default)
  /// true = icon kanan
  final bool iconRight;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.icon,
    this.focusNode,
    this.iconRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,

          // HOME PAGE
          prefixIcon: !iconRight && icon != null
              ? Icon(icon, color: AppColors.icon)
              : null,

          // SEARCH PAGE
          suffixIcon: iconRight && icon != null
              ? Icon(icon, color: AppColors.icon)
              : null,
        ),
      ),
    );
  }
}