import 'package:flutter/material.dart';

import '../screens/family_screen.dart';
import 'app_colors.dart';
import '../screens/insurance_screen.dart';
import '../screens/module_placeholder_screen.dart';
import '../screens/more_modules_screen.dart';
import '../screens/subscription_screen.dart';
import '../screens/vault_screen.dart';
import '../screens/vehicle_screen.dart';

const supportedModules = {
  'documents',
  'family_members',
  'secure_notes',
  'digital_assets',
  'insurance',
  'bank_accounts',
  'investments',
  'passwords',
  'vehicles',
  'properties',
};

const homeTileLimit = 7;

List<Map<String, dynamic>> defaultHomeModules() {
  const rows = [
    ['documents', 'Documents', 'HOME_QUICK_ACCESS'],
    ['family_members', 'Family Members', 'HOME_QUICK_ACCESS'],
    ['secure_notes', 'Secure Notes', 'HOME_QUICK_ACCESS'],
    ['digital_assets', 'Digital Assets', 'HOME_QUICK_ACCESS'],
    ['insurance', 'Insurance', 'HOME_QUICK_ACCESS'],
    ['bank_accounts', 'Bank Accounts', 'HOME_QUICK_ACCESS'],
    ['investments', 'Investments', 'HOME_QUICK_ACCESS'],
    ['vehicles', 'Vehicles', 'MORE'],
    ['properties', 'Properties', 'MORE'],
    ['passwords', 'Passwords', 'MORE'],
  ];
  return [
    for (final row in rows)
      {
        'module_key': row[0],
        'title': row[1],
        'placement': row[2],
        'enabled': true,
        'count': 0,
      },
  ];
}

IconData moduleIcon(String key) {
  switch (key) {
    case 'documents':
      return Icons.folder_rounded;
    case 'family_members':
      return Icons.groups_rounded;
    case 'secure_notes':
      return Icons.lock_rounded;
    case 'digital_assets':
      return Icons.photo_library_rounded;
    case 'insurance':
      return Icons.health_and_safety_rounded;
    case 'bank_accounts':
      return Icons.account_balance_rounded;
    case 'investments':
      return Icons.trending_up_rounded;
    case 'passwords':
      return Icons.key_rounded;
    case 'vehicles':
      return Icons.directions_car_rounded;
    case 'properties':
      return Icons.home_work_rounded;
    default:
      return Icons.apps_rounded;
  }
}

Color moduleTint(String key) {
  switch (key) {
    case 'documents':
      return AppColors.sky;
    case 'family_members':
      return AppColors.emerald;
    case 'secure_notes':
      return AppColors.navyDeep;
    case 'digital_assets':
      return AppColors.purple;
    case 'insurance':
      return AppColors.teal;
    case 'bank_accounts':
      return AppColors.goldSoft;
    case 'investments':
      return AppColors.orange;
    case 'passwords':
      return AppColors.navy;
    case 'vehicles':
      return AppColors.sky;
    case 'properties':
      return AppColors.emerald;
    default:
      return AppColors.grey;
  }
}

List<Map<String, dynamic>> supportedHomeModules(List<dynamic> raw) {
  return raw
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .where((m) => supportedModules.contains('${m['module_key']}'))
      .toList();
}

void openModule(BuildContext context, Map<String, dynamic> module) {
  final key = '${module['module_key']}';
  final title = '${module['title'] ?? key}';
  final enabled = module['enabled'] == true;
  final reason = '${module['reason'] ?? ''}';
  if (!enabled) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModulePlaceholderScreen(
          title: title,
          reason: reason == 'PLAN_REQUIRED'
              ? 'This module is available on a paid family plan.'
              : 'You do not have access to $title in this family.',
          showUpgrade: reason == 'PLAN_REQUIRED',
        ),
      ),
    );
    return;
  }
  Widget dest;
  switch (key) {
    case 'documents':
    case 'digital_assets':
      dest = const VaultScreen();
      break;
    case 'family_members':
      dest = const FamilyScreen();
      break;
    case 'insurance':
      dest = const InsuranceScreen();
      break;
    case 'vehicles':
      dest = const VehicleScreen();
      break;
    default:
      dest = ModulePlaceholderScreen(title: title);
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
}

void openMoreModules(BuildContext context, List<Map<String, dynamic>> extras) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MoreModulesScreen(modules: extras)),
  );
}

void openUpgrade(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
  );
}
