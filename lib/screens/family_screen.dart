import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'create_family_screen.dart';
import 'family_detail_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<dynamic> _pending = [];
  Map<String, dynamic>? _family;
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
      final pending = await api.listPendingInvitations();
      Map<String, dynamic>? family;
      final ref = api.session.familyReferenceNumber;
      if (ref != null) {
        family = await api.getFamilyDetails(ref);
      }
      setState(() {
        _pending = (pending['invitations'] as List?) ?? [];
        _family = family;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
        title: const Text('Family'),
        backgroundColor: AppColors.logoBlack,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_family != null)
                    ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.home,
                          color: AppColors.goldYellow),
                      title: Text('${_family!['family_name']}'),
                      subtitle: Text('Role: ${_family!['my_role'] ?? 'member'}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FamilyDetailScreen(
                              familyRef:
                                  '${_family!['family_reference_number']}',
                            ),
                          ),
                        ).then((_) => _load());
                      },
                    )
                  else
                    PrimaryButton(
                      label: 'Create family',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const CreateFamilyScreen(asOnboarding: false)),
                        ).then((_) => _load());
                      },
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Pending invitations',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_pending.isEmpty)
                    const Text('No pending invitations',
                        style: TextStyle(color: AppColors.grey))
                  else
                    ..._pending.map((inv) {
                      final map = inv as Map;
                      return Card(
                        child: ListTile(
                          title: Text('${map['family_name'] ?? 'Family'}'),
                          subtitle: Text(
                              '${map['role']} · ${map['relation']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await ApiService.instance.acceptInvitation(
                                    '${map['family_invitation_reference_number']}',
                                  );
                                  await _load();
                                },
                                child: const Text('Accept'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await ApiService.instance.rejectInvitation(
                                    '${map['family_invitation_reference_number']}',
                                  );
                                  await _load();
                                },
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
