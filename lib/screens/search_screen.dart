import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
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
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              autofocus: false,
              decoration: fieldDecoration(
                hint: 'Search documents, family, insurance...',
                prefix: Icons.search,
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) {
      return EmptyState(message: _error!, icon: Icons.error_outline);
    }
    if (_controller.text.trim().isEmpty) {
      return const EmptyState(
        message: 'Search your family vault by name, document, or policy.',
        icon: Icons.search,
      );
    }
    if (_results.isEmpty) {
      return const EmptyState(message: 'No matches in this family vault');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
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
