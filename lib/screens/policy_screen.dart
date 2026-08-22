import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/policy_texts.dart';
import '../utils/ui.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.policyKey});

  final String policyKey;

  @override
  Widget build(BuildContext context) {
    final doc = policyByKey(policyKey);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(doc.title),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Version ${doc.version}', style: bodyStyle(size: 12, color: AppColors.grey)),
          const SizedBox(height: 12),
          Text(doc.body, style: bodyStyle(size: 14)),
        ],
      ),
    );
  }
}

class PolicyListScreen extends StatelessWidget {
  const PolicyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Legal & policies'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final doc in policyDocuments)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(doc.title, style: bodyStyle(weight: FontWeight.w700)),
                  subtitle: Text('Version ${doc.version}', style: bodyStyle(size: 12, color: AppColors.grey)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PolicyScreen(policyKey: doc.key)),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
