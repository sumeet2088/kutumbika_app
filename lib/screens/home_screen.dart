import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import '../widgets/app_logo.dart';
import 'category_documents_screen.dart';
import 'family_screen.dart';
import 'notifications_screen.dart';
import 'reminders_screen.dart';
import 'subscription_screen.dart';
import 'upload_document_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _subscription;
  List<dynamic> _categories = [];
  List<dynamic> _reminders = [];
  String _query = '';
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
        api.getUserDetails(),
        api.listCategories(),
        api.listReminders(filter: 'upcoming'),
        api.getSubscription(),
      ]);
      setState(() {
        _dashboard = results[0];
        _user = results[1];
        _categories = (results[2]['categories'] as List?) ?? [];
        _reminders = (results[3]['reminders'] as List?) ?? [];
        _subscription = results[4];
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
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _body(),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(message: _error!, icon: Icons.error_outline),
        ],
      );
    }
    final d = _dashboard ?? {};
    final usage = (_subscription?['usage'] as Map?) ?? {};
    final filtered = _categories.where((c) {
      if (_query.isEmpty) return true;
      return '${c['document_name']}'.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    final unread = d['notifications_unread'] ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, ${displayName(_user)}', style: headingStyle(size: 24)),
                  Text('Welcome to Paarisetu', style: bodyStyle(color: AppColors.grey)),
                ],
              ),
            ),
            const AppLogo(kind: LogoKind.icon, height: 42),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
              icon: Badge(
                isLabelVisible: unread is int && unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_none, color: AppColors.navy),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: fieldDecoration(hint: 'Search documents, categories...', prefix: Icons.search),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _navyStat(Icons.description_outlined, '${d['documents_active'] ?? 0}', 'Documents'),
              _navyStat(Icons.groups_outlined, '${d['family_member_count'] ?? 0}', 'Family'),
              _navyStat(
                Icons.cloud_outlined,
                bytesLabel(usage['storage_used_bytes'] ?? 0),
                'Storage used',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            _tile(Icons.lock_outline, 'Vault', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
            }),
            _tile(Icons.people_outline, 'Family', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()));
            }),
            _tile(Icons.workspace_premium_outlined, 'Plan', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            }),
            _tile(Icons.medical_services_outlined, 'Medical', () => _openCategory('Medical')),
            _tile(Icons.shield_outlined, 'Insurance', () => _openCategory('Insurance')),
            _tile(Icons.more_horiz, 'More', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
            }),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Notifications & Reminders', style: bodyStyle(weight: FontWeight.w700, size: 16)),
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
          ..._reminders.take(3).map((r) {
            final map = r as Map;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E8),
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: const Icon(Icons.warning_amber, color: AppColors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${map['title']}', style: bodyStyle(weight: FontWeight.w700)),
                          Text('${map['reminder_date'] ?? ''}', style: bodyStyle(size: 12, color: AppColors.error)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8E8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Urgent', style: bodyStyle(size: 11, color: AppColors.error, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        Text('Categories', style: bodyStyle(weight: FontWeight.w700, size: 16)),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const EmptyState(message: 'No categories yet')
        else
          ...filtered.map((cat) {
            final map = cat as Map;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.navy,
                child: Icon(Icons.folder_outlined, color: AppColors.gold),
              ),
              title: Text('${map['document_name']}', style: bodyStyle(weight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDocumentsScreen(
                      categoryRef: '${map['document_category_reference_number']}',
                      categoryName: '${map['document_name']}',
                    ),
                  ),
                );
              },
            );
          }),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Upload Document',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadDocumentScreen()));
          },
        ),
      ],
    );
  }

  void _openCategory(String name) {
    for (final cat in _categories) {
      final map = cat as Map;
      if ('${map['document_name']}'.toLowerCase().contains(name.toLowerCase())) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDocumentsScreen(
              categoryRef: '${map['document_category_reference_number']}',
              categoryName: '${map['document_name']}',
            ),
          ),
        );
        return;
      }
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
  }

  Widget _navyStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.navy, size: 28),
            const SizedBox(height: 8),
            Text(label, style: bodyStyle(size: 12, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
