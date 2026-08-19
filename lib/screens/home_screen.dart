import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import '../widgets/app_logo.dart';
import 'notifications_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboard;
  List<dynamic> _categories = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService.instance;
      final results = await Future.wait([
        api.getDashboard(familyRef: api.session.familyReferenceNumber),
        api.listCategories(),
      ]);
      setState(() {
        _dashboard = results[0];
        _categories = (results[1]['categories'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _body(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      color: AppColors.logoBlack,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
          child: Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppLogo(height: 72),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  );
                },
                icon: const Icon(Icons.notifications_none,
                    color: AppColors.goldYellow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(message: _error!, icon: Icons.error_outline),
        ],
      );
    }
    final d = _dashboard ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDarkBlue,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _stat('Documents', '${d['documents_active'] ?? 0}', Icons.folder),
            _stat('Upcoming', '${d['reminders_upcoming'] ?? 0}', Icons.alarm),
            _stat('Overdue', '${d['reminders_overdue'] ?? 0}', Icons.warning),
            _stat('Unread', '${d['notifications_unread'] ?? 0}',
                Icons.notifications),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Document categories',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDarkBlue,
          ),
        ),
        const SizedBox(height: 12),
        if (_categories.isEmpty)
          const EmptyState(message: 'No categories yet')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (context, i) {
              final cat = _categories[i] as Map;
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VaultScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.description,
                          color: AppColors.secondaryBlue),
                      const Spacer(),
                      Text(
                        '${cat['document_name'] ?? 'Category'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDarkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 44) / 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.goldYellow),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDarkBlue)),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
