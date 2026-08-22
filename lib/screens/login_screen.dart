import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/phone.dart';
import '../utils/ui.dart';
import '../widgets/app_logo.dart';
import '../widgets/phone_field.dart';
import 'forgot_password_screen.dart';
import 'otp_verification_screen.dart';
import 'policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _api = ApiService.instance;
  bool _loading = false;
  bool _obscure = true;
  bool _otpMode = false;
  bool _useEmail = false;
  bool _acceptedLegal = false;
  DialCountry _country = defaultDialCountry;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isEmail => _useEmail || looksLikeEmail(_identityController.text);

  String? _identityError(String? value) {
    if (value == null || value.isEmpty) {
      return _useEmail ? 'Enter email' : 'Enter mobile number';
    }
    if (_useEmail || looksLikeEmail(value)) {
      if (!looksLikeEmail(value)) return 'Enter a valid email';
      return null;
    }
    if (toE164(value, country: _country) == null) {
      return 'Use ${_country.nationalMin}–${_country.nationalMax} digits or +E.164';
    }
    return null;
  }

  Map<String, String> get _identity {
    final value = _identityController.text.trim();
    if (_useEmail || looksLikeEmail(value)) return {'email': value};
    return {'mobile': toE164(value, country: _country) ?? value};
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

  Future<void> _submit() async {
    if (!_acceptedLegal) {
      ErrorHandler.showError(context, 'Agree to Terms and acknowledge the Privacy Policy to continue');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_otpMode) {
      await _run(() async {
        await _api.sendOTP(
          mobile: _identity['mobile'],
          email: _identity['email'],
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              mobile: _identity['mobile'] ?? '',
              email: _identity['email'],
            ),
          ),
        );
      });
      return;
    }
    if (_passwordController.text.isEmpty) {
      ErrorHandler.showError(context, 'Enter your password');
      return;
    }
    await _run(() async {
      final result = await _api.loginWithPassword(
        password: _passwordController.text,
        mobile: _identity['mobile'],
        email: _identity['email'],
      );
      if (!mounted) return;
      await goAfterLogin(context, result);
    });
  }

  Future<void> _oauth(String provider) async {
    if (!_acceptedLegal) {
      ErrorHandler.showError(context, 'Agree to Terms and acknowledge the Privacy Policy to continue');
      return;
    }
    final identity = _identityController.text.trim();
    final subject = identity.isEmpty ? 'paarisetu-user' : identity;
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
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 28),
            children: [
              const SizedBox(height: 12),
              const Center(child: AppLogo(kind: LogoKind.icon, height: 92)),
              const SizedBox(height: 20),
              Text('Welcome to Paarisetu.', textAlign: TextAlign.center, style: headingStyle()),
              const SizedBox(height: 6),
              Text(
                'Sign in to access your secure family vault.',
                textAlign: TextAlign.center,
                style: bodyStyle(size: 14, color: AppColors.navyDeep),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_useEmail)
                      AppTextField(
                        controller: _identityController,
                        label: 'Email',
                        hint: 'you@example.com',
                        prefix: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: _identityError,
                      )
                    else
                      PhoneField(
                        controller: _identityController,
                        country: _country,
                        onCountryChanged: (c) => setState(() => _country = c),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _useEmail = !_useEmail;
                            _identityController.clear();
                          });
                        },
                        child: Text(
                          _useEmail ? 'Use mobile number' : 'Use email instead',
                          style: GoogleFonts.inter(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (!_otpMode) ...[
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Password',
                        prefix: Icons.lock_rounded,
                        obscure: _obscure,
                        onToggleObscure: () => setState(() => _obscure = !_obscure),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForgotPasswordScreen(
                                  mobile: _isEmail
                                      ? ''
                                      : (toE164(_identityController.text, country: _country) ??
                                          _identityController.text),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              decoration: TextDecoration.underline,
                              color: AppColors.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 24),
                    CheckboxListTile(
                      value: _acceptedLegal,
                      onChanged: (v) => setState(() => _acceptedLegal = v == true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Wrap(
                        children: [
                          Text('I agree to the ', style: bodyStyle(size: 13)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyScreen(policyKey: 'terms'))),
                            child: Text('Terms & Conditions', style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.navy)),
                          ),
                          Text(' and acknowledge the ', style: bodyStyle(size: 13)),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyScreen(policyKey: 'privacy'))),
                            child: Text('Privacy Policy', style: bodyStyle(size: 13, weight: FontWeight.w700, color: AppColors.navy)),
                          ),
                          Text('.', style: bodyStyle(size: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: _otpMode ? 'Send OTP' : 'Submit',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.navy)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: bodyStyle(weight: FontWeight.w600)),
                        ),
                        const Expanded(child: Divider(color: AppColors.navy)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlineActionButton(
                      label: _otpMode ? 'Login with Password' : 'Login using OTP',
                      onPressed: () => setState(() => _otpMode = !_otpMode),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circle('G', () => _oauth('google')),
                        const SizedBox(width: 18),
                        _circle('', () => _oauth('apple'), icon: Icons.apple),
                        const SizedBox(width: 18),
                        _circle('f', () => _oauth('facebook')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(String text, VoidCallback onTap, {IconData? icon}) {
    return InkWell(
      onTap: _loading ? null : onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.navy, width: 1.2),
        ),
        child: icon == null
            ? Text(text, style: headingStyle(size: 20))
            : Icon(icon, color: AppColors.navy),
      ),
    );
  }
}
