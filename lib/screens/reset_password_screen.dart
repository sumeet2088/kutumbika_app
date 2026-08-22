import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.mobile});

  final String mobile;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_otp.text.length != AppConstants.otpLength) {
      ErrorHandler.showError(context, 'Enter the 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.instance.resetForgotPassword(
        mobile: widget.mobile,
        otp: _otp.text,
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'Password updated. Please login.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ApiService.instance.sendForgotPasswordOTP(widget.mobile);
      if (mounted) ErrorHandler.showSuccess(context, 'OTP resent');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        children: [
          Text('Reset Password', textAlign: TextAlign.center, style: headingStyle()),
          const SizedBox(height: 8),
          Text(
            'Please enter the OTP sent to your mobile/email, then create and confirm your new password.',
            textAlign: TextAlign.center,
            style: bodyStyle(color: AppColors.navyDeep),
          ),
          const SizedBox(height: 28),
          AppTextField(
            controller: _otp,
            label: 'OTP Verification Code',
            hint: 'Enter 6-digit code',
            keyboardType: TextInputType.number,
            maxLength: AppConstants.otpLength,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _password,
            label: 'New Password',
            hint: 'New password',
            obscure: _obscure,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirm,
            label: 'Confirm Password',
            hint: 'Confirm password',
            obscure: _obscure,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Update Password',
            loading: _loading,
            onPressed: _reset,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _resend,
            child: Text(
              'Resend OTP',
              style: GoogleFonts.inter(
                decoration: TextDecoration.underline,
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
