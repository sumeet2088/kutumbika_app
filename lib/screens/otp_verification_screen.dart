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
  const OTPVerificationScreen({
    super.key,
    required this.mobile,
    this.email,
  });

  final String mobile;
  final String? email;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
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

  String get _otp => _digits.map((c) => c.text).join();
  String get _destination =>
      (widget.email != null && widget.email!.isNotEmpty) ? widget.email! : widget.mobile;

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
    if (_otp.length != AppConstants.otpLength) {
      ErrorHandler.showError(context, 'Enter the ${AppConstants.otpLength}-digit OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _api.verifyOTP(
        otp: _otp,
        mobile: widget.mobile.isEmpty ? null : widget.mobile,
        email: widget.email,
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
      await _api.sendOTP(
        mobile: widget.mobile.isEmpty ? null : widget.mobile,
        email: widget.email,
      );
      _startTimer();
      if (mounted) ErrorHandler.showSuccess(context, 'OTP resent');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digits) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        children: [
          Text('Verify OTP.', textAlign: TextAlign.center, style: headingStyle()),
          const SizedBox(height: 8),
          Text(
            'Enter the 6-digit code sent to your registered ${_destination.contains('@') ? 'email' : 'mobile number'}.',
            textAlign: TextAlign.center,
            style: bodyStyle(color: AppColors.navyDeep),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              return SizedBox(
                width: 44,
                child: TextField(
                  controller: _digits[i],
                  focusNode: _focus[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  style: headingStyle(size: 22),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.navy),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) _focus[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _focus[i - 1].requestFocus();
                  },
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: _canResend ? _resend : null,
            child: Text(
              _canResend ? 'Resend OTP' : 'Resend OTP in $_resendTimer',
              style: GoogleFonts.inter(
                decoration: TextDecoration.underline,
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back to login page',
              style: GoogleFonts.inter(
                decoration: TextDecoration.underline,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Submit', loading: _loading, onPressed: _verify),
        ],
      ),
    );
  }
}
