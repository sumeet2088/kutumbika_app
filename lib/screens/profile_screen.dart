import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import '../utils/phone.dart';
import 'activity_screen.dart';
import 'edit_profile_screen.dart';
import 'password_screen.dart';
import 'preferences_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.instance.getUserDetails(),
        ApiService.instance.getSubscription(),
      ]);
      setState(() {
        _user = results[0];
        _sub = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _logout() async {
    try {
      await ApiService.instance.logout();
    } catch (_) {}
    if (!mounted) return;
    await goToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = displayName(_user);
    final plan = (_sub?['plan'] as Map?) ?? {};
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Profile', implyLeading: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.navy,
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.gold, fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: Text(name == 'there' ? 'Paarisetu user' : name, style: headingStyle(size: 22))),
                Center(
                  child: Text(
                    '${formatE164(_user?['mobile']?.toString())}  ${_user?['email'] ?? ''}',
                    style: bodyStyle(color: AppColors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  color: AppColors.navy,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${plan['plan_name'] ?? 'Free'} plan',
                        style: bodyStyle(color: Colors.white, weight: FontWeight.w700, size: 16)),
                    subtitle: Text('${_sub?['status'] ?? ''} · ${plan['storage_limit_gb'] ?? 0} GB',
                        style: bodyStyle(color: AppColors.gold, size: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                          .then((_) => _load());
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _tile('Personal information', Icons.edit_outlined, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user ?? {})),
                  ).then((_) => _load());
                }),
                _tile(
                  (_user?['has_password'] == true) ? 'Change password' : 'Create password',
                  Icons.lock_outline,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasswordScreen(hasPassword: _user?['has_password'] == true),
                      ),
                    ).then((_) => _load());
                  },
                ),
                _tile('Subscription & Plan', Icons.workspace_premium_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                      .then((_) => _load());
                }),
                _tile('Storage usage', Icons.cloud_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                }),
                _tile('Notifications', Icons.tune, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen()));
                }),
                _tile('Activity', Icons.history, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
                }),
                _tile('Settings', Icons.settings_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
                _tile('Logout', Icons.logout, _logout),
              ],
            ),
    );
  }

  Widget _tile(String title, IconData icon, VoidCallback onTap) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AppColors.navy),
        title: Text(title, style: bodyStyle(weight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
