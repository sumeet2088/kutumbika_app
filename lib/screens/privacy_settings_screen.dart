import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'policy_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  Map<String, dynamic>? _catalog;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.listConsents();
      if (mounted) {
        setState(() {
          _catalog = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  bool _granted(String type) {
    final items = (_catalog?['consents'] as List?) ?? [];
    for (final item in items) {
      final map = item as Map;
      if ('${map['consent_type']}' == type) return map['granted'] == true;
    }
    return false;
  }

  Future<void> _set(String type, bool granted) async {
    try {
      final data = await ApiService.instance.updateConsents([
        {'consent_type': type, 'granted': granted, 'policy_version': '1.0'},
      ]);
      setState(() => _catalog = data);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _export() async {
    try {
      final data = await ApiService.instance.exportMyData();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/paarisetu-data-export.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Saved to ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Privacy & Data'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: pagePadding(context, horizontal: 16, top: 12),
              children: [
                Text('Required notices', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                _row('Terms & Conditions', _granted('TERMS_ACCEPTED'), null),
                _row('Privacy Policy', _granted('PRIVACY_NOTICE_ACKNOWLEDGED'), null),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyListScreen()));
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Read legal documents'),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Optional purposes', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                _row(
                  'AI / OCR processing',
                  _granted('AI_PROCESSING'),
                  (v) => _set('AI_PROCESSING', v),
                ),
                _row(
                  'Marketing communications',
                  _granted('MARKETING'),
                  (v) => _set('MARKETING', v),
                ),
                _row(
                  'Product analytics',
                  _granted('ANALYTICS'),
                  (v) => _set('ANALYTICS', v),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Download my data', onPressed: _export),
                const SizedBox(height: 8),
                Text(
                  'Withdrawal is as easy as granting. Required Terms/Privacy stay on while the account is active; delete the account to end them.',
                  style: bodyStyle(size: 12, color: AppColors.grey),
                ),
              ],
            ),
    );
  }

  Widget _row(String label, bool value, ValueChanged<bool>? onChanged) {
    return AppCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: bodyStyle(weight: FontWeight.w600)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
