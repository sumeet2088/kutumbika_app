import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/layout.dart';
import '../utils/ui.dart';
import 'category_documents_screen.dart';
import 'document_detail_screen.dart';
import 'family_screen.dart';
import 'insurance_screen.dart';
import 'module_placeholder_screen.dart';
import 'reminders_screen.dart';
import 'vehicle_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _askController = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;
  int _tab = 0;
  bool _asking = false;
  Map<String, dynamic>? _answer;
  Map<String, dynamic>? _usage;
  String? _askError;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _askController.dispose();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    try {
      final data = await ApiService.instance.ragUsage(
        familyRef: ApiService.instance.session.familyReferenceNumber,
      );
      if (mounted) setState(() => _usage = data);
    } catch (_) {}
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.instance.searchVault(
        query: q,
        familyRef: ApiService.instance.session.familyReferenceNumber,
      );
      setState(() {
        _results = (data['results'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _ask() async {
    final q = _askController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _asking = true;
      _askError = null;
    });
    try {
      final data = await ApiService.instance.askRAG(
        question: q,
        familyRef: ApiService.instance.session.familyReferenceNumber,
      );
      setState(() {
        _answer = data;
        _asking = false;
        _usage = {
          'questions_used': data['questions_used'],
          'question_limit': data['question_limit'],
          'questions_remaining': data['questions_remaining'],
          'ocr_enabled': _usage?['ocr_enabled'],
        };
      });
    } catch (e) {
      setState(() {
        _askError = ErrorHandler.getErrorMessage(e);
        _asking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(AppLayout.of(context).contentInset(), 8, AppLayout.of(context).contentInset(), 0),
            child: Row(
              children: [
                Expanded(child: _tabChip(0, 'Search', Icons.search)),
                const SizedBox(width: 8),
                Expanded(child: _tabChip(1, 'Ask AI', Icons.auto_awesome_outlined)),
              ],
            ),
          ),
          Expanded(child: _tab == 0 ? _searchTab() : _askTab()),
        ],
      ),
    );
  }

  Widget _tabChip(int index, String label, IconData icon) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.navy : AppColors.navy.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.gold : AppColors.navy),
            const SizedBox(width: 6),
            Text(
              label,
              style: bodyStyle(
                weight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(AppLayout.of(context).contentInset(), 12, AppLayout.of(context).contentInset(), 12),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: fieldDecoration(
              hint: 'Search documents, family, insurance...',
              prefix: Icons.search,
            ),
          ),
        ),
        Expanded(child: _searchBody()),
      ],
    );
  }

  Widget _searchBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) {
      return EmptyState(message: _error!, icon: Icons.error_outline);
    }
    if (_searchController.text.trim().isEmpty) {
      return const EmptyState(
        message: 'Search your family vault by name, document, or policy.',
        icon: Icons.search,
      );
    }
    if (_results.isEmpty) {
      return const EmptyState(message: 'No matches in this family vault');
    }
    return ListView.separated(
      padding: pagePadding(context, horizontal: 20, top: 0),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = _results[i] as Map;
        return AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.bannerBlue,
              child: Icon(_icon('${item['icon_key']}'), color: AppColors.sky),
            ),
            title: Text('${item['title']}', style: bodyStyle(weight: FontWeight.w700)),
            subtitle: Text(
              '${item['subtitle'] ?? item['kind'] ?? ''}',
              style: bodyStyle(size: 12, color: AppColors.grey),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(item),
          ),
        );
      },
    );
  }

  Widget _askTab() {
    final used = _usage?['questions_used'] ?? 0;
    final limit = _usage?['question_limit'] ?? 5;
    final remaining = _usage?['questions_remaining'] ?? (limit - used);
    return ListView(
      padding: pagePadding(context, horizontal: 20, top: 12),
      children: [
        Text(
          '$used / $limit AI questions this month  ·  $remaining left',
          style: bodyStyle(size: 12, color: AppColors.grey),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _askController,
          minLines: 2,
          maxLines: 4,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _ask(),
          decoration: fieldDecoration(
            hint: 'When does my vehicle insurance expire?',
            prefix: Icons.auto_awesome_outlined,
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _asking ? 'Searching vault…' : 'Ask the family vault',
          loading: _asking,
          onPressed: _asking ? null : _ask,
        ),
        if (_askError != null) ...[
          const SizedBox(height: 16),
          EmptyState(message: _askError!, icon: Icons.error_outline),
        ],
        if (_answer != null) ...[
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Answer', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                const SizedBox(height: 8),
                Text('${_answer!['answer']}', style: bodyStyle()),
                const SizedBox(height: 8),
                Text(
                  'Provider: ${_answer!['provider'] ?? 'local'}',
                  style: bodyStyle(size: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
          ...((_answer!['sources'] as List?) ?? []).map((s) {
            final map = s as Map;
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined, color: AppColors.navy),
                  title: Text(
                    '${map['title'] ?? 'Document'}',
                    style: bodyStyle(weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${map['snippet'] ?? ''}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(size: 12, color: AppColors.grey),
                  ),
                  onTap: () {
                    final ref = '${map['document_reference_number'] ?? ''}';
                    if (ref.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentRef: ref)),
                    );
                  },
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  IconData _icon(String key) {
    switch (key) {
      case 'people':
        return Icons.people_outline;
      case 'folder':
        return Icons.folder_outlined;
      case 'shield':
        return Icons.health_and_safety_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'note':
        return Icons.sticky_note_2_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'alarm':
        return Icons.alarm_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  void _open(Map item) {
    final kind = '${item['kind']}';
    final ref = '${item['reference_number']}';
    Widget dest;
    switch (kind) {
      case 'document':
        dest = DocumentDetailScreen(documentRef: ref);
        break;
      case 'category':
        dest = CategoryDocumentsScreen(categoryRef: ref, categoryName: '${item['title']}');
        break;
      case 'member':
        dest = const FamilyScreen();
        break;
      case 'insurance':
        dest = const InsuranceScreen();
        break;
      case 'vehicle':
        dest = const VehicleScreen();
        break;
      case 'reminder':
        dest = const RemindersScreen();
        break;
      default:
        dest = ModulePlaceholderScreen(title: '${item['title']}');
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => dest));
  }
}
