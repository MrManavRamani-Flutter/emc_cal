import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'app_dialog.dart';

/// Standard theme-aware confirmation dialog for Delete or Destructive Actions
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool isDanger;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.delete_outline_rounded,
    this.isDanger = true,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.delete_outline_rounded,
    bool isDanger = true,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        isDanger: isDanger,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppTheme.textSecondary(context);

    return AppDialog(
      title: title,
      icon: icon,
      isDanger: isDanger,
      maxWidth: 460,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel ?? () => Navigator.of(context).pop(false),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 13.5,
          color: textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}
