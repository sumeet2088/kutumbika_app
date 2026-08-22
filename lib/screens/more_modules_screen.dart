import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/modules.dart';
import '../utils/ui.dart';

class MoreModulesScreen extends StatelessWidget {
  const MoreModulesScreen({super.key, required this.modules});

  final List<Map<String, dynamic>> modules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('More'),
      body: ListView.separated(
        padding: pagePadding(context, horizontal: 16, top: 12),
        itemCount: modules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final module = modules[index];
          final enabled = module['enabled'] == true;
          return AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppIconBadge(
                icon: moduleIcon('${module['module_key']}'),
                color: moduleTint('${module['module_key']}'),
              ),
              title: Text('${module['title']}', style: bodyStyle(weight: FontWeight.w700)),
              subtitle: Text(
                enabled
                    ? '${module['count'] ?? 0} items'
                    : (module['reason'] == 'PLAN_REQUIRED' ? 'Upgrade required' : 'Not available'),
                style: bodyStyle(size: 12, color: AppColors.grey),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openModule(context, module),
            ),
          );
        },
      ),
    );
  }
}
