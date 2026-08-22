import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'payload_crypto.dart';

class EnvService {
  static EnvService? _instance;
  static EnvService get instance => _instance ??= EnvService._internal();

  EnvService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: ".env");
      debugPrint('Environment variables loaded successfully');
      _initialized = true;
    } catch (e) {
      debugPrint('Failed to load .env file, using default values: $e');
      _initialized = true;
    }
    PayloadCrypto.configure(payloadEncryptionKey);
    debugPrint('API_BASE_URL resolved to $apiBaseUrl');
    debugPrint('Payload encryption ${PayloadCrypto.enabled ? 'enabled' : 'disabled'}');
  }

  String _getEnvVar(String key, String defaultValue) {
    try {
      return dotenv.env[key] ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  // API Configuration
  String get apiBaseUrl {
    final url = _getEnvVar('API_BASE_URL', 'http://127.0.0.1:8080');
    // If running on Android Emulator and pointing to localhost, use 10.0.2.2
    if (!kIsWeb && Platform.isAndroid && (url.contains('127.0.0.1') || url.contains('localhost'))) {
      return url.replaceAll('127.0.0.1', '127.0.0.1').replaceAll('localhost', '127.0.0.1');
    }
    return url;
  }
  String get apiVersion => _getEnvVar('API_VERSION', 'v1');
  int get apiTimeout => int.tryParse(_getEnvVar('API_TIMEOUT', '30')) ?? 30;
  String get payloadEncryptionKey => _getEnvVar('PAYLOAD_ENCRYPTION_KEY', '');

  // App Configuration
  String get appName => _getEnvVar('APP_NAME', 'Paarisetu');
  String get appVersion => _getEnvVar('APP_VERSION', '1.0.0');
  String get buildNumber => _getEnvVar('BUILD_NUMBER', '1');

  // Locale Configuration
  String get defaultLocale => _getEnvVar('DEFAULT_LOCALE', 'en-IN');
  String get defaultTimezone => _getEnvVar('DEFAULT_TIMEZONE', 'Asia/Kolkata');

  // OTP Configuration
  int get otpLength => int.tryParse(_getEnvVar('OTP_LENGTH', '6')) ?? 6;
  int get otpResendTimer =>
      int.tryParse(_getEnvVar('OTP_RESEND_TIMER', '30')) ?? 30;
  int get mobileNumberLength =>
      int.tryParse(_getEnvVar('MOBILE_NUMBER_LENGTH', '10')) ?? 10;

  // Feature Flags
  bool get enableAnalytics => _getEnvVar('ENABLE_ANALYTICS', 'false') == 'true';
  bool get enableCrashReporting =>
      _getEnvVar('ENABLE_CRASH_REPORTING', 'false') == 'true';
  bool get enableLogging => _getEnvVar('ENABLE_LOGGING', 'true') == 'true';

  // Storage Configuration
  bool get secureStorageEnabled =>
      _getEnvVar('SECURE_STORAGE_ENABLED', 'true') == 'true';
  bool get sharedPreferencesEnabled =>
      _getEnvVar('SHARED_PREFERENCES_ENABLED', 'true') == 'true';

  // Helper method to check if environment is loaded
  bool get isInitialized => _initialized;
}
