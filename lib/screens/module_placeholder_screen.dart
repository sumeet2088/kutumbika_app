import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/ui.dart';
import 'subscription_screen.dart';

class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    this.reason,
    this.showUpgrade = false,
  });

  final String title;
  final String? reason;
  final bool showUpgrade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(title),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: headingStyle(size: 22)),
                  const SizedBox(height: 8),
                  Text(
                    reason ??
                        'This family vault module is ready in the backend. The dedicated $title screen will land in the next phase.',
                    style: bodyStyle(color: AppColors.grey),
                  ),
                ],
              ),
            ),
            if (showUpgrade) ...[
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'View plans',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
