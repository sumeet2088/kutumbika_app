import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/phone.dart';
import '../utils/ui.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.mobile = ''});

  final String mobile;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identity = TextEditingController();
  final _api = ApiService.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _identity.text = widget.mobile;
  }

  @override
  void dispose() {
    _identity.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final value = _identity.text.trim();
    if (value.isEmpty) {
      ErrorHandler.showError(context, 'Enter mobile or email');
      return;
    }
    setState(() => _loading = true);
    try {
      final mobile = looksLikeEmail(value) ? '' : (toE164(value) ?? value);
      if (mobile.isEmpty) {
        ErrorHandler.showError(context, 'Password reset currently uses the registered mobile number');
        return;
      }
      await _api.sendForgotPasswordOTP(mobile);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(mobile: mobile),
        ),
      );
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
    return AuthScaffold(
      child: Column(
        children: [
          Text('Forgot Password', textAlign: TextAlign.center, style: headingStyle()),
          const SizedBox(height: 8),
          Text(
            'Enter your registered mobile number or email address to reset your password.',
            textAlign: TextAlign.center,
            style: bodyStyle(color: AppColors.navyDeep),
          ),
          const SizedBox(height: 28),
          AppTextField(
            controller: _identity,
            label: 'Mobile or Email',
            hint: 'Enter mobile or email',
            keyboardType: TextInputType.emailAddress,
            maxLength: 64,
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Submit Forgot Password',
            loading: _loading,
            onPressed: _send,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Login in',
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
