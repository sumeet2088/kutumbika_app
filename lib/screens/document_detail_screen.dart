import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/phone.dart';
import '../utils/ui.dart';
import 'document_versions_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentRef});

  final String documentRef;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  Map<String, dynamic>? _doc;
  List<dynamic> _shares = [];
  int _versionCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _title => '${_doc?['title'] ?? _doc?['file_name'] ?? 'Document'}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService.instance;
      final results = await Future.wait([
        api.getDocument(widget.documentRef),
        api.listDocumentVersions(widget.documentRef),
        api.listShares(widget.documentRef),
      ]);
      final versions = (results[1]['versions'] as List?) ?? [];
      setState(() {
        _doc = results[0];
        _versionCount = versions.length;
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

  Future<void> _openVersions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentVersionsScreen(
          documentRef: widget.documentRef,
          documentTitle: _title,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _download() async {
    try {
      final bytes = await ApiService.instance.downloadDocument(widget.documentRef);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share document'),
        content: Text(
          'You are about to share “$_title” with $e164. They will be able to view this document.\n\nThis file may contain personal information. Confirm you have the right to share it.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Share')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.instance.createShare(
        documentRef: widget.documentRef,
        permission: 'VIEW',
        mobile: e164,
      );
      await _load();
      if (mounted) ErrorHandler.showSuccess(context, 'Document shared');
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
      if (mounted) ErrorHandler.showSuccess(context, 'New version uploaded');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _askAbout() async {
    final question = await _ask('Ask about this document');
    if (question == null || question.trim().isEmpty) return;
    try {
      final data = await ApiService.instance.askRAG(
        question: question.trim(),
        familyRef: ApiService.instance.session.familyReferenceNumber,
        documentRef: widget.documentRef,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Vault answer'),
          content: SingleChildScrollView(
            child: Text('${data['answer'] ?? ''}'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = categoryLook(_title);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(
        'Document',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'version') _newVersion();
              if (value == 'soft') _delete(hard: false);
              if (value == 'hard') _delete(hard: true);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'version', child: Text('Upload new version')),
              PopupMenuItem(value: 'soft', child: Text('Move to trash')),
              PopupMenuItem(value: 'hard', child: Text('Delete permanently')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: pagePadding(context, horizontal: 16, top: 8),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        AppIconBadge(icon: look.$1, color: look.$2, size: 64, iconSize: 32),
                        const SizedBox(height: 12),
                        Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: bodyStyle(weight: FontWeight.w800, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_fileKind(_doc?['file_type'])} · ${bytesLabel(_doc?['file_size'] ?? 0)}',
                          style: bodyStyle(size: 13, color: AppColors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _action(Icons.download_rounded, AppColors.sky, 'Download', _download),
                      _action(Icons.ios_share_rounded, AppColors.teal, 'Share', _share),
                      _action(Icons.history_rounded, AppColors.orange, 'Versions', _openVersions),
                      _action(Icons.auto_awesome_rounded, AppColors.purple, 'Ask AI', _askAbout),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      children: [
                        _meta('Added', formatDisplayDate(_doc?['created_at'])),
                        _meta('Current version', 'v${_doc?['current_version'] ?? 1}'),
                        _meta('File type', _fileKind(_doc?['file_type'])),
                        _meta('Size', bytesLabel(_doc?['file_size'] ?? 0)),
                        _meta('OCR', _ocrLabel(), last: _doc?['expiry_date'] == null),
                        if (_doc?['expiry_date'] != null)
                          _meta('Expiry', formatDisplayDate(_doc?['expiry_date']), last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: const AppIconBadge(
                        icon: Icons.history_edu_rounded,
                        color: AppColors.orange,
                      ),
                      title: Text('Versions', style: bodyStyle(weight: FontWeight.w700)),
                      subtitle: Text(
                        _versionCount == 0
                            ? 'No history yet'
                            : '$_versionCount version${_versionCount == 1 ? '' : 's'} · filter by date or order',
                        style: bodyStyle(size: 12, color: AppColors.grey),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey),
                      onTap: _openVersions,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Shares', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                  const SizedBox(height: 8),
                  if (_shares.isEmpty)
                    AppCard(
                      child: Text(
                        'Not shared with anyone yet.',
                        style: bodyStyle(color: AppColors.grey),
                      ),
                    )
                  else
                    ..._shares.map((share) {
                      final map = share as Map;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const AppIconBadge(
                              icon: Icons.group_rounded,
                              color: AppColors.emerald,
                            ),
                            title: Text(
                              '${map['permission'] ?? 'VIEW'} · ${map['status'] ?? ''}',
                              style: bodyStyle(weight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              shortUserRef(map['grantee_user_reference_number']),
                              style: bodyStyle(size: 12, color: AppColors.grey),
                            ),
                            trailing: IconButton(
                              tooltip: 'Revoke',
                              icon: const Icon(Icons.block_rounded, color: AppColors.error),
                              onPressed: () async {
                                try {
                                  await ApiService.instance.revokeShare(
                                    widget.documentRef,
                                    '${map['document_share_reference_number']}',
                                  );
                                  await _load();
                                } catch (e) {
                                  if (mounted) {
                                    ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  String _fileKind(dynamic type) {
    final raw = '${type ?? ''}'.toLowerCase();
    if (raw.contains('pdf')) return 'PDF';
    if (raw.contains('jpeg') || raw.contains('jpg')) return 'JPEG';
    if (raw.contains('png')) return 'PNG';
    if (raw.contains('webp')) return 'WebP';
    if (raw.isEmpty) return 'File';
    return raw.split('/').last.toUpperCase();
  }

  String _ocrLabel() {
    final status = '${_doc?['ocr_status'] ?? 'PENDING'}';
    final chunks = (_doc?['indexed_chunks'] as num?)?.toInt() ?? 0;
    if (status.toUpperCase() == 'COMPLETED') {
      return chunks > 0 ? 'Ready · $chunks searchable parts' : 'Completed';
    }
    return status;
  }

  Widget _action(IconData icon, Color color, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              AppIconBadge(icon: icon, color: color, size: 46, iconSize: 22),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle(size: 12, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(String label, String value, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: bodyStyle(size: 13, color: AppColors.grey)),
          ),
          Expanded(
            child: Text(value, style: bodyStyle(weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
