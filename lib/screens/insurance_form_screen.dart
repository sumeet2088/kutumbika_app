import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';

class InsuranceFormScreen extends StatefulWidget {
  const InsuranceFormScreen({super.key});

  @override
  State<InsuranceFormScreen> createState() => _InsuranceFormScreenState();
}

class _InsuranceFormScreenState extends State<InsuranceFormScreen> {
  final _provider = TextEditingController();
  final _policyNumber = TextEditingController();
  final _start = TextEditingController();
  final _expiry = TextEditingController();
  List<dynamic> _documents = [];
  List<dynamic> _vehicles = [];
  String? _documentRef;
  String? _vehicleRef;
  File? _file;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadChoices();
  }

  Future<void> _loadChoices() async {
    final api = ApiService.instance;
    final familyRef = api.session.familyReferenceNumber;
    try {
      final results = await Future.wait([
        api.listDocuments(familyRef: familyRef),
        api.listVehicles(familyRef: familyRef).catchError((_) => {'vehicles': []}),
      ]);
      setState(() {
        _documents = (results[0]['documents'] as List?) ?? [];
        _vehicles = (results[1]['vehicles'] as List?) ?? [];
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _documentRef = null;
      });
    }
  }

  Future<void> _save() async {
    final familyRef = ApiService.instance.session.familyReferenceNumber;
    if (familyRef == null) {
      ErrorHandler.showError(context, 'Select a family first');
      return;
    }
    setState(() => _loading = true);
    try {
      var documentRef = _documentRef;
      if (_file != null) {
        final categories = await ApiService.instance.listCategories();
        final cats = (categories['categories'] as List?) ?? [];
        String? categoryRef;
        for (final cat in cats) {
          final map = cat as Map;
          if ('${map['document_name']}'.toLowerCase().contains('insurance')) {
            categoryRef = '${map['document_category_reference_number']}';
            break;
          }
        }
        categoryRef ??= cats.isNotEmpty
            ? '${(cats.first as Map)['document_category_reference_number']}'
            : null;
        if (categoryRef == null) {
          throw Exception('Create an Insurance document category first');
        }
        final uploaded = await ApiService.instance.uploadDocument(
          file: _file!,
          categoryRef: categoryRef,
          familyRef: familyRef,
          title: _file!.path.split(RegExp(r'[\\/]')).last,
          documentType: 'INSURANCE_POLICY',
        );
        documentRef = '${uploaded['document_reference_number']}';
      }
      await ApiService.instance.createInsurance(
        familyRef: familyRef,
        provider: _provider.text.trim(),
        policyNumber: _policyNumber.text.trim(),
        startDate: _start.text.trim().isEmpty ? null : _start.text.trim(),
        expiryDate: _expiry.text.trim().isEmpty ? null : _expiry.text.trim(),
        vehicleRef: _vehicleRef,
        documentRef: documentRef,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Add Policy'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _provider, decoration: fieldDecoration(hint: 'Insurance provider')),
          const SizedBox(height: 12),
          TextField(controller: _policyNumber, decoration: fieldDecoration(hint: 'Policy number')),
          const SizedBox(height: 12),
          TextField(controller: _start, decoration: fieldDecoration(hint: 'Start date YYYY-MM-DD')),
          const SizedBox(height: 12),
          TextField(controller: _expiry, decoration: fieldDecoration(hint: 'Expiry date YYYY-MM-DD')),
          const SizedBox(height: 16),
          Text('Attach vehicle (optional)', style: bodyStyle(weight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _vehicleRef,
            decoration: fieldDecoration(hint: 'Vehicle'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ..._vehicles.map((v) {
                final map = v as Map;
                return DropdownMenuItem(
                  value: '${map['vehicle_reference_number']}',
                  child: Text('${map['make'] ?? ''} ${map['model'] ?? ''} ${map['registration_number'] ?? ''}'),
                );
              }),
            ],
            onChanged: (v) => setState(() => _vehicleRef = v),
          ),
          const SizedBox(height: 16),
          Text('Policy document', style: bodyStyle(weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Upload a new file or attach one already in Documents. The PDF is stored only once.',
              style: bodyStyle(size: 12, color: AppColors.grey)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.upload_file),
            label: Text(_file == null ? 'Upload document' : _file!.path.split(RegExp(r'[\\/]')).last),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _documentRef,
            decoration: fieldDecoration(hint: 'Or attach existing document'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ..._documents.map((d) {
                final map = d as Map;
                return DropdownMenuItem(
                  value: '${map['document_reference_number']}',
                  child: Text('${map['title'] ?? map['file_name'] ?? 'Document'}'),
                );
              }),
            ],
            onChanged: (v) => setState(() {
              _documentRef = v;
              _file = null;
            }),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: _loading ? 'Saving...' : 'Save policy', onPressed: _loading ? null : _save),
        ],
      ),
    );
  }
}
