import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_client.dart';
import 'app_colors.dart';

enum _ToastKind { error, success, info }

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    _show(context, message: message, kind: _ToastKind.error);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, kind: _ToastKind.success);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message: message, kind: _ToastKind.info);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required _ToastKind kind,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: Duration(seconds: kind == _ToastKind.error ? 4 : 3),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        padding: EdgeInsets.zero,
        content: _AppToast(message: message, kind: kind),
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is ApiException) return error.message;
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('TimeoutException') ||
        message.contains('Connection') ||
        message.contains('Failed host lookup') ||
        message.contains('ClientException')) {
      return 'Cannot reach the API. Start api_gateway on port 8080.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}

class _AppToast extends StatelessWidget {
  const _AppToast({required this.message, required this.kind});

  final String message;
  final _ToastKind kind;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Color fill;
    final IconData icon;
    final String title;
    switch (kind) {
      case _ToastKind.error:
        accent = AppColors.error;
        fill = const Color(0xFFFFF4F4);
        icon = Icons.error_rounded;
        title = 'Something went wrong';
      case _ToastKind.success:
        accent = AppColors.success;
        fill = const Color(0xFFEFF8F1);
        icon = Icons.check_circle_rounded;
        title = 'Success';
      case _ToastKind.info:
        accent = AppColors.sky;
        fill = AppColors.bannerBlue;
        icon = Icons.info_rounded;
        title = 'Heads up';
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.navyDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
