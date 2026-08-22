import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/modules.dart';
import '../utils/ui.dart';
import 'activity_screen.dart';
import 'create_family_screen.dart';
import 'document_detail_screen.dart';
import 'family_screen.dart';
import 'reminders_screen.dart';
import 'subscription_screen.dart';
import 'vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboard;
  Map<String, dynamic>? _user;
  List<dynamic> _families = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ApiService.instance;
    Map<String, dynamic>? dashboard;
    Map<String, dynamic>? user;
    List<dynamic> families = [];
    try {
      user = await api.getUserDetails();
    } catch (_) {}
    try {
      dashboard = await api.getDashboard(familyRef: api.session.familyReferenceNumber);
    } catch (_) {
      dashboard = {};
    }
    try {
      families = ((await api.listMyFamilies())['families'] as List?) ?? [];
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _user = user;
      _dashboard = dashboard;
      _families = families;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _body(),
      ),
    );
  }

  Widget _body() {
    final d = _dashboard ?? {};
    final summary = (d['vault_summary'] as Map?) ?? {};
    final rawModules = supportedHomeModules((d['quick_access'] as List?) ?? []);
    final modules = rawModules.isEmpty ? defaultHomeModules() : rawModules;
    final homeTiles = modules.where((m) => '${m['placement']}' != 'MORE').toList();
    final extras = [
      ...modules.where((m) => '${m['placement']}' == 'MORE'),
      if (homeTiles.length > homeTileLimit) ...homeTiles.sublist(homeTileLimit),
    ];
    final visible = homeTiles.take(homeTileLimit).toList();
    final activity = (d['recent_activity'] as List?) ?? [];
    final hasFamily = _families.isNotEmpty || '${d['family_reference_number'] ?? ''}'.isNotEmpty;
    final first = displayFirstName(_user);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
      children: [
        Text(
          'Welcome back, $first! 👋',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hasFamily
              ? "Your family's legacy is safe and organized."
              : 'Create your family vault to start organizing documents, members, and more.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey, height: 1.35),
        ),
        if (_families.length > 1) ...[
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _currentFamilyRef(),
            decoration: fieldDecoration(hint: 'Family', prefix: Icons.home_outlined),
            items: _families.map((f) {
              final map = f as Map;
              return DropdownMenuItem(
                value: '${map['family_reference_number']}',
                child: Text('${map['family_name']} · ${map['my_role']}'),
              );
            }).toList(),
            onChanged: (ref) async {
              if (ref == null) return;
              await ApiService.instance.session.saveFamily(ref);
              await _load();
            },
          ),
        ],
        if (!hasFamily) ...[
          const SizedBox(height: 16),
          AppCard(
            color: AppColors.bannerBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set up your family vault', style: bodyStyle(weight: FontWeight.w800, size: 16)),
                const SizedBox(height: 6),
                Text(
                  'Invite family later. Start with your own secure space on the Free plan.',
                  style: bodyStyle(size: 13, color: AppColors.grey),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Create family',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateFamilyScreen(asOnboarding: false)),
                    ).then((_) => _load());
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        _sectionHeader(
          'Your Family Vault',
          'View All >',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen())),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(6, 16, 6, 14),
          child: Row(
            children: [
              _vaultStat(Icons.description_outlined, AppColors.sky, '${summary['documents'] ?? d['documents_active'] ?? 0}', 'Documents', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
              }),
              _vaultStat(Icons.people_outline, AppColors.emerald, '${summary['family_members'] ?? d['family_member_count'] ?? 0}', 'Family Members', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen()));
              }),
              _vaultStat(Icons.verified_user_outlined, AppColors.orange, '${summary['secure_items'] ?? 0}', 'Secure Items', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VaultScreen()));
              }),
              _vaultStat(Icons.schedule, AppColors.purple, '${summary['pending_actions'] ?? 0}', 'Pending Actions', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
              }),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _sectionHeader(
          'Quick Access',
          'Customize',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Home tiles follow your family plan. Custom order is coming next.')),
            );
          },
          trailingIcon: Icons.tune,
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: [
            ...visible.map((module) => _quickTile(
                  moduleIcon('${module['module_key']}'),
                  moduleTint('${module['module_key']}'),
                  '${module['title']}',
                  () => openModule(context, module),
                  enabled: module['enabled'] != false,
                )),
            _quickTile(
              Icons.apps,
              AppColors.grey,
              'More',
              () => openMoreModules(context, extras.isEmpty ? visible : extras),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _sectionHeader(
          'Recent Activity',
          'View All >',
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())),
        ),
        const SizedBox(height: 8),
        if (activity.isEmpty)
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.bannerBlue,
                  child: Icon(Icons.history, color: AppColors.sky),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasFamily
                        ? 'No activity yet. Upload a document or invite a family member to get started.'
                        : 'Activity will appear here after you create a family and add your first document.',
                    style: bodyStyle(size: 13, color: AppColors.grey),
                  ),
                ),
              ],
            ),
          )
        else
          ...activity.take(3).map((raw) {
            final item = raw as Map;
            final color = _activityColor('${item['color_key']}');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(_activityIcon('${item['icon_key']}'), color: color),
                  ),
                  title: Text('${item['title']}', style: bodyStyle(weight: FontWeight.w600)),
                  subtitle: Text(relativeTime(item['created_at']), style: bodyStyle(size: 12, color: AppColors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
                  onTap: () {
                    final ref = '${item['entity_reference_number'] ?? ''}';
                    if ('${item['entity_type']}' == 'DOCUMENT' && ref.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentRef: ref)),
                      );
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
                  },
                ),
              ),
            );
          }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bannerBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_outlined, color: AppColors.sky),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Legacy. Our Priority.', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(
                      "We ensure your family's important information remains secure for generations.",
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Learn More', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap, {IconData? trailingIcon}) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.navy)),
        const Spacer(),
        InkWell(
          onTap: onTap,
          child: Row(
            children: [
              if (trailingIcon != null) ...[
                Icon(trailingIcon, size: 15, color: AppColors.sky),
                const SizedBox(width: 4),
              ],
              Text(action, style: GoogleFonts.inter(color: AppColors.sky, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vaultStat(IconData icon, Color color, String value, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.navy)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.grey, fontWeight: FontWeight.w500, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTile(IconData icon, Color color, String label, VoidCallback onTap, {bool enabled = true}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _currentFamilyRef() {
    final current = ApiService.instance.session.familyReferenceNumber;
    final refs = _families.map((f) => '${(f as Map)['family_reference_number']}').toList();
    if (current != null && refs.contains(current)) return current;
    return refs.isEmpty ? null : refs.first;
  }

  Color _activityColor(String key) {
    switch (key) {
      case 'green':
        return AppColors.emerald;
      case 'orange':
        return AppColors.orange;
      case 'purple':
        return AppColors.purple;
      default:
        return AppColors.sky;
    }
  }

  IconData _activityIcon(String key) {
    switch (key) {
      case 'people':
        return Icons.people_outline;
      case 'shield':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
