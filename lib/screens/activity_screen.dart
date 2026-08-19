import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      final data = await ApiService.instance.getUserActivity();
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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Activity'),
        backgroundColor: AppColors.logoBlack,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(message: 'No activity yet')
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final a = _items[i] as Map;
                    return ListTile(
                      title: Text('${a['action']} ${a['entity_type']}'),
                      subtitle: Text(
                        '${a['created_at'] ?? ''}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    );
                  },
                ),
    );
  }
}
