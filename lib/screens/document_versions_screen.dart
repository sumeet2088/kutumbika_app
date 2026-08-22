import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

enum _VersionFilter { all, date, range }

enum _VersionOrder { newest, oldest, versionHigh, versionLow }

class DocumentVersionsScreen extends StatefulWidget {
  const DocumentVersionsScreen({
    super.key,
    required this.documentRef,
    this.documentTitle,
  });

  final String documentRef;
  final String? documentTitle;

  @override
  State<DocumentVersionsScreen> createState() => _DocumentVersionsScreenState();
}

class _DocumentVersionsScreenState extends State<DocumentVersionsScreen> {
  List<Map<String, dynamic>> _versions = [];
  bool _loading = true;
  _VersionFilter _filter = _VersionFilter.all;
  _VersionOrder _order = _VersionOrder.newest;
  DateTime? _onDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.listDocumentVersions(widget.documentRef);
      final rows = (data['versions'] as List?) ?? [];
      setState(() {
        _versions = rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  List<Map<String, dynamic>> get _visible {
    var rows = List<Map<String, dynamic>>.from(_versions);
    if (_filter == _VersionFilter.date && _onDate != null) {
      rows = rows.where((row) {
        final created = parseAppDate(row['created_at']);
        return created != null && _sameDay(created, _onDate!);
      }).toList();
    }
    if (_filter == _VersionFilter.range && _rangeStart != null && _rangeEnd != null) {
      final start = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
      final end = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);
      rows = rows.where((row) {
        final created = parseAppDate(row['created_at']);
        if (created == null) return false;
        final day = DateTime(created.year, created.month, created.day);
        return !day.isBefore(start) && !day.isAfter(end);
      }).toList();
    }
    rows.sort((a, b) {
      final aDate = parseAppDate(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = parseAppDate(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final aVer = (a['version'] as num?)?.toInt() ?? 0;
      final bVer = (b['version'] as num?)?.toInt() ?? 0;
      switch (_order) {
        case _VersionOrder.oldest:
          return aDate.compareTo(bDate);
        case _VersionOrder.versionHigh:
          return bVer.compareTo(aVer);
        case _VersionOrder.versionLow:
          return aVer.compareTo(bVer);
        case _VersionOrder.newest:
          return bDate.compareTo(aDate);
      }
    });
    return rows;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _download(Map<String, dynamic> version) async {
    try {
      final bytes = await ApiService.instance.downloadDocumentVersion(
        widget.documentRef,
        '${version['document_version_reference_number']}',
      );
      final dir = await getTemporaryDirectory();
      final name = '${version['file_name'] ?? 'document-v${version['version']}.bin'}';
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
      if (mounted) {
        ErrorHandler.showSuccess(context, 'New version uploaded');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  void _setFilter(_VersionFilter filter) {
    setState(() => _filter = filter);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.documentTitle?.trim().isNotEmpty == true
        ? widget.documentTitle!
        : 'Document versions';
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(
        'Versions',
        actions: [
          IconButton(
            tooltip: 'Upload new version',
            onPressed: _newVersion,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: pagePadding(context, horizontal: 16, top: 8),
                children: [
                  Text(title, style: bodyStyle(weight: FontWeight.w800, size: 20)),
                  const SizedBox(height: 4),
                  Text(
                    '${_versions.length} version${_versions.length == 1 ? '' : 's'} in this file',
                    style: bodyStyle(size: 13, color: AppColors.grey),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip('All', _VersionFilter.all),
                        _chip('Date', _VersionFilter.date),
                        _chip('Date range', _VersionFilter.range),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filter == _VersionFilter.date)
                    AppDateField(
                      label: 'On date',
                      value: _onDate,
                      lastDate: DateTime.now(),
                      onPicked: (date) => setState(() => _onDate = date),
                    ),
                  if (_filter == _VersionFilter.range) ...[
                    AppDateField(
                      label: 'From',
                      value: _rangeStart,
                      lastDate: DateTime.now(),
                      onPicked: (date) => setState(() {
                        _rangeStart = date;
                        if (_rangeEnd != null && _rangeEnd!.isBefore(date)) {
                          _rangeEnd = date;
                        }
                      }),
                    ),
                    const SizedBox(height: 10),
                    AppDateField(
                      label: 'To',
                      value: _rangeEnd,
                      firstDate: _rangeStart,
                      lastDate: DateTime.now(),
                      onPicked: (date) => setState(() => _rangeEnd = date),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_filter == _VersionFilter.date) const SizedBox(height: 12),
                  Text('Order', style: bodyStyle(weight: FontWeight.w700, size: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _orderChip('Newest first', _VersionOrder.newest),
                      _orderChip('Oldest first', _VersionOrder.oldest),
                      _orderChip('Version high–low', _VersionOrder.versionHigh),
                      _orderChip('Version low–high', _VersionOrder.versionLow),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const EmptyState(
                      icon: Icons.history_rounded,
                      message: 'No versions match this filter.',
                    )
                  else
                    ...visible.map(_versionCard),
                ],
              ),
      ),
    );
  }

  Widget _chip(String label, _VersionFilter value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _setFilter(value),
        selectedColor: AppColors.navy,
        backgroundColor: AppColors.white,
        side: BorderSide(color: AppColors.navy.withValues(alpha: selected ? 0 : 0.18)),
        labelStyle: bodyStyle(
          size: 13,
          weight: FontWeight.w700,
          color: selected ? AppColors.white : AppColors.navy,
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _orderChip(String label, _VersionOrder value) {
    final selected = _order == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _order = value),
      selectedColor: AppColors.navyDeep,
      backgroundColor: AppColors.white,
      side: BorderSide(color: AppColors.navy.withValues(alpha: selected ? 0 : 0.18)),
      labelStyle: bodyStyle(
        size: 12,
        weight: FontWeight.w700,
        color: selected ? AppColors.white : AppColors.navy,
      ),
      showCheckmark: false,
    );
  }

  Widget _versionCard(Map<String, dynamic> version) {
    final created = parseAppDate(version['created_at']);
    final current = version['is_current'] == true;
    final fileName = '${version['file_name'] ?? 'Document'}';
    final look = categoryLook(fileName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            _dateBadge(created),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Version ${version['version'] ?? '—'}',
                          style: bodyStyle(weight: FontWeight.w800, size: 16),
                        ),
                      ),
                      if (current)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Current',
                            style: bodyStyle(size: 11, weight: FontWeight.w800, color: AppColors.emerald),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$fileName · ${bytesLabel(version['file_size'] ?? 0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(size: 13, color: AppColors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Uploaded by ${shortUserRef(version['uploaded_by'])}'
                    '${created == null ? '' : ' · ${relativeTime(version['created_at'])}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle(size: 12, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Download this version',
              onPressed: () => _download(version),
              icon: AppIconBadge(icon: Icons.download_rounded, color: look.$2, size: 36, iconSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateBadge(DateTime? date) {
    return Container(
      width: 56,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.bannerBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            date == null ? '—' : '${date.day}',
            style: bodyStyle(size: 20, weight: FontWeight.w800, color: AppColors.navy),
          ),
          Text(
            date == null ? 'DATE' : formatDisplayMonth(date),
            style: bodyStyle(size: 11, weight: FontWeight.w700, color: AppColors.sky),
          ),
        ],
      ),
    );
  }
}
