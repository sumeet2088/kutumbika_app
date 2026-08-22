import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/phone.dart';
import '../utils/ui.dart';
import 'invite_member_screen.dart';

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

  String get _myRole => '${_family?['my_role'] ?? ''}'.toUpperCase();
  bool get _canManage => _myRole == 'OWNER' || _myRole == 'ADMIN';

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
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.instance.updateFamily(familyRef: widget.familyRef, familyName: name.text);
      await _load();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _changeRole(Map member) async {
    final current = '${member['role']}'.toUpperCase();
    final options = _myRole == 'OWNER'
        ? ['ADMIN', 'EDITOR', 'VIEWER']
        : ['EDITOR', 'VIEWER'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Change role', style: headingStyle(size: 20)),
            ),
            for (final role in options)
              ListTile(
                title: Text(role),
                trailing: current == role ? const Icon(Icons.check, color: AppColors.gold) : null,
                onTap: () => Navigator.pop(context, role),
              ),
          ],
        ),
      ),
    );
    if (selected == null || selected == current) return;
    try {
      await ApiService.instance.changeMemberRole(
        familyRef: widget.familyRef,
        memberRef: '${member['family_member_reference_number']}',
        role: selected,
      );
      await _load();
      if (mounted) ErrorHandler.showSuccess(context, 'Role updated to $selected');
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _remove(Map member) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member'),
        content: const Text(
          'This revokes access immediately. Documents they uploaded stay in the family vault.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.instance.removeMember(
        familyRef: widget.familyRef,
        memberRef: '${member['family_member_reference_number']}',
      );
      await _load();
      if (mounted) ErrorHandler.showSuccess(context, 'Membership revoked. Documents were kept.');
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar(
        '${_family?['family_name'] ?? 'Family'}',
        actions: [
          IconButton(onPressed: _rename, icon: const Icon(Icons.edit_outlined)),
          if (_canManage)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InviteMemberScreen(
                      familyRef: widget.familyRef,
                      myRole: _myRole,
                    ),
                  ),
                ).then((_) => _load());
              },
              icon: const Icon(Icons.person_add_alt_1),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker()
                            .pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (picked == null) return;
                        await ApiService.instance.updateFamily(
                          familyRef: widget.familyRef,
                          photo: File(picked.path),
                        );
                        await _load();
                      },
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.navy,
                        backgroundImage: _photo == null ? null : MemoryImage(_photo!),
                        child: _photo == null
                            ? const Icon(Icons.photo_camera_outlined, color: AppColors.gold)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: Text('Your role: $_myRole', style: bodyStyle(color: AppColors.grey))),
                  const SizedBox(height: 20),
                  Text('Family Members', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                  const SizedBox(height: 8),
                  ..._members.map((m) {
                    final map = m as Map;
                    final name =
                        '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim();
                    final role = '${map['role']}'.toUpperCase();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.navy,
                            child: Text(
                              (name.isEmpty ? 'M' : name[0]).toUpperCase(),
                              style: const TextStyle(color: AppColors.gold),
                            ),
                          ),
                          title: Text(name.isEmpty ? formatE164('${map['mobile'] ?? ''}') : name,
                              style: bodyStyle(weight: FontWeight.w700)),
                          subtitle: Text('$role · ${map['relation']} · ${map['status']}',
                              style: bodyStyle(size: 12, color: AppColors.grey)),
                          trailing: !_canManage || role == 'OWNER'
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'role') _changeRole(map);
                                    if (v == 'remove') _remove(map);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'role', child: Text('Change role')),
                                    PopupMenuItem(value: 'remove', child: Text('Remove')),
                                  ],
                                ),
                        ),
                      ),
                    );
                  }),
                  if (_canManage) ...[
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Invite Member',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InviteMemberScreen(
                              familyRef: widget.familyRef,
                              myRole: _myRole,
                            ),
                          ),
                        ).then((_) => _load());
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Invitations', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                  if (_invites.isEmpty)
                    Text('No pending invitations', style: bodyStyle(color: AppColors.grey))
                  else
                    ..._invites.map((i) {
                      final map = i as Map;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(formatE164('${map['mobile'] ?? map['email'] ?? 'Invite'}')),
                        subtitle: Text('${map['status']} · ${map['role']}'),
                      );
                    }),
                  const SizedBox(height: 16),
                  Text('Activity', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                  ..._activity.map((a) {
                    final map = a as Map;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${map['action']} ${map['entity_type']}'),
                      subtitle: Text('${map['created_at'] ?? ''}'),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
