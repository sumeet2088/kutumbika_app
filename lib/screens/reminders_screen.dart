import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'reminder_form_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  String _filter = 'all';
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listReminders(filter: _filter);
      setState(() {
        _items = (data['reminders'] as List?) ?? [];
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
      appBar: navyAppBar('Reminders'),
      floatingActionButton: AppChromeScope.embedded(context)
          ? null
          : FloatingActionButton(
        backgroundColor: AppColors.primaryDarkBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReminderFormScreen()),
          ).then((_) => _load());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                for (final f in ['all', 'upcoming', 'overdue'])
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
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const EmptyState(message: 'No reminders')
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final item = _items[i] as Map;
                          return ListTile(
                            tileColor: Colors.white,
                            title: Text('${item['title']}'),
                            subtitle: Text(
                              '${item['schedule_label'] ?? ''} · ${item['reminder_date']} ${item['reminder_time']}',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            trailing: item['is_overdue'] == true
                                ? const Icon(Icons.warning, color: Colors.orange)
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReminderFormScreen(
                                    reminderRef:
                                        '${item['reminder_reference_number']}',
                                  ),
                                ),
                              ).then((_) => _load());
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
