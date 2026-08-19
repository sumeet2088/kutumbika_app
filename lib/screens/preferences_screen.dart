import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _email = true;
  bool _sms = true;
  bool _push = true;
  bool _digest = true;
  String _language = 'en';
  String _timezone = 'Asia/Kolkata';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.getPreferences();
      setState(() {
        _email = data['notify_email'] != false;
        _sms = data['notify_sms'] != false;
        _push = data['notify_push'] != false;
        _digest = data['reminder_digest'] != false;
        _language = '${data['language'] ?? 'en'}';
        _timezone = '${data['timezone'] ?? 'Asia/Kolkata'}';
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _save() async {
    try {
      await ApiService.instance.updatePreferences({
        'notify_email': _email,
        'notify_sms': _sms,
        'notify_push': _push,
        'reminder_digest': _digest,
        'language': _language,
        'timezone': _timezone,
      });
      if (mounted) ErrorHandler.showSuccess(context, 'Preferences saved');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: AppColors.logoBlack,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Email notifications'),
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                SwitchListTile(
                  title: const Text('SMS notifications'),
                  value: _sms,
                  onChanged: (v) => setState(() => _sms = v),
                ),
                SwitchListTile(
                  title: const Text('Push notifications'),
                  value: _push,
                  onChanged: (v) => setState(() => _push = v),
                ),
                SwitchListTile(
                  title: const Text('Reminder digest'),
                  value: _digest,
                  onChanged: (v) => setState(() => _digest = v),
                ),
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(_language),
                ),
                ListTile(
                  title: const Text('Timezone'),
                  subtitle: Text(_timezone),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: PrimaryButton(label: 'Save', onPressed: _save),
                ),
              ],
            ),
    );
  }
}
