import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final IconData? icon;

  // TAMBAHAN
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.icon,
    this.focusNode, // TAMBAHAN
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
        focusNode: focusNode, // TAMBAHAN
        onChanged: onChanged,
        decoration: InputDecoration(
          icon: icon != null
              ? Icon(icon, color: AppColors.icon)
              : null,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}