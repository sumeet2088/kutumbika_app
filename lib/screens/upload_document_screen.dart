import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'create_family_screen.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  List<dynamic> _categories = [];
  String? _categoryRef;
  File? _file;
  bool _loading = false;
  bool _authorized = false;
  bool _allowAI = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await ApiService.instance.listCategories();
      setState(() {
        _categories = (data['categories'] as List?) ?? [];
        if (_categories.isNotEmpty) {
          _categoryRef =
              '${(_categories.first as Map)['document_category_reference_number']}';
        }
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _file = File(result.files.single.path!));
      if (_title.text.isEmpty) {
        _title.text = result.files.single.name;
      }
    }
  }

  Future<void> _upload() async {
    final familyRef = ApiService.instance.session.familyReferenceNumber;
    if (familyRef == null) {
      ErrorHandler.showError(context, 'Create a family before uploading');
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const CreateFamilyScreen(asOnboarding: false)),
      );
      return;
    }
    if (_file == null || _categoryRef == null) {
      ErrorHandler.showError(context, 'Pick a file and category');
      return;
    }
    if (!_authorized) {
      ErrorHandler.showError(context, 'Confirm you are authorised to upload this information');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.instance.uploadDocument(
        file: _file!,
        categoryRef: _categoryRef!,
        familyRef: familyRef,
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        allowAI: _allowAI,
        authorizedFamilyData: _authorized,
      );
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'Document uploaded');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Upload Document'),
      body: ListView(
        padding: pagePadding(context, horizontal: 24, top: 16),
        children: [
          PrimaryButton(
            label: _file == null ? 'Choose file' : _file!.path.split(RegExp(r'[\\/]')).last,
            onPressed: _pick,
          ),
          const SizedBox(height: 16),
          AppTextField(controller: _title, label: 'Title', prefix: Icons.title_rounded),
          const SizedBox(height: 14),
          AppTextField(
            controller: _description,
            label: 'Description',
            prefix: Icons.notes_rounded,
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _categoryRef,
            decoration: fieldDecoration(label: 'Category', prefix: Icons.folder_rounded),
            items: [
              for (final c in _categories)
                DropdownMenuItem(
                  value: '${(c as Map)['document_category_reference_number']}',
                  child: Text('${c['document_name']}'),
                ),
            ],
            onChanged: (v) => setState(() => _categoryRef = v),
          ),
          const SizedBox(height: 24),
          Text('How this file is processed', style: bodyStyle(weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Your document will be encrypted and stored in this family vault. We use it for organisation, search and reminders. Image OCR and AI question-answering run only if you allow AI processing.',
            style: bodyStyle(size: 13, color: AppColors.navyDeep),
          ),
          CheckboxListTile(
            value: _authorized,
            onChanged: (v) => setState(() => _authorized = v == true),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('I am authorised to upload and manage this information in Paarisetu'),
          ),
          CheckboxListTile(
            value: _allowAI,
            onChanged: (v) => setState(() => _allowAI = v == true),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow AI / OCR to process this document (optional)'),
            subtitle: const Text('You can turn this off later in Privacy & Data'),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Continue upload', loading: _loading, onPressed: _upload),
        ],
      ),
    );
  }
}
