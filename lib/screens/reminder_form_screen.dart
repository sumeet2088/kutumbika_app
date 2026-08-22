import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class ReminderFormScreen extends StatefulWidget {
  const ReminderFormScreen({super.key, this.reminderRef});

  final String? reminderRef;

  @override
  State<ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<ReminderFormScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  String _repeat = 'NONE';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.reminderRef != null) _load();
  }

  Future<void> _load() async {
    final data = await ApiService.instance.getReminder(widget.reminderRef!);
    _title.text = '${data['title'] ?? ''}';
    _notes.text = '${data['notes'] ?? ''}';
    _repeat = '${data['repeat_type'] ?? 'NONE'}';
    final date = DateTime.tryParse('${data['reminder_date']}');
    if (date != null) _date = date;
    final parts = '${data['reminder_time'] ?? '09:00'}'.split(':');
    if (parts.length >= 2) {
      _time = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final date = DateFormat('yyyy-MM-dd').format(_date);
      final time =
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
      if (widget.reminderRef == null) {
        await ApiService.instance.createReminder(
          title: _title.text,
          reminderDate: date,
          reminderTime: time,
          repeatType: _repeat,
          notes: _notes.text.isEmpty ? null : _notes.text,
        );
      } else {
        await ApiService.instance.updateReminder(widget.reminderRef!, {
          'title': _title.text,
          'reminder_date': date,
          'reminder_time': time,
          'repeat_type': _repeat,
          'notes': _notes.text,
        });
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.reminderRef == null) return;
    await ApiService.instance.deleteReminder(widget.reminderRef!);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(
        widget.reminderRef == null ? 'New reminder' : 'Reminder',
        actions: [
          if (widget.reminderRef != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: ListView(
        padding: pagePadding(context, horizontal: 24, top: 16),
        children: [
          AppTextField(controller: _title, label: 'Title', prefix: Icons.notifications_active_rounded),
          const SizedBox(height: 14),
          AppDateField(
            label: 'Date',
            value: _date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            onPicked: (picked) => setState(() => _date = picked),
          ),
          const SizedBox(height: 14),
          AppTimeField(
            label: 'Time',
            value: _time,
            onPicked: (picked) => setState(() => _time = picked),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _repeat,
            decoration: fieldDecoration(label: 'Repeat', prefix: Icons.repeat_rounded),
            items: const [
              DropdownMenuItem(value: 'NONE', child: Text('Does not repeat')),
              DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
              DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
              DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
              DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
            ],
            onChanged: (v) => setState(() => _repeat = v ?? 'NONE'),
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _notes,
            label: 'Notes',
            prefix: Icons.notes_rounded,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save', loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}
