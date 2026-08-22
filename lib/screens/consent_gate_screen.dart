import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import '../services/api_service.dart';
import 'policy_screen.dart';

class ConsentGateScreen extends StatefulWidget {
  const ConsentGateScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<ConsentGateScreen> createState() => _ConsentGateScreenState();
}

class _ConsentGateScreenState extends State<ConsentGateScreen> {
  bool _terms = false;
  bool _privacy = false;
  bool _marketing = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_terms || !_privacy) {
      ErrorHandler.showError(context, 'Accept Terms and acknowledge the Privacy Policy to continue');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.instance.updateConsents([
        {'consent_type': 'TERMS_ACCEPTED', 'granted': true, 'policy_version': '1.0'},
        {'consent_type': 'PRIVACY_NOTICE_ACKNOWLEDGED', 'granted': true, 'policy_version': '1.0'},
        {'consent_type': 'MARKETING', 'granted': _marketing, 'policy_version': '1.0'},
      ]);
      if (mounted) widget.onAccepted();
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
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Privacy notice'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Before you use Paarisetu', style: headingStyle(size: 24)),
          const SizedBox(height: 8),
          Text(
            'We need a clear yes for the contract and privacy notice. Marketing is optional and separate.',
            style: bodyStyle(color: AppColors.navyDeep),
          ),
          const SizedBox(height: 16),
          _link('Terms & Conditions', 'terms'),
          _link('Privacy Policy', 'privacy'),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v == true),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I agree to the Terms & Conditions'),
          ),
          CheckboxListTile(
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v == true),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I acknowledge the Privacy Policy'),
          ),
          CheckboxListTile(
            value: _marketing,
            onChanged: (v) => setState(() => _marketing = v == true),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Send me promotional offers (optional)'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Continue',
            loading: _loading,
            onPressed: _terms && _privacy ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _link(String label, String key) {
    return TextButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PolicyScreen(policyKey: key)));
      },
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: bodyStyle(weight: FontWeight.w700, color: AppColors.navy)),
      ),
    );
  }
}
