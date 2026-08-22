import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await ApiService.instance.listNotifications(filter: _filter);
      setState(() {
        _items = (data['notifications'] as List?) ?? [];
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
      appBar: navyAppBar(
        'Notifications',
        actions: [
          TextButton(
            onPressed: () async {
              await ApiService.instance.markAllNotificationsRead();
              await _load();
            },
            child: const Text('Read all', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final f in ['all', 'unread'])
                ChoiceChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) {
                    setState(() => _filter = f);
                    _load();
                  },
                ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const EmptyState(message: 'No notifications')
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final n = _items[i] as Map;
                          return ListTile(
                            leading: Icon(
                              n['read'] == true
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: AppColors.goldYellow,
                            ),
                            title: Text('${n['title'] ?? n['type']}'),
                            subtitle: Text(
                              '${n['message'] ?? ''}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            onTap: () async {
                              final id = n['id'];
                              if (id is int) {
                                await ApiService.instance
                                    .markNotificationRead(id);
                                await _load();
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
