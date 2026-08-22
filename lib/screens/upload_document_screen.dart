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
        padding: const EdgeInsets.all(24),
        children: [
          PrimaryButton(
            label: _file == null ? 'Choose file' : _file!.path.split(RegExp(r'[\\/]')).last,
            onPressed: _pick,
          ),
          const SizedBox(height: 16),
          AppTextField(controller: _title, label: 'Title'),
          const SizedBox(height: 16),
          AppTextField(controller: _description, label: 'Description'),
          const SizedBox(height: 16),
          const Text('Category'),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: fieldDecoration(label: 'Category'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _categoryRef,
                isExpanded: true,
                items: [
                  for (final c in _categories)
                    DropdownMenuItem(
                      value: '${(c as Map)['document_category_reference_number']}',
                      child: Text('${c['document_name']}'),
                    ),
                ],
                onChanged: (v) => setState(() => _categoryRef = v),
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Upload', loading: _loading, onPressed: _upload),
        ],
      ),
    );
  }
}
