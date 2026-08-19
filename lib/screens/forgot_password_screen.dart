import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.mobile = ''});

  final String mobile;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _mobile = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _api = ApiService.instance;
  bool _sent = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _mobile.text = widget.mobile;
  }

  @override
  void dispose() {
    _mobile.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_mobile.text.length != AppConstants.mobileNumberLength) {
      ErrorHandler.showError(context, 'Enter a valid mobile number');
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.sendForgotPasswordOTP(_mobile.text);
      setState(() => _sent = true);
      if (mounted) ErrorHandler.showSuccess(context, 'OTP sent');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    setState(() => _loading = true);
    try {
      await _api.resetForgotPassword(
        mobile: _mobile.text,
        otp: _otp.text,
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'Password reset. Please login.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Forgot password'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryDarkBlue,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Reset with mobile OTP',
            style: GoogleFonts.inter(color: AppColors.grey),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _mobile,
            label: 'Mobile',
            keyboardType: TextInputType.phone,
            prefix: Icons.phone,
            maxLength: AppConstants.mobileNumberLength,
          ),
          if (!_sent) ...[
            const SizedBox(height: 24),
            PrimaryButton(label: 'Send OTP', loading: _loading, onPressed: _send),
          ] else ...[
            const SizedBox(height: 16),
            AppTextField(
              controller: _otp,
              label: 'OTP',
              keyboardType: TextInputType.number,
              maxLength: AppConstants.otpLength,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _password,
              label: 'New password',
              obscure: true,
              prefix: Icons.lock,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirm,
              label: 'Confirm password',
              obscure: true,
              prefix: Icons.lock,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Reset password',
              loading: _loading,
              onPressed: _reset,
            ),
          ],
        ],
      ),
    );
  }
}
