
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Shows an "Under Construction" dialog for features not yet implemented
Future<void> showInConstructionDialog(
  BuildContext context, {
  String? featureName,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.construction_rounded,
          size: 48,
          color: AppColors.orange,
        ),
      ),
      title: const Text(
        'Em Construção',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        featureName != null
            ? 'A funcionalidade "$featureName" ainda está em desenvolvimento.\n\nEm breve estará disponível!'
            : 'Esta funcionalidade ainda está em desenvolvimento.\n\nEm breve estará disponível!',
        textAlign: TextAlign.center,
        style: AppTextStyles.body,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: 160,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK, ENTENDI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
