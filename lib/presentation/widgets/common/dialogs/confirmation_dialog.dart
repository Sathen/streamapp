import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../buttons/primary_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.outlineVariant, width: 1),
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDestructive
                          ? AppTheme.errorColor.withOpacity(0.1)
                          : AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isDestructive
                            ? AppTheme.errorColor.withOpacity(0.3)
                            : AppTheme.primaryBlue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color:
                      isDestructive
                          ? AppTheme.errorColor
                          : AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.highEmphasisText,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumEmphasisText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.mediumEmphasisText,
                      side: BorderSide(color: AppTheme.outlineColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: confirmText,
                    isDestructive: isDestructive,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
