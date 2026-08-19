import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
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
  bool _loading = true;
  String? _error;

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
      final data = await ApiService.instance.listDocuments();
      setState(() {
        _docs = (data['documents'] as List?) ?? [];
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
      appBar: AppBar(
        title: const Text('Vault'),
        backgroundColor: AppColors.logoBlack,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DeletedDocumentsScreen()),
              ).then((_) => _load());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryDarkBlue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
          ).then((_) => _load());
        },
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [EmptyState(message: _error!)])
                : _docs.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(message: 'No documents yet. Upload one.'),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final doc = _docs[i] as Map;
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            leading: const Icon(Icons.insert_drive_file,
                                color: AppColors.secondaryBlue),
                            title: Text(
                              '${doc['title'] ?? doc['file_name'] ?? 'Document'}',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${doc['file_type'] ?? ''}  ${doc['file_size'] ?? ''} bytes',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppColors.grey),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentDetailScreen(
                                    documentRef:
                                        '${doc['document_reference_number']}',
                                  ),
                                ),
                              ).then((_) => _load());
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
