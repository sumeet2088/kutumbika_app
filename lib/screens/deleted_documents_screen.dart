import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class DeletedDocumentsScreen extends StatefulWidget {
  const DeletedDocumentsScreen({super.key});

  @override
  State<DeletedDocumentsScreen> createState() => _DeletedDocumentsScreenState();
}

class _DeletedDocumentsScreenState extends State<DeletedDocumentsScreen> {
  List<dynamic> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listDeletedDocuments();
      setState(() {
        _docs = (data['documents'] as List?) ?? [];
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
        title: const Text('Deleted documents'),
        backgroundColor: AppColors.logoBlack,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? const EmptyState(message: 'Nothing in the recycle bin')
              : ListView.builder(
                  itemCount: _docs.length,
                  itemBuilder: (context, i) {
                    final doc = _docs[i] as Map;
                    return ListTile(
                      title: Text('${doc['title'] ?? doc['file_name']}'),
                      subtitle: Text(
                        'Deleted ${doc['deleted_at'] ?? ''}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: doc['can_restore'] == true
                          ? TextButton(
                              onPressed: () async {
                                await ApiService.instance.restoreDocument(
                                  '${doc['document_reference_number']}',
                                );
                                await _load();
                              },
                              child: const Text('Restore'),
                            )
                          : null,
                    );
                  },
                ),
    );
  }
}
