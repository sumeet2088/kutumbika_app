class DialCountry {
  const DialCountry({
    required this.iso,
    required this.name,
    required this.dial,
    required this.nationalMin,
    required this.nationalMax,
    required this.flag,
  });

  final String iso;
  final String name;
  final String dial;
  final int nationalMin;
  final int nationalMax;
  final String flag;

  String get label => '$flag +$dial';
}

const dialCountries = <DialCountry>[
  DialCountry(iso: 'IN', name: 'India', dial: '91', nationalMin: 10, nationalMax: 10, flag: '🇮🇳'),
  DialCountry(iso: 'US', name: 'United States', dial: '1', nationalMin: 10, nationalMax: 10, flag: '🇺🇸'),
  DialCountry(iso: 'CA', name: 'Canada', dial: '1', nationalMin: 10, nationalMax: 10, flag: '🇨🇦'),
  DialCountry(iso: 'GB', name: 'United Kingdom', dial: '44', nationalMin: 10, nationalMax: 10, flag: '🇬🇧'),
  DialCountry(iso: 'AE', name: 'United Arab Emirates', dial: '971', nationalMin: 9, nationalMax: 9, flag: '🇦🇪'),
  DialCountry(iso: 'SG', name: 'Singapore', dial: '65', nationalMin: 8, nationalMax: 8, flag: '🇸🇬'),
  DialCountry(iso: 'AU', name: 'Australia', dial: '61', nationalMin: 9, nationalMax: 9, flag: '🇦🇺'),
  DialCountry(iso: 'JP', name: 'Japan', dial: '81', nationalMin: 10, nationalMax: 10, flag: '🇯🇵'),
  DialCountry(iso: 'DE', name: 'Germany', dial: '49', nationalMin: 10, nationalMax: 13, flag: '🇩🇪'),
  DialCountry(iso: 'BR', name: 'Brazil', dial: '55', nationalMin: 10, nationalMax: 11, flag: '🇧🇷'),
];

DialCountry get defaultDialCountry =>
    dialCountries.firstWhere((c) => c.iso == 'IN');

String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

/// Canonical E.164: + and 8–15 digits.
String? toE164(String raw, {DialCountry? country}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final plus = trimmed.startsWith('+') || trimmed.startsWith('00');
  var digits = digitsOnly(trimmed);
  if (digits.isEmpty) return null;

  if (!plus) {
    final cc = country ?? defaultDialCountry;
    if (digits.startsWith(cc.dial) &&
        digits.length > cc.dial.length) {
      // already includes country code
    } else {
      digits = '${cc.dial}$digits';
    }
  }
  if (digits.length < 8 || digits.length > 15) return null;
  if (digits.startsWith('0')) return null;
  return '+$digits';
}

bool isValidMobile(String raw, {DialCountry? country}) => toE164(raw, country: country) != null;

String formatE164(String? value) {
  if (value == null || value.isEmpty) return '';
  final e164 = toE164(value) ?? value;
  final digits = digitsOnly(e164);
  for (final c in dialCountries) {
    if (digits.startsWith(c.dial) && digits.length > c.dial.length) {
      return '+${c.dial} ${digits.substring(c.dial.length)}';
    }
  }
  return e164;
}

bool looksLikeEmail(String value) => value.contains('@');
