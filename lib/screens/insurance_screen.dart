import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'document_detail_screen.dart';
import 'insurance_form_screen.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  List<dynamic> _policies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listInsurance(
        familyRef: ApiService.instance.session.familyReferenceNumber,
      );
      setState(() {
        _policies = (data['policies'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Insurance'),
      floatingActionButton: AppChromeScope.embedded(context)
          ? null
          : FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InsuranceFormScreen()),
          ).then((_) => _load());
        },
        child: const Icon(Icons.add, color: AppColors.gold),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _policies.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(message: 'No insurance policies yet. Add one and attach its PDF from Documents.'),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _policies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final map = _policies[index] as Map;
                      final expiry = '${map['expiry_date'] ?? ''}';
                      return AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.navy,
                            child: Icon(Icons.shield_outlined, color: AppColors.gold),
                          ),
                          title: Text(
                            '${map['provider'] ?? 'Insurance'}',
                            style: bodyStyle(weight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if ('${map['policy_number']}'.isNotEmpty) 'Policy ${map['policy_number']}',
                              if ('${map['vehicle_label']}'.isNotEmpty) '${map['vehicle_label']}',
                              if (expiry.isNotEmpty) 'Expiry $expiry',
                            ].join(' · '),
                            style: bodyStyle(size: 12, color: AppColors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final docRef = '${map['document_reference_number'] ?? ''}';
                            if (docRef.isEmpty) {
                              ErrorHandler.showError(context, 'No policy document attached');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DocumentDetailScreen(documentRef: docRef),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
