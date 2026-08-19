import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/ui.dart';
import 'activity_screen.dart';
import 'edit_profile_screen.dart';
import 'password_screen.dart';
import 'preferences_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getUserDetails();
      setState(() {
        _user = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
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
    final name =
        '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}'.trim();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.logoBlack,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.secondaryBlue,
                  child: Text(
                    (name.isEmpty ? 'U' : name[0]).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    name.isEmpty ? 'Kutumbika user' : name,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${_user?['mobile'] ?? ''}  ${_user?['email'] ?? ''}',
                    style: GoogleFonts.inter(color: AppColors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                _tile('Edit profile', Icons.edit, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(user: _user ?? {}),
                    ),
                  ).then((_) => _load());
                }),
                _tile(
                  (_user?['has_password'] == true)
                      ? 'Change password'
                      : 'Create password',
                  Icons.lock,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasswordScreen(
                          hasPassword: _user?['has_password'] == true,
                        ),
                      ),
                    ).then((_) => _load());
                  },
                ),
                _tile('Preferences', Icons.tune, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PreferencesScreen()),
                  );
                }),
                _tile('Activity', Icons.history, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityScreen()),
                  );
                }),
                _tile('Deactivate account', Icons.pause_circle, () async {
                  final ok = await _confirm('Deactivate this account?');
                  if (ok != true) return;
                  await ApiService.instance.deactivateAccount();
                  if (mounted) await _logout();
                }),
                _tile('Delete account', Icons.delete_forever, () async {
                  final ok = await _confirm('Permanently delete this account?');
                  if (ok != true) return;
                  await ApiService.instance.deleteAccount();
                  if (!mounted) return;
                  await goToLogin(context);
                }),
                _tile('Logout', Icons.logout, _logout),
              ],
            ),
    );
  }

  Future<bool?> _confirm(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  Widget _tile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryDarkBlue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
