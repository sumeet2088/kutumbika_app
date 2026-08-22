import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/ui.dart';
import 'activity_screen.dart';
import 'password_screen.dart';
import 'preferences_screen.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Account', style: bodyStyle(weight: FontWeight.w700, size: 16)),
          _tile(context, 'Change password', Icons.lock_outline, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordScreen(hasPassword: true)));
          }),
          _tile(context, 'Activity log', Icons.history, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
          }),
          const SizedBox(height: 16),
          Text('Preferences', style: bodyStyle(weight: FontWeight.w700, size: 16)),
          _tile(context, 'Notifications & language', Icons.tune, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen()));
          }),
          _tile(context, 'Subscription', Icons.workspace_premium_outlined, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
          }),
          const SizedBox(height: 16),
          Text('Danger zone', style: bodyStyle(weight: FontWeight.w700, size: 16, color: AppColors.error)),
          _tile(context, 'Deactivate account', Icons.pause_circle_outline, () async {
            final ok = await _confirm(context, 'Deactivate this account?');
            if (ok != true) return;
            await ApiService.instance.deactivateAccount();
            if (context.mounted) await goToLogin(context);
          }),
          _tile(context, 'Delete account', Icons.delete_forever_outlined, () async {
            final ok = await _confirm(context, 'Permanently delete this account?');
            if (ok != true) return;
            await ApiService.instance.deleteAccount();
            if (context.mounted) await goToLogin(context);
          }),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.instance.logout();
              } catch (_) {}
              if (context.mounted) await goToLogin(context);
            },
            child: Text('Logout', style: bodyStyle(color: AppColors.error, weight: FontWeight.w700, size: 16)),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.navy),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<bool?> _confirm(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
  }
}
