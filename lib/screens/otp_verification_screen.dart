import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';
import 'home_screen.dart';
import '../services/api_service.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String mobile;

  const OTPVerificationScreen({
    super.key,
    required this.mobile,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = AppConstants.otpResendTimer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _canResend = false;
      _resendTimer = AppConstants.otpResendTimer;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer <= 0) {
          timer.cancel();
          setState(() {
            _canResend = true;
          });
        }
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != AppConstants.otpLength) {
      ErrorHandler.showError(
          context, 'Please enter ${AppConstants.otpLength}-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.verifyOTP(widget.mobile, _otpController.text);

      if (mounted) {
        ErrorHandler.showSuccess(context, 'OTP verified successfully');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    try {
      await _apiService.sendOTP(widget.mobile);
      _startResendTimer();

      if (mounted) {
        ErrorHandler.showSuccess(context, 'OTP resent successfully');
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
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.primaryDarkBlue,
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Verify OTP',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarkBlue,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Enter the 6-digit OTP sent to ${widget.mobile}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // OTP input field
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(AppConstants.otpLength),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarkBlue,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text(
                            'Verify',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend OTP
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive OTP? ",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      TextButton(
                        onPressed: _canResend ? _resendOTP : null,
                        child: Text(
                          _canResend ? 'Resend' : 'Resend in $_resendTimer sec',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.secondaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
