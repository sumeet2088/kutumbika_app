import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'reminder_form_screen.dart';
import 'reminders_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<dynamic> _notifications = [];
  List<dynamic> _reminders = [];
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
        ApiService.instance.listNotifications(filter: 'all'),
        ApiService.instance.listReminders(filter: 'upcoming'),
      ]);
      setState(() {
        _notifications = (results[0]['notifications'] as List?) ?? [];
        _reminders = (results[1]['reminders'] as List?) ?? [];
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: pagePadding(context, horizontal: 20, top: 8),
                children: [
                  Row(
                    children: [
                      Text('Alerts', style: headingStyle(size: 22)),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          await ApiService.instance.markAllNotificationsRead();
                          await _load();
                        },
                        child: const Text('Read all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_notifications.isEmpty)
                    AppCard(child: Text('No notifications yet', style: bodyStyle(color: AppColors.grey)))
                  else
                    ..._notifications.map((n) {
                      final map = n as Map;
                      final read = map['read'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: read ? AppColors.lightGrey : AppColors.bannerBlue,
                              child: Icon(
                                read ? Icons.notifications_none : Icons.notifications_active,
                                color: AppColors.sky,
                              ),
                            ),
                            title: Text('${map['title'] ?? map['type']}', style: bodyStyle(weight: FontWeight.w700)),
                            subtitle: Text(
                              '${map['message'] ?? ''}\n${relativeTime(map['created_at'] ?? map['sent_at'])}',
                              style: bodyStyle(size: 12, color: AppColors.grey),
                            ),
                            onTap: () async {
                              final id = map['id'];
                              if (id is int) {
                                await ApiService.instance.markNotificationRead(id);
                                await _load();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Upcoming reminders', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
                        },
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  if (_reminders.isEmpty)
                    AppCard(child: Text('No upcoming reminders', style: bodyStyle(color: AppColors.grey)))
                  else
                    ..._reminders.take(5).map((r) {
                      final map = r as Map;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFFE8E8),
                              child: Icon(Icons.alarm, color: AppColors.error),
                            ),
                            title: Text('${map['title']}', style: bodyStyle(weight: FontWeight.w700)),
                            subtitle: Text('${map['reminder_date'] ?? ''} ${map['reminder_time'] ?? ''}'),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderFormScreen()))
                                  .then((_) => _load());
                            },
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
