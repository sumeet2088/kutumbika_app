import 'package:flutter/material.dart';

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
  List<dynamic> _families = [];
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
      final mine = await api.listMyFamilies().catchError((_) => {'families': []});
      Map<String, dynamic>? family;
      final ref = api.session.familyReferenceNumber;
      if (ref != null) family = await api.getFamilyDetails(ref);
      setState(() {
        _pending = (pending['invitations'] as List?) ?? [];
        _families = (mine['families'] as List?) ?? [];
        _family = family;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Family'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_families.isNotEmpty)
                    ..._families.map((f) {
                      final map = f as Map;
                      final ref = '${map['family_reference_number']}';
                      final current = ref == ApiService.instance.session.familyReferenceNumber;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.navy,
                              child: Icon(Icons.home, color: AppColors.gold),
                            ),
                            title: Text('${map['family_name']}', style: bodyStyle(weight: FontWeight.w700)),
                            subtitle: Text(
                              '${map['my_role']}${current ? ' · current' : ''}${map['plan_name'] != null ? ' · ${map['plan_name']}' : ''}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await ApiService.instance.session.saveFamily(ref);
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FamilyDetailScreen(familyRef: ref),
                                ),
                              ).then((_) => _load());
                            },
                          ),
                        ),
                      );
                    })
                  else if (_family != null)
                    AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.navy,
                          child: Icon(Icons.home, color: AppColors.gold),
                        ),
                        title: Text('${_family!['family_name']}', style: bodyStyle(weight: FontWeight.w700)),
                        subtitle: Text('Your role: ${_family!['my_role'] ?? 'member'}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FamilyDetailScreen(
                                familyRef: '${_family!['family_reference_number']}',
                              ),
                            ),
                          ).then((_) => _load());
                        },
                      ),
                    )
                  else
                    PrimaryButton(
                      label: 'Create family',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateFamilyScreen(asOnboarding: false),
                          ),
                        ).then((_) => _load());
                      },
                    ),
                  const SizedBox(height: 24),
                  Text('Pending invitations', style: bodyStyle(weight: FontWeight.w700, size: 16)),
                  const SizedBox(height: 8),
                  if (_pending.isEmpty)
                    Text('No pending invitations', style: bodyStyle(color: AppColors.grey))
                  else
                    ..._pending.map((inv) {
                      final map = inv as Map;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${map['family_name'] ?? 'Family'}', style: bodyStyle(weight: FontWeight.w700)),
                              Text('${map['role']} · ${map['relation']}', style: bodyStyle(color: AppColors.grey)),
                              Row(
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
