import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import '../utils/phone.dart';
import 'activity_screen.dart';
import 'edit_profile_screen.dart';
import 'password_screen.dart';
import 'preferences_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _sub;
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
      final results = await Future.wait([
        ApiService.instance.getUserDetails(),
        ApiService.instance.getSubscription(
          familyRef: ApiService.instance.session.familyReferenceNumber,
        ),
      ]);
      setState(() {
        _user = results[0];
        _sub = results[1];
        _loading = false;
      });
      await _loadPhoto();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _loadPhoto() async {
    if (_user?['has_photo'] != true) {
      if (mounted) setState(() => _photo = null);
      return;
    }
    try {
      final photo = await ApiService.instance.getUserPhoto();
      if (mounted) setState(() => _photo = photo);
    } catch (_) {
      if (mounted) setState(() => _photo = null);
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    try {
      await ApiService.instance.uploadUserPhoto(File(picked.path));
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'Profile photo updated');
      await _load();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> _logout() async {
    try {
      await ApiService.instance.logout();
    } catch (_) {}
    if (!mounted) return;
    await goToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = displayName(_user);
    final plan = (_sub?['plan'] as Map?) ?? {};
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: pagePadding(context, horizontal: 16, top: 16),
              children: [
                Text('Profile', style: headingStyle(size: 22)),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.navy,
                          backgroundImage: _avatarImage,
                          child: _avatarImage != null
                              ? null
                              : Text(
                                  name[0].toUpperCase(),
                                  style: const TextStyle(color: AppColors.gold, fontSize: 28),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_camera, size: 16, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: Text(name == 'there' ? 'Paarisetu user' : name, style: headingStyle(size: 22))),
                const SizedBox(height: 16),
                AppCard(
                  color: AppColors.navy,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${plan['plan_name'] ?? 'Free'} plan',
                        style: bodyStyle(color: Colors.white, weight: FontWeight.w700, size: 16)),
                    subtitle: Text('${_sub?['status'] ?? ''} · ${plan['storage_limit_gb'] ?? 0} GB',
                        style: bodyStyle(color: AppColors.gold, size: 12)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                          .then((_) => _load());
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _detailsCard(),
                const SizedBox(height: 12),
                _tile('Personal information', Icons.edit_outlined, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user ?? {})),
                  ).then((_) => _load());
                }),
                _tile(
                  (_user?['has_password'] == true) ? 'Change password' : 'Create password',
                  Icons.lock_outline,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasswordScreen(hasPassword: _user?['has_password'] == true),
                      ),
                    ).then((_) => _load());
                  },
                ),
                _tile('Subscription & Plan', Icons.workspace_premium_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                      .then((_) => _load());
                }),
                _tile('Storage usage', Icons.cloud_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                }),
                _tile('Notifications', Icons.tune, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen()));
                }),
                _tile('Activity', Icons.history, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
                }),
                _tile('Settings', Icons.settings_outlined, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }),
                _tile('Logout', Icons.logout, _logout),
              ],
            ),
    );
  }

  ImageProvider? get _avatarImage {
    if (_photo != null) return MemoryImage(_photo!);
    final raw = '${_user?['profile_photo'] ?? ''}'.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return NetworkImage(raw);
    }
    return null;
  }

  Widget _detailsCard() {
    final user = _user ?? {};
    final dob = DateTime.tryParse('${user['dob'] ?? ''}');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal details', style: bodyStyle(weight: FontWeight.w700, size: 16)),
          const SizedBox(height: 12),
          _verifiedDetail(
            'Mobile',
            formatE164(user['mobile']?.toString()),
            user['mobile_verified'] == true,
          ),
          _verifiedDetail(
            'Email',
            _orDash(user['email']),
            user['email_verified'] == true,
          ),
          _detail('Date of birth', dob == null ? '—' : DateFormat.yMMMd().format(dob)),
          _detail('Gender', _orDash(user['gender'])),
          _detail('Country', _orDash(user['country'])),
          _detail('State', _orDash(user['state'])),
          _detail('City', _orDash(user['city'])),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: bodyStyle(size: 13, color: AppColors.grey)),
          ),
          Expanded(child: Text(value, style: bodyStyle(weight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _verifiedDetail(String label, String value, bool verified) {
    final text = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: bodyStyle(size: 13, color: AppColors.grey)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: Text(text, style: bodyStyle(weight: FontWeight.w600))),
                if (verified)
                  const Icon(Icons.verified_rounded, size: 18, color: AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _orDash(dynamic value, {String fallback = '—'}) {
    final text = '$value'.trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
  }

  Widget _tile(String title, IconData icon, VoidCallback onTap) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: AppIconBadge(icon: icon, color: AppColors.navy, size: 36, iconSize: 18),
        title: Text(title, style: bodyStyle(weight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
