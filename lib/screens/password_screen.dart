import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, required this.hasPassword});

  final bool hasPassword;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      if (widget.hasPassword) {
        await ApiService.instance.changePassword(
          currentPassword: _current.text,
          newPassword: _password.text,
          confirmPassword: _confirm.text,
        );
      } else {
        await ApiService.instance.createPassword(
          password: _password.text,
          confirmPassword: _confirm.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(widget.hasPassword ? 'Change password' : 'Create password'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.hasPassword) ...[
            AppTextField(
              controller: _current,
              label: 'Current password',
              obscure: true,
            ),
            const SizedBox(height: 16),
          ],
          AppTextField(controller: _password, label: 'New password', obscure: true),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirm,
            label: 'Confirm password',
            obscure: true,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save', loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}
