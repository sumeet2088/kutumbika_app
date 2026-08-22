import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final familyRef = ApiService.instance.session.familyReferenceNumber;
      final data = familyRef != null
          ? await ApiService.instance.listFamilyActivity(familyRef)
          : await ApiService.instance.getUserActivity();
      setState(() {
        _items = (data['activities'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Activity'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _items.isEmpty
              ? const EmptyState(message: 'No activity yet')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = _items[i] as Map;
                    return AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.bannerBlue,
                          child: Icon(
                            '${a['entity_type']}' == 'FAMILY' ? Icons.people_outline : Icons.description_outlined,
                            color: AppColors.sky,
                          ),
                        ),
                        title: Text(_title(a), style: bodyStyle(weight: FontWeight.w600)),
                        subtitle: Text(relativeTime(a['created_at']), style: bodyStyle(size: 12, color: AppColors.grey)),
                      ),
                    );
                  },
                ),
    );
  }

  String _title(Map a) {
    if (a['title'] != null && '${a['title']}'.isNotEmpty) return '${a['title']}';
    final action = '${a['action']}'.replaceAll('_', ' ').toLowerCase();
    final entity = '${a['entity_type']}'.replaceAll('_', ' ').toLowerCase();
    return '$action $entity';
  }
}
