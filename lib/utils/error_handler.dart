import 'package:flutter/material.dart';

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

  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Failed to initialize app')) {
        return 'Unable to initialize app. Please check your connection.';
      } else if (message.contains('Failed to send OTP')) {
        return 'Unable to send OTP. Please try again.';
      } else if (message.contains('Failed to verify OTP')) {
        return 'Invalid OTP. Please try again.';
      } else if (message.contains('Failed to get user details')) {
        return 'Unable to fetch user details.';
      } else if (message.contains('Failed to get documents')) {
        return 'Unable to fetch documents.';
      } else if (message.contains('Connection')) {
        return 'Network error. Please check your internet connection.';
      }
      return 'An error occurred. Please try again.';
    }
    return 'An unexpected error occurred.';
  }
}