import '../services/env_service.dart';

class AppConstants {
  static EnvService get _env => EnvService.instance;

  // API Configuration
  static String get baseUrl => _env.apiBaseUrl;
  static String get apiVersion => _env.apiVersion;
  static String get apiPrefix => '/api/$apiVersion';

  // API Endpoints
  static String get appInitEndpoint => '$apiPrefix/app/init';
  static String get otpSendEndpoint => '$apiPrefix/auth/otp/send';
  static String get otpVerifyEndpoint => '$apiPrefix/auth/otp/verify';
  static String get userDetailsEndpoint => '$apiPrefix/user/details';
  static String get documentsEndpoint => '$apiPrefix/documents';
  static String get logoutEndpoint => '$apiPrefix/auth/logout';

  // App Configuration
  static String get appName => _env.appName;
  static const String appTagline =
      'Everything Your Family Needs. One Secure Place.';
  static String get appVersion => _env.appVersion;
  static String get buildNumber => _env.buildNumber;

  // Timeout Configuration
  static int get connectionTimeout => _env.apiTimeout; // seconds
  static int get receiveTimeout => _env.apiTimeout; // seconds
  static int get sendTimeout => _env.apiTimeout; // seconds

  // OTP Configuration
  static int get otpLength => _env.otpLength;
  static int get otpResendTimer => _env.otpResendTimer; // seconds
  static int get mobileNumberLength => _env.mobileNumberLength;

  // Storage Keys
  static const String visitorTokenKey = 'visitor_token';
  static const String userTokenKey = 'user_token';
  static const String visitorReferenceNumberKey = 'visitor_reference_number';
  static const String deviceReferenceNumberKey = 'device_reference_number';
  static const String isFirstLaunchKey = 'is_first_launch';

  // Default Locale
  static String get defaultLocale => _env.defaultLocale;
  static String get defaultTimezone => _env.defaultTimezone;

  // Feature Flags
  static bool get enableAnalytics => _env.enableAnalytics;
  static bool get enableCrashReporting => _env.enableCrashReporting;
  static bool get enableLogging => _env.enableLogging;
  static bool get secureStorageEnabled => _env.secureStorageEnabled;
  static bool get sharedPreferencesEnabled => _env.sharedPreferencesEnabled;
}
