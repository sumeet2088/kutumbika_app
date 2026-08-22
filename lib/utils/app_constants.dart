import '../services/env_service.dart';

class AppConstants {
  static EnvService get _env => EnvService.instance;

  static String get baseUrl => _env.apiBaseUrl;
  static String get apiVersion => _env.apiVersion;
  static String get apiPrefix => '/api/$apiVersion';

  static String get appInitEndpoint => '$apiPrefix/app/init';
  static String get otpSendEndpoint => '$apiPrefix/auth/otp/send';
  static String get otpVerifyEndpoint => '$apiPrefix/auth/otp/verify';
  static String get passwordLoginEndpoint => '$apiPrefix/auth/password/login';
  static String get oauthLoginEndpoint => '$apiPrefix/auth/oauth/login';
  static String get forgotSendEndpoint => '$apiPrefix/auth/password/forgot/send';
  static String get forgotResetEndpoint => '$apiPrefix/auth/password/forgot/reset';
  static String get completeDeviceLoginEndpoint =>
      '$apiPrefix/auth/device/complete-login';
  static String get refreshEndpoint => '$apiPrefix/auth/refresh';
  static String get logoutEndpoint => '$apiPrefix/logout';
  static String get deviceBindEndpoint => '$apiPrefix/device/bind';
  static String get deviceChallengeEndpoint => '$apiPrefix/device/challenge';

  static String get userDetailsEndpoint => '$apiPrefix/user/details';
  static String get userUpdateEndpoint => '$apiPrefix/user/update';
  static String get userPhotoEndpoint => '$apiPrefix/user/photo';
  static String get userOtpSendEndpoint => '$apiPrefix/user/otp/send';
  static String get userOtpVerifyEndpoint => '$apiPrefix/user/otp/verify';
  static String get passwordCreateEndpoint => '$apiPrefix/user/password/create';
  static String get passwordChangeEndpoint => '$apiPrefix/user/password/change';
  static String get userActivityEndpoint => '$apiPrefix/user/activity';
  static String get userPreferencesEndpoint => '$apiPrefix/user/preferences';
  static String get userPreferencesUpdateEndpoint =>
      '$apiPrefix/user/preferences/update';
  static String get userDeactivateEndpoint => '$apiPrefix/user/deactivate';
  static String get userDeleteEndpoint => '$apiPrefix/user/delete';
  static String get privacyConsentsEndpoint => '$apiPrefix/privacy/consents';
  static String privacyWithdrawEndpoint(String type) =>
      '$apiPrefix/privacy/consents/$type/withdraw';
  static String get privacyExportEndpoint => '$apiPrefix/privacy/export';

  static String get familyCreateEndpoint => '$apiPrefix/family/create';
  static String get familyPendingInvitesEndpoint =>
      '$apiPrefix/family/invitations/pending';
  static String familyAcceptInviteEndpoint(String ref) =>
      '$apiPrefix/family/invitations/$ref/accept';
  static String familyRejectInviteEndpoint(String ref) =>
      '$apiPrefix/family/invitations/$ref/reject';
  static String familyInviteEndpoint(String familyRef) =>
      '$apiPrefix/family/$familyRef/invitations';
  static String familyInvitesEndpoint(String familyRef) =>
      '$apiPrefix/family/$familyRef/invitations';
  static String familyMembersEndpoint(String familyRef) =>
      '$apiPrefix/family/$familyRef/members';
  static String familyMemberRoleEndpoint(String familyRef, String memberRef) =>
      '$apiPrefix/family/$familyRef/members/$memberRef/role';
  static String familyMemberRemoveEndpoint(String familyRef, String memberRef) =>
      '$apiPrefix/family/$familyRef/members/$memberRef/remove';
  static String familyActivityEndpoint(String familyRef) =>
      '$apiPrefix/family/$familyRef/activity';
  static String familyUpdateEndpoint(String familyRef) =>
      '$apiPrefix/family/$familyRef/update';
  static String familyDetailsEndpoint(String familyRef) =>
      '$apiPrefix/family/$familyRef';
  static String familyPhotoEndpoint(String familyRef) =>
      '$apiPrefix/family/$familyRef/photo';
  static String get familyMineEndpoint => '$apiPrefix/family/mine';

  static String get vehiclesEndpoint => '$apiPrefix/vehicles/';
  static String vehicleUpdateEndpoint(String ref) =>
      '$apiPrefix/vehicles/$ref/update';
  static String get insuranceEndpoint => '$apiPrefix/insurance/';
  static String insuranceUpdateEndpoint(String ref) =>
      '$apiPrefix/insurance/$ref/update';

  static String get categoriesEndpoint => '$apiPrefix/document/categories/';
  static String get documentsEndpoint => '$apiPrefix/documents/';
  static String get documentsUploadEndpoint => '$apiPrefix/documents/upload';
  static String get documentsDeletedEndpoint => '$apiPrefix/documents/deleted';
  static String documentDetailsEndpoint(String ref) =>
      '$apiPrefix/documents/$ref';
  static String documentUpdateEndpoint(String ref) =>
      '$apiPrefix/documents/$ref/update';
  static String documentDownloadEndpoint(String ref) =>
      '$apiPrefix/documents/$ref/download';
  static String documentVersionsEndpoint(String ref) =>
      '$apiPrefix/documents/$ref/versions';
  static String documentVersionDownloadEndpoint(String ref, String versionRef) =>
      '$apiPrefix/documents/$ref/versions/$versionRef/download';
  static String documentSoftDeleteEndpoint(String ref) =>
      '$apiPrefix/documents/$ref/soft-delete';
  static String documentHardDeleteEndpoint(String ref) =>
      '$apiPrefix/documents/$ref/hard-delete';
  static String documentRestoreEndpoint(String ref) =>
      '$apiPrefix/documents/$ref/restore';
  static String documentSharesEndpoint(String ref) =>
      '$apiPrefix/documents/$ref/shares';
  static String documentShareRevokeEndpoint(String ref, String shareRef) =>
      '$apiPrefix/documents/$ref/shares/$shareRef/revoke';

  static String get remindersEndpoint => '$apiPrefix/reminders/';
  static String reminderDetailsEndpoint(String ref) =>
      '$apiPrefix/reminders/$ref';
  static String reminderUpdateEndpoint(String ref) =>
      '$apiPrefix/reminders/$ref/update';
  static String reminderDeleteEndpoint(String ref) =>
      '$apiPrefix/reminders/$ref/delete';

  static String get notificationsEndpoint => '$apiPrefix/notifications/';
  static String get notificationsReadAllEndpoint =>
      '$apiPrefix/notifications/read-all';
  static String notificationReadEndpoint(int id) =>
      '$apiPrefix/notifications/$id/read';

  static String get dashboardEndpoint => '$apiPrefix/dashboard/';
  static String get searchEndpoint => '$apiPrefix/search/';
  static String get ragAskEndpoint => '$apiPrefix/rag/ask';
  static String get ragUsageEndpoint => '$apiPrefix/rag/usage';
  static String get subscriptionEndpoint => '$apiPrefix/subscription/';
  static String get subscriptionCancelEndpoint => '$apiPrefix/subscription/cancel';
  static String get subscriptionRenewEndpoint => '$apiPrefix/subscription/renew';
  static String get subscriptionPlansEndpoint => '$apiPrefix/subscription/plans/';
  static String get paymentCreateEndpoint => '$apiPrefix/subscription/payments/create';
  static String paymentStatusEndpoint(String orderRef) =>
      '$apiPrefix/subscription/payments/$orderRef';

  static const String logoAsset = 'assets/logo/paarisetu_logo.png';
  static const String logoIconAsset = 'assets/logo/paarisetu_icon.png';
  static String get appName => _env.appName;
  static const String appTagline =
      'Connecting Generations. Protecting Legacies.';
  static const String appSecureTagline =
      'Your Family. Your Documents. Always Secure.';
  static String get appVersion => _env.appVersion;
  static String get buildNumber => _env.buildNumber;

  static int get connectionTimeout => _env.apiTimeout;
  static int get otpLength => _env.otpLength;
  static int get otpResendTimer => _env.otpResendTimer;
  static int get mobileNumberLength => _env.mobileNumberLength;

  static const String visitorTokenKey = 'visitor_token';
  static const String userTokenKey = 'user_token';
  static const String visitorReferenceNumberKey = 'visitor_reference_number';
  static const String deviceReferenceNumberKey = 'device_reference_number';
  static const String userReferenceNumberKey = 'user_reference_number';
  static const String familyReferenceNumberKey = 'family_reference_number';
  static const String deviceIdKey = 'device_id';
  static const String devicePrivateKeyKey = 'device_private_d';
  static const String devicePublicKeyKey = 'device_public_key_pem';
  static const String challengeKey = 'device_challenge';
  static const String challengeRefKey = 'device_challenge_ref';

  static String get defaultLocale => _env.defaultLocale;
  static String get defaultTimezone => _env.defaultTimezone;
}
