import 'package:flutter/material.dart';
import 'package:senkuko/core/app_colors.dart';

class AppSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          if (onTap != null)
            GestureDetector(
              onTap: onTap,
              child: const Text(
                "Lihat semua",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}