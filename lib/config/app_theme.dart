// lib/config/app_theme.dart
// Shared design system for Diabetter

import 'package:flutter/material.dart';

/// Diabetter color palette
class AppColors {
  AppColors._();

  // Primary Blue
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF1E40AF);
  static const Color lightBlue = Color(0xFFEFF6FF);

  // Accent colors
  static const Color green = Color(0xFF10B981);
  static const Color lightGreen = Color(0xFFECFDF5);
  static const Color red = Color(0xFFEF4444);
  static const Color lightRed = Color(0xFFFEF2F2);
  static const Color orange = Color(0xFFF59E0B);
  static const Color lightOrange = Color(0xFFFFFBEB);

  // Neutrals
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color grey = Color(0xFF9CA3AF);
  static const Color darkGrey = Color(0xFF4B5563);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
}

/// Shared text styles
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.grey,
  );

  static const TextStyle metric = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}

/// Shared decorations
class AppDecorations {
  AppDecorations._();

  static BoxDecoration card = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration cardFlat = BoxDecoration(
    color: AppColors.lightGrey,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration cardSuccess = BoxDecoration(
    color: AppColors.lightGreen,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration cardWarning = BoxDecoration(
    color: AppColors.lightOrange,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration cardDanger = BoxDecoration(
    color: AppColors.lightRed,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration cardInfo = BoxDecoration(
    color: AppColors.lightBlue,
    borderRadius: BorderRadius.circular(12),
  );
}

/// Shared button styles
class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryBlue,
    foregroundColor: AppColors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );

  static ButtonStyle secondary = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primaryBlue,
    side: const BorderSide(color: AppColors.primaryBlue),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
