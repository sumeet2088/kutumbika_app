import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/login_result.dart';
import '../screens/create_family_screen.dart';
import '../screens/device_register_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../utils/app_colors.dart';

Future<void> goAfterLogin(BuildContext context, LoginResult result) async {
  Widget dest;
  if (result.requiresDeviceRegistration) {
    dest = DeviceRegisterScreen(result: result);
  } else if (result.isNewUser) {
    dest = const CreateFamilyScreen();
  } else {
    dest = const MainShell();
  }
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => dest),
    (route) => false,
  );
}

Future<void> goToLogin(BuildContext context) {
  return Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.prefix,
    this.validator,
    this.maxLength,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefix;
  final String? Function(String?)? validator;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDarkBlue,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.5)),
            prefixIcon:
                prefix == null ? null : Icon(prefix, color: AppColors.grey),
            filled: true,
            fillColor: AppColors.lightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.inbox_outlined, size: 48, color: AppColors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration fieldDecoration({String? hint, IconData? prefix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.grey.withValues(alpha: 0.5)),
    prefixIcon: prefix == null ? null : Icon(prefix, color: AppColors.grey),
    filled: true,
    fillColor: AppColors.lightGrey,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
