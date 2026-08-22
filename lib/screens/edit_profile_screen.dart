import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _first = TextEditingController(text: '${widget.user['first_name'] ?? ''}');
  late final _last = TextEditingController(text: '${widget.user['last_name'] ?? ''}');
  late final _email = TextEditingController(text: '${widget.user['email'] ?? ''}');
  late final _city = TextEditingController(text: '${widget.user['city'] ?? ''}');
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiService.instance.updateUser({
        'first_name': _first.text,
        'last_name': _last.text,
        'email': _email.text,
        'city': _city.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyEmail() async {
    if (_email.text.isEmpty) return;
    try {
      await ApiService.instance.sendUserOTP(email: _email.text);
      final otp = await _askOtp();
      if (otp == null) return;
      await ApiService.instance.verifyUserOTP(otp: otp, email: _email.text);
      if (mounted) ErrorHandler.showSuccess(context, 'Email verified');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<String?> _askOtp() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter OTP'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Verify')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Edit profile'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppTextField(controller: _first, label: 'First name'),
          const SizedBox(height: 16),
          AppTextField(controller: _last, label: 'Last name'),
          const SizedBox(height: 16),
          AppTextField(
            controller: _email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          TextButton(onPressed: _verifyEmail, child: const Text('Verify email OTP')),
          AppTextField(controller: _city, label: 'City'),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save', loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}
