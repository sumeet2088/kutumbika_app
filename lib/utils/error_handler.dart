import 'package:flutter/material.dart';

import '../services/api_client.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
