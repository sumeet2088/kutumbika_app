import 'package:flutter/material.dart';

import '../screens/activity_screen.dart';
import '../screens/family_screen.dart';
import '../screens/reminders_screen.dart';
import '../screens/privacy_settings_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/vault_screen.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../utils/layout.dart';
import '../utils/ui.dart';
import 'app_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.user,
    required this.families,
    required this.navigatorKey,
    required this.onHome,
    required this.onFamilyChanged,
  });

  final Map<String, dynamic>? user;
  final List<dynamic> families;
  final GlobalKey<NavigatorState> navigatorKey;
  final VoidCallback onHome;
  final ValueChanged<String> onFamilyChanged;

  @override
  Widget build(BuildContext context) {
    final name = displayName(user);
    return Drawer(
      width: AppLayout.of(context).drawerWidth,
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const AppLogo(kind: LogoKind.full, height: 56),
            const SizedBox(height: 8),
            Text(AppConstants.appTagline, style: bodyStyle(size: 11, color: AppColors.grey)),
            const SizedBox(height: 16),
            Text(name == 'there' ? 'Paarisetu user' : name, style: headingStyle(size: 20)),
            const SizedBox(height: 16),
            if (families.length > 1) ...[
              Text('Switch family', style: bodyStyle(size: 12, color: AppColors.grey, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...families.map((f) {
                final map = f as Map;
                final ref = '${map['family_reference_number']}';
                final current = ref == ApiService.instance.session.familyReferenceNumber;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(current ? Icons.home : Icons.home_outlined, color: AppColors.navy),
                  title: Text('${map['family_name']}', style: bodyStyle(weight: FontWeight.w600)),
                  subtitle: Text('${map['my_role']}'),
                  trailing: current ? const Icon(Icons.check, color: AppColors.emerald) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onFamilyChanged(ref);
                  },
                );
              }),
              const Divider(),
            ],
            _tile(context, Icons.home_rounded, AppColors.navy, 'Home', onHome),
            _tile(context, Icons.folder_rounded, AppColors.sky, 'Documents', () => _open(context, const VaultScreen())),
            _tile(context, Icons.groups_rounded, AppColors.emerald, 'Family', () => _open(context, const FamilyScreen())),
            _tile(context, Icons.notifications_active_rounded, AppColors.orange, 'Reminders', () => _open(context, const RemindersScreen())),
            _tile(context, Icons.history_rounded, AppColors.purple, 'Activity', () => _open(context, const ActivityScreen())),
            _tile(context, Icons.workspace_premium_rounded, AppColors.goldSoft, 'Subscription', () => _open(context, const SubscriptionScreen())),
            _tile(context, Icons.privacy_tip_rounded, AppColors.teal, 'Privacy & Data', () => _open(context, const PrivacySettingsScreen())),
            _tile(context, Icons.settings_rounded, AppColors.navyDeep, 'Settings', () => _open(context, const SettingsScreen())),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.pop(context);
    navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _tile(BuildContext context, IconData icon, Color color, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIconBadge(icon: icon, color: color, size: 36, iconSize: 18),
      title: Text(title, style: bodyStyle(weight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}
