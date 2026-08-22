import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/phone.dart';
import '../utils/ui.dart';
import '../widgets/phone_field.dart';

class InviteMemberScreen extends StatefulWidget {
  const InviteMemberScreen({super.key, required this.familyRef, this.myRole});

  final String familyRef;
  final String? myRole;

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  String _role = 'VIEWER';
  String _relation = 'OTHER';
  bool _loading = false;
  DialCountry _country = defaultDialCountry;

  List<String> get _roles {
    if ((widget.myRole ?? '').toUpperCase() == 'OWNER') {
      return const ['ADMIN', 'EDITOR', 'VIEWER'];
    }
    return const ['EDITOR', 'VIEWER'];
  }

  static const _relations = [
    'FATHER', 'MOTHER', 'HUSBAND', 'WIFE', 'SON', 'DAUGHTER',
    'BROTHER', 'SISTER', 'UNCLE', 'AUNT', 'GUARDIAN', 'OTHER',
  ];

  @override
  void dispose() {
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final e164 = toE164(_mobile.text, country: _country);
    if (e164 == null) {
      ErrorHandler.showError(context, 'Enter a valid international mobile number');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.instance.inviteFamilyMember(
        familyRef: widget.familyRef,
        mobile: e164,
        role: _role,
        relation: _relation,
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      );
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'Invitation sent');
      Navigator.pop(context, true);
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
      appBar: navyAppBar('Invite Member'),
      body: ListView(
        padding: pagePadding(context),
        children: [
          Text('Add a family member to this vault. Role is checked against the current plan.',
              style: bodyStyle(color: AppColors.grey)),
          const SizedBox(height: 20),
          PhoneField(
            controller: _mobile,
            country: _country,
            onCountryChanged: (c) => setState(() => _country = c),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _email,
            label: 'Email (optional)',
            hint: 'email@example.com',
            prefix: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: fieldDecoration(label: 'Role', prefix: Icons.shield_rounded),
            items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _role = v ?? 'VIEWER'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _relation,
            decoration: fieldDecoration(label: 'Relationship', prefix: Icons.family_restroom_rounded),
            items: _relations.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() => _relation = v ?? 'OTHER'),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Save Member', loading: _loading, onPressed: _save),
        ],
      ),
    );
  }
}
