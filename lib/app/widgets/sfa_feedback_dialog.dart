import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

enum SfaFeedbackType {
  success,
  error,
  warning,
  info,
  sync,
  approval,
  upload,
  delete,
  update,
}

class SfaFeedbackDialog extends StatelessWidget {
  const SfaFeedbackDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.detail,
    this.actionLabel = 'OK',
    this.onAction,
    this.autoCloseAfter,
  });
  final SfaFeedbackType type;
  final String title, message, actionLabel;
  final String? detail;
  final VoidCallback? onAction;
  final Duration? autoCloseAfter;

  static Future<void> show({
    required SfaFeedbackType type,
    required String title,
    required String message,
    String? detail,
    String actionLabel = 'OK',
    VoidCallback? onAction,
    Duration? autoCloseAfter,
  }) async {
    if (autoCloseAfter != null)
      Timer(autoCloseAfter, () {
        if (Get.isDialogOpen ?? false) Get.back();
      });
    await Get.dialog<void>(
      SfaFeedbackDialog(
        type: type,
        title: title,
        message: message,
        detail: detail,
        actionLabel: actionLabel,
        onAction: onAction,
        autoCloseAfter: autoCloseAfter,
      ),
      barrierDismissible: autoCloseAfter == null,
    );
  }

  bool get _isSuccess => {
    SfaFeedbackType.success,
    SfaFeedbackType.sync,
    SfaFeedbackType.approval,
    SfaFeedbackType.upload,
    SfaFeedbackType.update,
  }.contains(type);
  Color get _color => switch (type) {
    SfaFeedbackType.error || SfaFeedbackType.delete => AppColors.danger,
    SfaFeedbackType.warning => AppColors.warning,
    SfaFeedbackType.info => AppColors.primary,
    _ => AppColors.success,
  };
  IconData get _icon => switch (type) {
    SfaFeedbackType.error => Icons.error_outline_rounded,
    SfaFeedbackType.warning => Icons.warning_amber_rounded,
    SfaFeedbackType.info => Icons.info_outline_rounded,
    SfaFeedbackType.delete => Icons.delete_outline_rounded,
    SfaFeedbackType.upload => Icons.cloud_upload_rounded,
    SfaFeedbackType.approval => Icons.verified_rounded,
    SfaFeedbackType.sync => Icons.sync_rounded,
    SfaFeedbackType.update => Icons.edit_rounded,
    _ => Icons.check_rounded,
  };

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 30),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSuccess)
            Image.asset(
              'assets/images/dialogs/success_check.png',
              height: 112,
              errorBuilder: (_, __, ___) => _iconBadge(),
            )
          else
            _iconBadge(),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (detail != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(detail!, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          if (autoCloseAfter == null) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Get.back();
                  onAction?.call();
                },
                child: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _iconBadge() => Container(
    width: 86,
    height: 86,
    decoration: BoxDecoration(
      color: _color.withValues(alpha: .12),
      shape: BoxShape.circle,
    ),
    child: Icon(_icon, color: _color, size: 48),
  );
}
