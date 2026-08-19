import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import '../widgets/app_logo.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService.instance;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _mobileError(String? value) {
    if (value == null || value.isEmpty) return 'Please enter mobile number';
    if (value.length != AppConstants.mobileNumberLength) {
      return 'Enter a ${AppConstants.mobileNumberLength}-digit mobile number';
    }
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      await _api.sendOTP(mobile: _mobileController.text);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OTPVerificationScreen(mobile: _mobileController.text),
        ),
      );
    });
  }

  Future<void> _passwordLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.isEmpty) {
      ErrorHandler.showError(context, 'Enter your password');
      return;
    }
    await _run(() async {
      final result = await _api.loginWithPassword(
        password: _passwordController.text,
        mobile: _mobileController.text,
      );
      if (!mounted) return;
      await goAfterLogin(context, result);
    });
  }

  Future<void> _oauth(String provider) async {
    final mobile = _mobileController.text.trim();
    final subject = mobile.isEmpty ? 'kutumbika-user' : mobile;
    await _run(() async {
      final result = await _api.loginWithOAuth(
        provider: provider,
        idToken: 'dummy.$subject.$subject@example.com',
      );
      if (!mounted) return;
      await goAfterLogin(context, result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.logoBlack,
      ),
      child: Scaffold(
        backgroundColor: AppColors.logoBlack,
        body: Column(
          children: [
            const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(32, 16, 32, 24),
                child: Center(child: AppLogo(height: 160)),
              ),
            ),
            Expanded(
              child: Container(
                color: AppColors.white,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Login',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'OTP, password, or social login — same as the gateway.',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.grey),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _social('Google', Icons.g_mobiledata,
                                  Colors.red, () => _oauth('google')),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _social('Apple', Icons.apple, Colors.black,
                                  () => _oauth('apple')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: _mobileController,
                          label: 'Mobile Number',
                          hint: '10-digit mobile',
                          keyboardType: TextInputType.phone,
                          prefix: Icons.phone,
                          maxLength: AppConstants.mobileNumberLength,
                          validator: _mobileError,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryDarkBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscure,
                          decoration: fieldDecoration(
                            hint: 'Optional for OTP login',
                            prefix: Icons.lock,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                    mobile: _mobileController.text,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.secondaryBlue,
                              ),
                            ),
                          ),
                        ),
                        PrimaryButton(
                          label: 'Send OTP',
                          loading: _loading,
                          onPressed: _sendOtp,
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Login with Password',
                          loading: _loading,
                          onPressed: _passwordLogin,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _social(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _loading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDarkBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
