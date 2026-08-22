import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/phone.dart';
import '../utils/ui.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentRef});

  final String documentRef;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  Map<String, dynamic>? _doc;
  List<dynamic> _versions = [];
  List<dynamic> _shares = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService.instance;
      final results = await Future.wait([
        api.getDocument(widget.documentRef),
        api.listDocumentVersions(widget.documentRef),
        api.listShares(widget.documentRef),
      ]);
      setState(() {
        _doc = results[0];
        _versions = (results[1]['versions'] as List?) ?? [];
        _shares = (results[2]['shares'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _download({String? versionRef}) async {
    try {
      final bytes = versionRef == null
          ? await ApiService.instance.downloadDocument(widget.documentRef)
          : await ApiService.instance
              .downloadDocumentVersion(widget.documentRef, versionRef);
      final dir = await getTemporaryDirectory();
      final name = _doc?['file_name'] ?? 'document.bin';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ErrorHandler.showSuccess(context, 'Saved to ${file.path}');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _delete({required bool hard}) async {
    final reason = await _ask('Delete reason');
    if (reason == null || reason.isEmpty) return;
    try {
      if (hard) {
        await ApiService.instance.hardDeleteDocument(widget.documentRef, reason);
      } else {
        await ApiService.instance.softDeleteDocument(widget.documentRef, reason);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _share() async {
    final mobile = await _ask('Grantee mobile (E.164, e.g. +919876543210)');
    if (mobile == null || mobile.isEmpty) return;
    final e164 = toE164(mobile) ?? mobile;
    try {
      await ApiService.instance.createShare(
        documentRef: widget.documentRef,
        permission: 'VIEW',
        mobile: e164,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _newVersion() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    try {
      await ApiService.instance.updateDocument(
        documentRef: widget.documentRef,
        file: File(result.files.single.path!),
        remarks: 'Updated from app',
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<String?> _ask(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(_doc?['title']?.toString() ?? 'Document'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${_doc?['file_name'] ?? ''}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_doc?['file_type'] ?? ''} · ${_doc?['file_size'] ?? ''} bytes',
                  style: GoogleFonts.inter(color: AppColors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                        onPressed: () => _download(),
                        child: const Text('Download')),
                    ElevatedButton(
                        onPressed: _newVersion, child: const Text('New version')),
                    ElevatedButton(onPressed: _share, child: const Text('Share')),
                    ElevatedButton(
                        onPressed: () => _delete(hard: false),
                        child: const Text('Soft delete')),
                    ElevatedButton(
                        onPressed: () => _delete(hard: true),
                        child: const Text('Hard delete')),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Versions',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ..._versions.map((v) {
                  final map = v as Map;
                  return ListTile(
                    title: Text('v${map['version']} ${map['file_name'] ?? ''}'),
                    subtitle: Text('${map['uploaded_by'] ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _download(
                        versionRef:
                            '${map['document_version_reference_number']}',
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text('Shares',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ..._shares.map((s) {
                  final map = s as Map;
                  return ListTile(
                    title: Text('${map['permission']} · ${map['status']}'),
                    subtitle: Text('${map['grantee_user_reference_number'] ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.block),
                      onPressed: () async {
                        await ApiService.instance.revokeShare(
                          widget.documentRef,
                          '${map['document_share_reference_number']}',
                        );
                        await _load();
                      },
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
