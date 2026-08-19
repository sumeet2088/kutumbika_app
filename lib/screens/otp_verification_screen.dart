import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key, required this.mobile});

  final String mobile;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _api = ApiService.instance;
  bool _loading = false;
  bool _canResend = false;
  int _resendTimer = AppConstants.otpResendTimer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _canResend = false;
      _resendTimer = AppConstants.otpResendTimer;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendTimer--);
      if (_resendTimer <= 0) {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _verify() async {
    if (_otpController.text.length != AppConstants.otpLength) {
      ErrorHandler.showError(
          context, 'Enter the ${AppConstants.otpLength}-digit OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _api.verifyOTP(
        otp: _otpController.text,
        mobile: widget.mobile,
      );
      if (!mounted) return;
      await goAfterLogin(context, result);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    try {
      await _api.sendOTP(mobile: widget.mobile);
      _startTimer();
      if (mounted) {
        ErrorHandler.showSuccess(context, 'OTP resent');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryDarkBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verify OTP',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the OTP sent to ${widget.mobile}',
              style: GoogleFonts.inter(color: AppColors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AppConstants.otpLength),
              ],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: AppColors.primaryDarkBlue,
              ),
              decoration: fieldDecoration(),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Verify',
              loading: _loading,
              onPressed: _verify,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _canResend ? _resend : null,
                child: Text(
                  _canResend ? 'Resend OTP' : 'Resend in $_resendTimer sec',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
