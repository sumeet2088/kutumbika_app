import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? _sub;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getSubscription();
      setState(() {
        _sub = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await ApiService.instance.cancelSubscription(
        subscriptionRef: '${_sub?['subscription_reference_number'] ?? ''}',
      );
      await _load();
      if (mounted) ErrorHandler.showSuccess(context, 'Renewal cancelled. Access stays until period end.');
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _renew() async {
    setState(() => _busy = true);
    try {
      await ApiService.instance.renewSubscription();
      await _load();
      if (mounted) ErrorHandler.showSuccess(context, 'Subscription renewed');
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = (_sub?['plan'] as Map?) ?? {};
    final usage = (_sub?['usage'] as Map?) ?? {};
    final restrictions = (_sub?['restrictions'] as Map?) ?? {};
    final used = (usage['storage_used_bytes'] ?? 0) as num;
    final limitGb = (plan['storage_limit_gb'] ?? 0) as num;
    final limitBytes = limitGb * 1024 * 1024 * 1024;
    final progress = limitBytes <= 0 ? 0.0 : (used / limitBytes).clamp(0, 1).toDouble();
    final cancelled = _sub?['cancel_at_period_end'] == true;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Subscription & Plan'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    color: AppColors.navy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${plan['plan_name'] ?? 'Current plan'}',
                            style: headingStyle(size: 24).copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                          '${_sub?['status'] ?? ''}  ·  ${plan['billing_cycle'] ?? ''}',
                          style: bodyStyle(color: AppColors.gold),
                        ),
                        if (_sub?['access_until'] != null)
                          Text('Access until ${_sub!['access_until']}',
                              style: bodyStyle(color: Colors.white70, size: 12)),
                        const SizedBox(height: 8),
                        Text(
                          cancelled
                              ? 'Cancels at period end. No refunds. New uploads are blocked.'
                              : 'Role does not override this plan. Family usage is shared.',
                          style: bodyStyle(color: Colors.white70, size: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Storage usage', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.navy,
                          backgroundColor: AppColors.creamDark,
                        ),
                        const SizedBox(height: 8),
                        Text('${bytesLabel(used)} of ${limitGb.toStringAsFixed(0)} GB',
                            style: bodyStyle(color: AppColors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      children: [
                        _row('Documents', '${usage['document_count'] ?? 0} / ${plan['document_limit'] ?? 0}'),
                        _row('Family members', '${usage['family_member_count'] ?? 0} / ${plan['family_member_limit'] ?? 0}'),
                        _row('Devices', '${usage['device_count'] ?? 0} / ${plan['device_limit'] ?? 0}'),
                        _row('Price', '${plan['currency'] ?? 'INR'} ${plan['price'] ?? '0'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('What you can do now', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                        const SizedBox(height: 8),
                        _flag('Upload documents', restrictions['can_upload_documents'] == true),
                        _flag('Replace files', restrictions['can_replace_documents'] == true),
                        _flag('Invite members', restrictions['can_invite_members'] == true),
                        _flag('Add devices', restrictions['can_add_devices'] == true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Change Plan',
                    loading: _busy,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlansScreen()),
                      ).then((_) => _load());
                    },
                  ),
                  const SizedBox(height: 12),
                  if (cancelled)
                    OutlineActionButton(label: 'Renew before end date', onPressed: _busy ? null : _renew)
                  else
                    TextButton(
                      onPressed: _busy ? null : _cancel,
                      child: Text('Cancel renewal', style: bodyStyle(color: AppColors.error, weight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: bodyStyle(color: AppColors.grey))),
          Text(value, style: bodyStyle(weight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _flag(String label, bool ok) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? AppColors.success : AppColors.error),
      title: Text(label),
    );
  }
}

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.listPlans();
      setState(() {
        _plans = (data['plans'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _buy(Map plan) async {
    setState(() => _busy = true);
    try {
      final order = await ApiService.instance.createPayment(
        planRef: '${plan['plan_reference_number']}',
      );
      if (order['payment_required'] != true && order['subscription'] != null) {
        if (mounted) {
          ErrorHandler.showSuccess(context, 'Plan activated');
          Navigator.pop(context);
        }
        return;
      }
      final orderRef = '${order['order_reference_number']}';
      // Dummy provider treats status poll as paid.
      await ApiService.instance.paymentStatus(orderRef);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await ApiService.instance.paymentStatus(orderRef);
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'Payment recorded. Plan will activate after confirmation.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Choose a Plan'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final plan = _plans[i] as Map;
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${plan['plan_name']}', style: headingStyle(size: 22)),
                      Text('${plan['currency'] ?? 'INR'} ${plan['price']} · ${plan['billing_cycle']}',
                          style: bodyStyle(color: AppColors.grey)),
                      const SizedBox(height: 8),
                      Text('${plan['storage_limit_gb']} GB  ·  ${plan['document_limit']} documents  ·  ${plan['family_member_limit']} members',
                          style: bodyStyle(size: 13)),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Select ${plan['plan_name']}',
                        loading: _busy,
                        onPressed: () => _buy(plan),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
