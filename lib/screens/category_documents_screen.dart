import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'document_detail_screen.dart';
import 'upload_document_screen.dart';

class CategoryDocumentsScreen extends StatefulWidget {
  const CategoryDocumentsScreen({
    super.key,
    required this.categoryRef,
    required this.categoryName,
  });

  final String categoryRef;
  final String categoryName;

  @override
  State<CategoryDocumentsScreen> createState() => _CategoryDocumentsScreenState();
}

class _CategoryDocumentsScreenState extends State<CategoryDocumentsScreen> {
  List<dynamic> _docs = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService.instance;
      final data = await api.listDocuments(familyRef: api.session.familyReferenceNumber);
      final all = (data['documents'] as List?) ?? [];
      setState(() {
        _docs = all.where((d) {
          final map = d as Map;
          return '${map['document_category_reference_number']}' == widget.categoryRef;
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _docs.where((d) {
      if (_query.isEmpty) return true;
      final map = d as Map;
      return '${map['title'] ?? map['file_name']}'.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(widget.categoryName),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadDocumentScreen()))
              .then((_) => _load());
        },
        icon: const Icon(Icons.upload_file, color: AppColors.gold),
        label: const Text('Upload', style: TextStyle(color: AppColors.gold)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: pagePadding(context, horizontal: 16, top: 12),
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: fieldDecoration(hint: 'Search in ${widget.categoryName}', prefix: Icons.search),
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const EmptyState(message: 'No documents in this category yet')
                  else
                    ...visible.map((d) {
                      final map = d as Map;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.picture_as_pdf, color: AppColors.navy),
                            title: Text('${map['title'] ?? map['file_name'] ?? 'Document'}',
                                style: bodyStyle(weight: FontWeight.w600)),
                            subtitle: Text(
                              '${map['file_type'] ?? 'FILE'} · ${bytesLabel(map['file_size'] ?? 0)}',
                              style: bodyStyle(size: 12, color: AppColors.grey),
                            ),
                            trailing: const Icon(Icons.more_vert),
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
