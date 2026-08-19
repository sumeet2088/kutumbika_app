import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';

class FamilyDetailScreen extends StatefulWidget {
  const FamilyDetailScreen({super.key, required this.familyRef});

  final String familyRef;

  @override
  State<FamilyDetailScreen> createState() => _FamilyDetailScreenState();
}

class _FamilyDetailScreenState extends State<FamilyDetailScreen> {
  Map<String, dynamic>? _family;
  List<dynamic> _members = [];
  List<dynamic> _invites = [];
  List<dynamic> _activity = [];
  Uint8List? _photo;
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
        api.getFamilyDetails(widget.familyRef),
        api.listFamilyMembers(widget.familyRef),
        api.listFamilyInvitations(widget.familyRef),
        api.listFamilyActivity(widget.familyRef),
      ]);
      setState(() {
        _family = results[0];
        _members = (results[1]['members'] as List?) ?? [];
        _invites = (results[2]['invitations'] as List?) ?? [];
        _activity = (results[3]['activities'] as List?) ?? [];
        _loading = false;
      });
      if (_family?['has_photo'] == true) {
        try {
          final photo = await api.getFamilyPhoto(widget.familyRef);
          if (mounted) setState(() => _photo = photo);
        } catch (_) {}
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _invite() async {
    final mobile = TextEditingController();
    final relation = TextEditingController(text: 'relative');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: mobile,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: relation,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Invite')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.instance.inviteFamilyMember(
        familyRef: widget.familyRef,
        mobile: mobile.text,
        role: 'MEMBER',
        relation: relation.text,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _rename() async {
    final name = TextEditingController(text: '${_family?['family_name'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update family'),
        content: TextField(controller: name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.instance.updateFamily(
        familyRef: widget.familyRef,
        familyName: name.text,
      );
      await _load();
    } catch (e) {
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
        title: Text('${_family?['family_name'] ?? 'Family'}'),
        backgroundColor: AppColors.logoBlack,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _rename, icon: const Icon(Icons.edit)),
          IconButton(onPressed: _invite, icon: const Icon(Icons.person_add)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (picked == null) return;
                      await ApiService.instance.updateFamily(
                        familyRef: widget.familyRef,
                        photo: File(picked.path),
                      );
                      await _load();
                    },
                    child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.secondaryBlue,
                    backgroundImage:
                        _photo == null ? null : MemoryImage(_photo!),
                    child: _photo == null
                        ? const Icon(Icons.family_restroom, color: Colors.white)
                        : null,
                  ),
                ),
                ),
                const SizedBox(height: 16),
                Text('Members',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ..._members.map((m) {
                  final map = m as Map;
                  return ListTile(
                    title: Text(
                        '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'
                            .trim()
                            .ifEmpty('${map['mobile'] ?? 'Member'}')),
                    subtitle: Text('${map['role']} · ${map['relation']} · ${map['status']}'),
                  );
                }),
                const SizedBox(height: 16),
                Text('Invitations',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ..._invites.map((i) {
                  final map = i as Map;
                  return ListTile(
                    title: Text('${map['mobile'] ?? map['email'] ?? 'Invite'}'),
                    subtitle: Text('${map['status']} · ${map['role']}'),
                  );
                }),
                const SizedBox(height: 16),
                Text('Activity',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ..._activity.map((a) {
                  final map = a as Map;
                  return ListTile(
                    dense: true,
                    title: Text('${map['action']} ${map['entity_type']}'),
                    subtitle: Text('${map['created_at'] ?? ''}'),
                  );
                }),
              ],
            ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
