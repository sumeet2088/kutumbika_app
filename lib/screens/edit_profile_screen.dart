import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/error_handler.dart';
import '../utils/phone.dart';
import '../utils/ui.dart';
import '../widgets/phone_field.dart';

const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

const _countries = [
  'India',
  'United States',
  'United Kingdom',
  'United Arab Emirates',
  'Singapore',
  'Canada',
  'Australia',
  'Germany',
  'Japan',
  'Other',
];

const _indianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

const _languages = <String, String>{
  'en': 'English',
  'hi': 'Hindi',
  'mr': 'Marathi',
  'ta': 'Tamil',
  'te': 'Telugu',
  'kn': 'Kannada',
  'bn': 'Bengali',
  'gu': 'Gujarati',
};

const _timezones = [
  'Asia/Kolkata',
  'Asia/Dubai',
  'Asia/Singapore',
  'America/New_York',
  'America/Los_Angeles',
  'Europe/London',
  'Australia/Sydney',
  'UTC',
];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _first = TextEditingController(text: _value('first_name'));
  late final _last = TextEditingController(text: _value('last_name'));
  late final _email = TextEditingController(text: _value('email'));
  late final _city = TextEditingController(text: _value('city'));
  late final _stateOther = TextEditingController(text: _value('state'));
  late final _mobile = TextEditingController();
  late final _mobileLocked = TextEditingController();

  late String? _gender;
  late String _country;
  late String? _state;
  late String _language;
  late String _timezone;
  DateTime? _dob;
  late DialCountry _dial;
  late bool _emailVerified;
  late bool _mobileVerified;
  late String _mobileDisplay;
  Uint8List? _photo;
  bool _changingMobile = false;
  bool _loading = false;
  bool _photoLoading = false;

  String _value(String key) => '${widget.user[key] ?? ''}'.trim();

  @override
  void initState() {
    super.initState();
    _gender = _matchOrKeep(_value('gender'), _genders);
    _country = _matchOrKeep(_value('country'), _countries) ?? 'India';
    _state = _matchOrKeep(_value('state'), _indianStates);
    _language = _languages.containsKey(_value('language')) ? _value('language') : 'en';
    _timezone = _matchOrKeep(_value('timezone'), _timezones) ?? 'Asia/Kolkata';
    _dob = DateTime.tryParse(_value('dob'));
    _emailVerified = widget.user['email_verified'] == true;
    _mobileVerified = widget.user['mobile_verified'] == true;
    _mobileDisplay = formatE164(_value('mobile'));
    _mobileLocked.text = _mobileDisplay.isEmpty ? '—' : _mobileDisplay;
    final split = _splitMobile(_value('mobile'));
    _dial = split.$1;
    _mobile.text = split.$2;
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    if (widget.user['has_photo'] != true) return;
    try {
      final photo = await ApiService.instance.getUserPhoto();
      if (mounted) setState(() => _photo = photo);
    } catch (_) {}
  }

  ImageProvider? get _avatarImage {
    if (_photo != null) return MemoryImage(_photo!);
    final raw = _value('profile_photo');
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return NetworkImage(raw);
    }
    return null;
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _photoLoading = true);
    try {
      await ApiService.instance.uploadUserPhoto(File(picked.path));
      final photo = await ApiService.instance.getUserPhoto();
      if (!mounted) return;
      setState(() => _photo = photo);
      ErrorHandler.showSuccess(context, 'Profile photo updated');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  (DialCountry, String) _splitMobile(String raw) {
    final digits = digitsOnly(raw);
    for (final c in dialCountries) {
      if (digits.startsWith(c.dial) && digits.length > c.dial.length) {
        return (c, digits.substring(c.dial.length));
      }
    }
    return (defaultDialCountry, digits);
  }

  String? _matchOrKeep(String value, List<String> options) {
    if (value.isEmpty) return null;
    for (final option in options) {
      if (option.toLowerCase() == value.toLowerCase()) return option;
    }
    return value;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final state = _country == 'India' ? (_state ?? '') : _stateOther.text.trim();
      await ApiService.instance.updateUser({
        'first_name': _first.text.trim(),
        'last_name': _last.text.trim(),
        if (!_emailVerified) 'email': _email.text.trim(),
        'dob': _dob == null ? '' : DateFormat('yyyy-MM-dd').format(_dob!),
        'gender': _gender ?? '',
        'country': _country,
        'state': state,
        'city': _city.text.trim(),
        'timezone': _timezone,
        'language': _language,
      });
      if (!mounted) return;
      ErrorHandler.showSuccess(context, 'Profile updated');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyEmail() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ErrorHandler.showError(context, 'Enter an email first');
      return;
    }
    try {
      await ApiService.instance.sendUserOTP(email: email);
      final otp = await _askOtp('Enter the OTP sent to $email');
      if (otp == null || otp.isEmpty) return;
      await ApiService.instance.verifyUserOTP(otp: otp, email: email);
      if (!mounted) return;
      setState(() => _emailVerified = true);
      ErrorHandler.showSuccess(context, 'Email verified');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    }
  }

  Future<void> _updateMobile() async {
    final e164 = toE164(_mobile.text, country: _dial);
    if (e164 == null) {
      ErrorHandler.showError(context, 'Enter a valid mobile number');
      return;
    }
    setState(() => _changingMobile = true);
    try {
      await ApiService.instance.sendUserOTP(mobile: e164);
      final otp = await _askOtp('Enter the OTP sent to ${formatE164(e164)}');
      if (otp == null || otp.isEmpty) return;
      await ApiService.instance.verifyUserOTP(otp: otp, mobile: e164);
      if (!mounted) return;
      setState(() {
        _mobileDisplay = formatE164(e164);
        _mobileLocked.text = _mobileDisplay;
        _mobileVerified = true;
      });
      ErrorHandler.showSuccess(context, 'Mobile number updated');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _changingMobile = false);
    }
  }

  Future<String?> _askOtp(String title) async {
    final controller = TextEditingController();
    final otp = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: bodyStyle(weight: FontWeight.w700, size: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: fieldDecoration(label: 'OTP'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    controller.dispose();
    return otp;
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _city.dispose();
    _stateOther.dispose();
    _mobile.dispose();
    _mobileLocked.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRef = _value('user_reference_number');
    final status = _value('status');
    final genderItems = {
      ..._genders,
      if (_gender != null && _gender!.isNotEmpty) _gender!,
    }.toList();
    final countryItems = {
      ..._countries,
      if (_country.isNotEmpty) _country,
    }.toList();
    final timezoneItems = {
      ..._timezones,
      if (_timezone.isNotEmpty) _timezone,
    }.toList();
    final languageItems = Map<String, String>.from(_languages);
    if (_language.isNotEmpty && !languageItems.containsKey(_language)) {
      languageItems[_language] = _language;
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: navyAppBar('Edit profile'),
      body: ListView(
        padding: pagePadding(context, horizontal: 24, top: 8),
        children: [
          Center(
            child: GestureDetector(
              onTap: _photoLoading ? null : _pickPhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.navy,
                    backgroundImage: _avatarImage,
                    child: _photoLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                          )
                        : _avatarImage != null
                            ? null
                            : Text(
                                displayName(widget.user)[0].toUpperCase(),
                                style: const TextStyle(color: AppColors.gold, fontSize: 28),
                              ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                    child: const Icon(Icons.photo_camera, size: 16, color: AppColors.navy),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text('Tap to change photo', style: bodyStyle(size: 12, color: AppColors.grey))),
          const SizedBox(height: 24),
          _section('Account'),
          _readonly('User ID', userRef.isEmpty ? '—' : userRef),
          const SizedBox(height: 12),
          _readonly('Status', status.isEmpty ? 'ACTIVE' : status),
          const SizedBox(height: 24),
          _section('Name'),
          AppTextField(controller: _first, label: 'First name', prefix: Icons.person_rounded),
          const SizedBox(height: 14),
          AppTextField(controller: _last, label: 'Last name', prefix: Icons.person_outline_rounded),
          const SizedBox(height: 24),
          _section('Contact'),
          AppTextField(
            controller: _email,
            label: 'Email',
            prefix: Icons.alternate_email_rounded,
            enabled: !_emailVerified,
            verified: _emailVerified,
            keyboardType: TextInputType.emailAddress,
          ),
          if (!_emailVerified)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _verifyEmail,
                child: const Text('Verify email OTP'),
              ),
            )
          else
            const SizedBox(height: 14),
          if (_mobileVerified)
            AppTextField(
              controller: _mobileLocked,
              label: 'Mobile',
              prefix: Icons.phone_rounded,
              enabled: false,
              verified: true,
            )
          else ...[
            PhoneField(
              controller: _mobile,
              country: _dial,
              onCountryChanged: (c) => setState(() => _dial = c),
              label: 'Mobile number',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _changingMobile ? null : _updateMobile,
                child: Text(_changingMobile ? 'Updating…' : 'Send OTP to verify mobile'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _section('Personal'),
          AppDateField(
            label: 'Date of birth',
            value: _dob,
            lastDate: DateTime.now(),
            onPicked: (picked) => setState(() => _dob = picked),
          ),
          if (_dob != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _dob = null),
                child: const Text('Clear date of birth'),
              ),
            )
          else
            const SizedBox(height: 16),
          _dropdown<String>(
            label: 'Gender',
            prefix: Icons.wc_rounded,
            value: _gender,
            items: [
              const DropdownMenuItem(value: null, child: Text('Select gender')),
              for (final g in genderItems) DropdownMenuItem(value: g, child: Text(g)),
            ],
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 24),
          _section('Location'),
          _dropdown<String>(
            label: 'Country',
            prefix: Icons.flag_rounded,
            value: _country,
            items: [
              for (final c in countryItems) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _country = v;
                if (v != 'India') _state = null;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_country == 'India')
            _dropdown<String>(
              label: 'State',
              prefix: Icons.map_rounded,
              value: _state,
              items: [
                const DropdownMenuItem(value: null, child: Text('Select state')),
                for (final s in {
                  ..._indianStates,
                  if (_state != null && _state!.isNotEmpty) _state!,
                })
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _state = v),
            )
          else
            AppTextField(controller: _stateOther, label: 'State / region', prefix: Icons.map_rounded),
          const SizedBox(height: 16),
          AppTextField(controller: _city, label: 'City', prefix: Icons.location_city_rounded),
          const SizedBox(height: 24),
          _section('App preferences'),
          _dropdown<String>(
            label: 'Language',
            prefix: Icons.translate_rounded,
            value: _language,
            items: [
              for (final e in languageItems.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _language = v ?? 'en'),
          ),
          const SizedBox(height: 16),
          _dropdown<String>(
            label: 'Timezone',
            prefix: Icons.public_rounded,
            value: _timezone,
            items: [
              for (final z in timezoneItems) DropdownMenuItem(value: z, child: Text(z)),
            ],
            onChanged: (v) => setState(() => _timezone = v ?? 'Asia/Kolkata'),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Save', loading: _loading, onPressed: _save),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: bodyStyle(weight: FontWeight.w700, size: 16)),
    );
  }

  Widget _readonly(String label, String value) {
    return InputDecorator(
      decoration: fieldDecoration(label: label),
      child: Text(value, style: bodyStyle(weight: FontWeight.w500)),
    );
  }

  Widget _dropdown<T>({
    required String label,
    IconData? prefix,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: fieldDecoration(label: label, prefix: prefix),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
