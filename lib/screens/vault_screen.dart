import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/layout.dart';
import '../utils/ui.dart';
import 'category_documents_screen.dart';
import 'deleted_documents_screen.dart';
import 'document_detail_screen.dart';
import 'upload_document_screen.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<dynamic> _docs = [];
  List<dynamic> _categories = [];
  Map<String, dynamic>? _subscription;
  bool _loading = true;
  String? _error;
  String _query = '';

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
        api.listDocuments(familyRef: api.session.familyReferenceNumber),
        api.listCategories(),
        api.getSubscription(familyRef: api.session.familyReferenceNumber),
      ]);
      setState(() {
        _docs = (results[0]['documents'] as List?) ?? [];
        _categories = (results[1]['categories'] as List?) ?? [];
        _subscription = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getErrorMessage(e);
        _loading = false;
      });
    }
  }

  int _countFor(String categoryRef) {
    return _docs.where((d) => '${(d as Map)['document_category_reference_number']}' == categoryRef).length;
  }

  @override
  Widget build(BuildContext context) {
    final usage = (_subscription?['usage'] as Map?) ?? {};
    final plan = (_subscription?['plan'] as Map?) ?? {};
    final used = (usage['storage_used_bytes'] ?? 0) as num;
    final limitGb = (plan['storage_limit_gb'] ?? 0) as num;
    final limitBytes = limitGb * 1024 * 1024 * 1024;
    final progress = limitBytes <= 0 ? 0.0 : (used / limitBytes).clamp(0, 1).toDouble();
    final canUpload = ((_subscription?['restrictions'] as Map?)?['can_upload_documents'] ?? true) == true;
    final filteredCats = _categories.where((c) {
      if (_query.isEmpty) return true;
      return '${c['document_name']}'.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(
        'My Vault',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DeletedDocumentsScreen()))
                  .then((_) => _load());
            },
          ),
        ],
      ),
      floatingActionButton: AppChromeScope.embedded(context)
          ? null
          : FloatingActionButton(
        backgroundColor: AppColors.navy,
        onPressed: () {
          if (!canUpload) {
            ErrorHandler.showError(context, 'Uploads are not allowed on the current plan or role.');
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadDocumentScreen()))
              .then((_) => _load());
        },
        child: const Icon(Icons.add, color: AppColors.gold),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : _error != null
                ? ListView(children: [EmptyState(message: _error!)])
                : ListView(
                    padding: pagePadding(context, horizontal: 16, top: 12),
                    children: [
                      AppCard(
                        color: AppColors.navy,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Storage', style: bodyStyle(color: AppColors.gold, weight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              '${bytesLabel(used)} / ${limitGb.toStringAsFixed(0)} GB',
                              style: bodyStyle(color: Colors.white, weight: FontWeight.w700, size: 18),
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.gold,
                              backgroundColor: Colors.white24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${usage['document_count'] ?? _docs.length} documents  ·  ${canUpload ? 'Uploads allowed' : 'Uploads blocked'}',
                              style: bodyStyle(color: Colors.white70, size: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: fieldDecoration(
                          hint: 'Search categories or documents',
                          prefix: Icons.search_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (filteredCats.isEmpty)
                        const EmptyState(message: 'No categories yet')
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredCats.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: AppLayout.of(context).vaultColumns,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 76,
                          ),
                          itemBuilder: (context, i) {
                            final cat = filteredCats[i] as Map;
                            final ref = '${cat['document_category_reference_number']}';
                            final name = '${cat['document_name']}';
                            final look = categoryLook(name);
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CategoryDocumentsScreen(
                                      categoryRef: ref,
                                      categoryName: name,
                                    ),
                                  ),
                                ).then((_) => _load());
                              },
                              child: AppCard(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    AppIconBadge(icon: look.$1, color: look.$2, size: 36, iconSize: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: bodyStyle(weight: FontWeight.w800, size: 14),
                                          ),
                                          Text(
                                            '${_countFor(ref)} files',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: bodyStyle(size: 11, color: AppColors.grey, weight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      Text('Recent documents', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                      const SizedBox(height: 8),
                      if (_docs.isEmpty)
                        const EmptyState(message: 'No documents yet. Upload one.')
                      else
                        ..._docs.take(8).map((doc) {
                          final map = doc as Map;
                          final title = '${map['title'] ?? map['file_name']}';
                          final look = categoryLook(title);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: AppIconBadge(icon: look.$1, color: look.$2, size: 40, iconSize: 20),
                            title: Text(title, style: bodyStyle(weight: FontWeight.w600)),
                            subtitle: Text(bytesLabel(map['file_size'] ?? 0), style: bodyStyle(size: 12, color: AppColors.grey)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentDetailScreen(
                                    documentRef: '${map['document_reference_number']}',
                                  ),
                                ),
                              ).then((_) => _load());
                            },
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
