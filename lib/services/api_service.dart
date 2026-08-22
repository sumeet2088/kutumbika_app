import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/login_result.dart';
import '../utils/app_constants.dart';
import '../utils/layout.dart';
import 'api_client.dart';
import 'device_crypto.dart';
import 'session_store.dart';

export '../models/login_result.dart';
export 'api_client.dart' show ApiException;

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final ApiClient _client = ApiClient.instance;
  final SessionStore session = SessionStore.instance;

  Future<void> initializeApp() async {
    await session.load();
    final keys = await _ensureDeviceKeys();
    final platform = _platformName();
    final data = await _client.postJson(
      AppConstants.appInitEndpoint,
      auth: AuthMode.none,
      body: {
        'platform': platform,
        'app_version': AppConstants.appVersion,
        'build_number': AppConstants.buildNumber,
        'locale': AppConstants.defaultLocale,
        'timezone': AppConstants.defaultTimezone,
        'device': {
          'type': AppLayout.detectDeviceType(),
          'device_id': session.deviceId,
          'manufacturer': _manufacturer(),
          'model': _model(),
          'os_name': _osName(),
          'os_version': _osVersion(),
        },
        'security': {
          'type': platform == 'ios' ? 'app_attest' : 'play_integrity',
          'request_hash': 'paarisetu-init',
          'integrity_token': 'dev-integrity-token',
        },
      },
    );
    await session.saveVisitor(
      token: data['token'] as String,
      visitorRef: data['visitor_reference_number'] as String,
      deviceRef: data['device_reference_number'] as String? ??
          data['device_id'] as String,
      challenge: data['challenge'] as String?,
      challengeRef: data['challenge_reference_number'] as String?,
    );
    if (data['public_key_registered'] != true &&
        session.challenge != null &&
        session.privateKeyD != null) {
      try {
        await bindDevice();
      } catch (e) {
        debugPrint('Device bind skipped: $e');
      }
    }
    debugPrint('App initialized ${keys['public_key_pem'] != null}');
  }

  Future<Map<String, String>> _ensureDeviceKeys() async {
    if (session.privateKeyD != null && session.publicKeyPem != null) {
      return {
        'public_key_pem': session.publicKeyPem!,
        'private_d': session.privateKeyD!,
      };
    }
    final keys = DeviceCrypto.generateKeyPair();
    await session.saveDeviceKeys(
      publicKeyPem: keys['public_key_pem']!,
      privateKeyD: keys['private_d']!,
    );
    return keys;
  }

  Future<Map<String, dynamic>> bindDevice({String? deviceName}) async {
    final keys = await _ensureDeviceKeys();
    final challenge = session.challenge;
    if (challenge == null || challenge.isEmpty) {
      throw ApiException('Device challenge missing');
    }
    return _client.postJson(
      AppConstants.deviceBindEndpoint,
      auth: AuthMode.visitor,
      body: {
        'public_key': keys['public_key_pem'],
        'signature': DeviceCrypto.signChallenge(keys['private_d']!, challenge),
        if (deviceName != null) 'device_name': deviceName,
      },
    );
  }

  Future<Map<String, dynamic>> issueDeviceChallenge({String? purpose}) async {
    final data = await _client.postJson(
      AppConstants.deviceChallengeEndpoint,
      auth: session.hasUser ? AuthMode.user : AuthMode.visitor,
      body: {
        if (purpose != null) 'purpose': purpose,
      },
    );
    await session.saveChallenge(
      challenge: data['challenge'] as String?,
      challengeRef: data['challenge_reference_number'] as String?,
    );
    return data;
  }

  Future<void> sendOTP({String? mobile, String? email}) {
    return _client.postJson(
      AppConstants.otpSendEndpoint,
      auth: AuthMode.visitor,
      body: {
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
      },
    );
  }

  Future<LoginResult> verifyOTP({
    required String otp,
    String? mobile,
    String? email,
  }) async {
    final data = await _client.postJson(
      AppConstants.otpVerifyEndpoint,
      auth: AuthMode.visitor,
      body: {
        'otp': otp,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        ..._deviceProofFields(),
      },
    );
    return _storeLogin(LoginResult.fromJson(data));
  }

  Future<LoginResult> loginWithPassword({
    required String password,
    String? mobile,
    String? email,
  }) async {
    final data = await _client.postJson(
      AppConstants.passwordLoginEndpoint,
      auth: AuthMode.visitor,
      body: {
        'password': password,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        ..._deviceProofFields(),
      },
    );
    return _storeLogin(LoginResult.fromJson(data));
  }

  Future<LoginResult> loginWithOAuth({
    required String provider,
    required String idToken,
  }) async {
    final data = await _client.postJson(
      AppConstants.oauthLoginEndpoint,
      auth: AuthMode.visitor,
      body: {
        'provider': provider,
        'id_token': idToken,
        ..._deviceProofFields(),
      },
    );
    return _storeLogin(LoginResult.fromJson(data));
  }

  Future<Map<String, dynamic>> sendForgotPasswordOTP(String mobile) {
    return _client.postJson(
      AppConstants.forgotSendEndpoint,
      auth: AuthMode.visitor,
      body: {'mobile': mobile},
    );
  }

  Future<Map<String, dynamic>> resetForgotPassword({
    required String mobile,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _client.postJson(
      AppConstants.forgotResetEndpoint,
      auth: AuthMode.visitor,
      body: {
        'mobile': mobile,
        'otp': otp,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<LoginResult> completeDeviceLogin({String? deviceName}) async {
    final keys = await _ensureDeviceKeys();
    final challenge = session.challenge;
    final challengeRef = session.challengeReferenceNumber;
    if (challenge == null || challengeRef == null) {
      throw ApiException('Device registration challenge missing');
    }
    final data = await _client.postJson(
      AppConstants.completeDeviceLoginEndpoint,
      auth: AuthMode.visitor,
      body: {
        'challenge_reference_number': challengeRef,
        'public_key': keys['public_key_pem'],
        'signature': DeviceCrypto.signChallenge(keys['private_d']!, challenge),
        if (deviceName != null) 'device_name': deviceName,
      },
    );
    return _storeLogin(LoginResult.fromJson(data));
  }

  Future<Map<String, dynamic>> logout() async {
    final data = await _client.postJson(
      AppConstants.logoutEndpoint,
      auth: AuthMode.user,
      body: {},
    );
    await session.clearUser();
    return data;
  }

  Future<Map<String, dynamic>> getUserDetails() {
    return _client.getJson(AppConstants.userDetailsEndpoint);
  }

  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> body) {
    return _client.postJson(AppConstants.userUpdateEndpoint, body: body);
  }

  Future<Map<String, dynamic>> uploadUserPhoto(File photo) {
    return _client.postMultipart(
      AppConstants.userPhotoEndpoint,
      fields: const {},
      files: {'profile_photo': photo},
    );
  }

  Future<Uint8List> getUserPhoto() {
    return _client.getBytes(AppConstants.userPhotoEndpoint);
  }

  Future<Map<String, dynamic>> sendUserOTP({String? mobile, String? email}) {
    return _client.postJson(
      AppConstants.userOtpSendEndpoint,
      body: {
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
      },
    );
  }

  Future<Map<String, dynamic>> verifyUserOTP({
    required String otp,
    String? mobile,
    String? email,
  }) {
    return _client.postJson(
      AppConstants.userOtpVerifyEndpoint,
      body: {
        'otp': otp,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
      },
    );
  }

  Future<Map<String, dynamic>> createPassword({
    required String password,
    required String confirmPassword,
  }) {
    return _client.postJson(
      AppConstants.passwordCreateEndpoint,
      body: {'password': password, 'confirm_password': confirmPassword},
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _client.postJson(
      AppConstants.passwordChangeEndpoint,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  Future<Map<String, dynamic>> getUserActivity({String? cursor}) {
    return _client.getJson(
      AppConstants.userActivityEndpoint,
      query: {
        'limit': '20',
        if (cursor != null) 'cursor': cursor,
      },
    );
  }

  Future<Map<String, dynamic>> getPreferences() {
    return _client.getJson(AppConstants.userPreferencesEndpoint);
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body) {
    return _client.postJson(AppConstants.userPreferencesUpdateEndpoint,
        body: body);
  }

  Future<Map<String, dynamic>> deactivateAccount() {
    return _client.postJson(
      AppConstants.userDeactivateEndpoint,
      body: {'confirm': true},
    );
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final data = await _client.postJson(
      AppConstants.userDeleteEndpoint,
      body: {'confirm': true},
    );
    await session.clearAll();
    return data;
  }

  Future<Map<String, dynamic>> createFamily({
    required String familyName,
    File? photo,
  }) async {
    final data = await _client.postMultipart(
      AppConstants.familyCreateEndpoint,
      fields: {'family_name': familyName},
      files: photo == null ? {} : {'family_photo': photo},
    );
    await session.saveFamily(data['family_reference_number'] as String?);
    return data;
  }

  Future<Map<String, dynamic>> updateFamily({
    required String familyRef,
    String? familyName,
    File? photo,
  }) {
    return _client.postMultipart(
      AppConstants.familyUpdateEndpoint(familyRef),
      fields: {
        if (familyName != null) 'family_name': familyName,
      },
      files: photo == null ? {} : {'family_photo': photo},
    );
  }

  Future<Map<String, dynamic>> getFamilyDetails(String familyRef) {
    return _client.getJson(AppConstants.familyDetailsEndpoint(familyRef));
  }

  Future<Uint8List> getFamilyPhoto(String familyRef) {
    return _client.getBytes(AppConstants.familyPhotoEndpoint(familyRef));
  }

  Future<Map<String, dynamic>> inviteFamilyMember({
    required String familyRef,
    required String mobile,
    required String role,
    required String relation,
    String? email,
  }) {
    return _client.postJson(
      AppConstants.familyInviteEndpoint(familyRef),
      body: {
        'mobile': mobile,
        'role': role,
        'relation': relation,
        if (email != null) 'email': email,
      },
    );
  }

  Future<Map<String, dynamic>> listFamilyInvitations(String familyRef) {
    return _client.getJson(AppConstants.familyInvitesEndpoint(familyRef));
  }

  Future<Map<String, dynamic>> listPendingInvitations() {
    return _client.getJson(AppConstants.familyPendingInvitesEndpoint);
  }

  Future<Map<String, dynamic>> listMyFamilies() {
    return _client.getJson(AppConstants.familyMineEndpoint);
  }

  Future<Map<String, dynamic>> acceptInvitation(String invitationRef) async {
    final data = await _client.postJson(
      AppConstants.familyAcceptInviteEndpoint(invitationRef),
      body: {},
    );
    final familyRef = data['parent_family_reference_number'] as String? ??
        data['own_family_reference_number'] as String?;
    if (familyRef != null) await session.saveFamily(familyRef);
    return data;
  }

  Future<Map<String, dynamic>> rejectInvitation(String invitationRef) {
    return _client.postJson(
      AppConstants.familyRejectInviteEndpoint(invitationRef),
      body: {},
    );
  }

  Future<Map<String, dynamic>> listFamilyMembers(
    String familyRef, {
    String filter = 'active',
  }) {
    return _client.getJson(
      AppConstants.familyMembersEndpoint(familyRef),
      query: {'filter': filter, 'limit': '50'},
    );
  }

  Future<Map<String, dynamic>> changeMemberRole({
    required String familyRef,
    required String memberRef,
    required String role,
  }) {
    return _client.postJson(
      AppConstants.familyMemberRoleEndpoint(familyRef, memberRef),
      body: {'role': role},
    );
  }

  Future<Map<String, dynamic>> removeMember({
    required String familyRef,
    required String memberRef,
  }) {
    return _client.postJson(
      AppConstants.familyMemberRemoveEndpoint(familyRef, memberRef),
      body: {},
    );
  }

  Future<Map<String, dynamic>> listFamilyActivity(String familyRef) {
    return _client.getJson(
      AppConstants.familyActivityEndpoint(familyRef),
      query: {'limit': '50'},
    );
  }

  Future<Map<String, dynamic>> listCategories() {
    return _client.getJson(AppConstants.categoriesEndpoint);
  }

  Future<Map<String, dynamic>> listDocuments({
    String? cursor,
    String? familyRef,
  }) {
    return _client.getJson(
      AppConstants.documentsEndpoint,
      query: {
        'limit': '50',
        if (cursor != null) 'cursor': cursor,
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
  }

  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String categoryRef,
    required String familyRef,
    String? title,
    String? description,
    String? remarks,
    String? documentType,
    bool allowAI = false,
    bool authorizedFamilyData = false,
  }) {
    return _client.postMultipart(
      AppConstants.documentsUploadEndpoint,
      fields: {
        'document_category_reference_number': categoryRef,
        'family_reference_number': familyRef,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (remarks != null) 'remarks': remarks,
        if (documentType != null) 'document_type': documentType,
        'allow_ai_processing': allowAI ? 'true' : 'false',
        'authorized_family_data': authorizedFamilyData ? 'true' : 'false',
      },
      files: {'file': file},
    );
  }

  Future<Map<String, dynamic>> listConsents() {
    return _client.getJson(AppConstants.privacyConsentsEndpoint);
  }

  Future<Map<String, dynamic>> updateConsents(List<Map<String, dynamic>> consents) {
    return _client.postJson(
      AppConstants.privacyConsentsEndpoint,
      body: {'consents': consents, 'source': 'APP'},
    );
  }

  Future<Map<String, dynamic>> withdrawConsent(String type) {
    return _client.postJson(
      AppConstants.privacyWithdrawEndpoint(type),
      body: {'source': 'APP'},
    );
  }

  Future<Map<String, dynamic>> exportMyData() {
    return _client.getJson(AppConstants.privacyExportEndpoint);
  }

  Future<Map<String, dynamic>> updateDocument({
    required String documentRef,
    File? file,
    String? title,
    String? remarks,
  }) {
    return _client.postMultipart(
      AppConstants.documentUpdateEndpoint(documentRef),
      fields: {
        if (title != null) 'title': title,
        if (remarks != null) 'remarks': remarks,
      },
      files: file == null ? {} : {'file': file},
    );
  }

  Future<Map<String, dynamic>> getDocument(String documentRef) {
    return _client.getJson(AppConstants.documentDetailsEndpoint(documentRef));
  }

  Future<Uint8List> downloadDocument(String documentRef) {
    return _client.getBytes(AppConstants.documentDownloadEndpoint(documentRef));
  }

  Future<Map<String, dynamic>> listDocumentVersions(String documentRef) {
    return _client.getJson(AppConstants.documentVersionsEndpoint(documentRef));
  }

  Future<Uint8List> downloadDocumentVersion(
      String documentRef, String versionRef) {
    return _client.getBytes(
      AppConstants.documentVersionDownloadEndpoint(documentRef, versionRef),
    );
  }

  Future<Map<String, dynamic>> softDeleteDocument(
      String documentRef, String reason) {
    return _client.postJson(
      AppConstants.documentSoftDeleteEndpoint(documentRef),
      body: {'delete_reason': reason},
    );
  }

  Future<Map<String, dynamic>> hardDeleteDocument(
      String documentRef, String reason) {
    return _client.postJson(
      AppConstants.documentHardDeleteEndpoint(documentRef),
      body: {'delete_reason': reason},
    );
  }

  Future<Map<String, dynamic>> restoreDocument(String documentRef) {
    return _client.postJson(
      AppConstants.documentRestoreEndpoint(documentRef),
      body: {},
    );
  }

  Future<Map<String, dynamic>> listDeletedDocuments({String? familyRef}) {
    return _client.getJson(
      AppConstants.documentsDeletedEndpoint,
      query: {
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
  }

  Future<Map<String, dynamic>> getSubscription({String? familyRef}) {
    return _client.getJson(
      AppConstants.subscriptionEndpoint,
      query: {
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
  }

  Future<Map<String, dynamic>> cancelSubscription({String? subscriptionRef}) {
    return _client.postJson(
      AppConstants.subscriptionCancelEndpoint,
      query: {
        if (session.familyReferenceNumber != null)
          'family_reference_number': session.familyReferenceNumber!,
      },
      body: {
        if (subscriptionRef != null)
          'subscription_reference_number': subscriptionRef,
      },
    );
  }

  Future<Map<String, dynamic>> renewSubscription() {
    return _client.postJson(
      AppConstants.subscriptionRenewEndpoint,
      query: {
        if (session.familyReferenceNumber != null)
          'family_reference_number': session.familyReferenceNumber!,
      },
      body: {},
    );
  }

  Future<Map<String, dynamic>> listPlans() {
    return _client.getJson(AppConstants.subscriptionPlansEndpoint);
  }

  Future<Map<String, dynamic>> createPayment({required String planRef}) {
    return _client.postJson(
      AppConstants.paymentCreateEndpoint,
      body: {
        'plan_reference_number': planRef,
        if (session.familyReferenceNumber != null)
          'family_reference_number': session.familyReferenceNumber,
      },
    );
  }

  Future<Map<String, dynamic>> paymentStatus(String orderRef) {
    return _client.getJson(AppConstants.paymentStatusEndpoint(orderRef));
  }

  Future<Map<String, dynamic>> createShare({
    required String documentRef,
    required String permission,
    String? mobile,
    String? email,
    String? userRef,
  }) {
    return _client.postJson(
      AppConstants.documentSharesEndpoint(documentRef),
      body: {
        'permission': permission,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        if (userRef != null) 'user_reference_number': userRef,
      },
    );
  }

  Future<Map<String, dynamic>> listShares(String documentRef) {
    return _client.getJson(AppConstants.documentSharesEndpoint(documentRef));
  }

  Future<Map<String, dynamic>> revokeShare(
      String documentRef, String shareRef) {
    return _client.postJson(
      AppConstants.documentShareRevokeEndpoint(documentRef, shareRef),
      body: {},
    );
  }

  Future<Map<String, dynamic>> createReminder({
    required String title,
    required String reminderDate,
    required String reminderTime,
    String repeatType = 'NONE',
    String? documentRef,
    String? notes,
  }) {
    return _client.postJson(
      AppConstants.remindersEndpoint,
      body: {
        'title': title,
        'reminder_date': reminderDate,
        'reminder_time': reminderTime,
        'repeat_type': repeatType,
        if (documentRef != null) 'document_reference_number': documentRef,
        if (notes != null) 'notes': notes,
      },
    );
  }

  Future<Map<String, dynamic>> listReminders({String filter = 'all'}) {
    return _client.getJson(
      AppConstants.remindersEndpoint,
      query: {'filter': filter, 'limit': '50'},
    );
  }

  Future<Map<String, dynamic>> getReminder(String reminderRef) {
    return _client.getJson(AppConstants.reminderDetailsEndpoint(reminderRef));
  }

  Future<Map<String, dynamic>> updateReminder(
    String reminderRef,
    Map<String, dynamic> body,
  ) {
    return _client.postJson(
      AppConstants.reminderUpdateEndpoint(reminderRef),
      body: body,
    );
  }

  Future<Map<String, dynamic>> deleteReminder(String reminderRef) {
    return _client.postJson(
      AppConstants.reminderDeleteEndpoint(reminderRef),
      body: {},
    );
  }

  Future<Map<String, dynamic>> listNotifications({String filter = 'all'}) {
    return _client.getJson(
      AppConstants.notificationsEndpoint,
      query: {'filter': filter, 'limit': '50'},
    );
  }

  Future<Map<String, dynamic>> markNotificationRead(int id) {
    return _client.postJson(
      AppConstants.notificationReadEndpoint(id),
      body: {},
    );
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() {
    return _client.postJson(
      AppConstants.notificationsReadAllEndpoint,
      body: {},
    );
  }

  Future<Map<String, dynamic>> searchVault({
    required String query,
    String? familyRef,
  }) {
    return _client.getJson(
      AppConstants.searchEndpoint,
      query: {
        'q': query,
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
  }

  Future<Map<String, dynamic>> askRAG({
    required String question,
    String? familyRef,
    String? documentRef,
  }) {
    return _client.postJson(
      AppConstants.ragAskEndpoint,
      body: {
        'question': question,
        if (familyRef != null) 'family_reference_number': familyRef,
        if (documentRef != null) 'document_reference_number': documentRef,
      },
    );
  }

  Future<Map<String, dynamic>> ragUsage({String? familyRef}) {
    return _client.getJson(
      AppConstants.ragUsageEndpoint,
      query: {
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
  }

  Future<Map<String, dynamic>> getDashboard({String? familyRef}) async {
    final data = await _client.getJson(
      AppConstants.dashboardEndpoint,
      query: {
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
    final ref = data['family_reference_number'] as String?;
    if (ref != null && ref.isNotEmpty) {
      await session.saveFamily(ref);
    }
    return data;
  }

  Map<String, dynamic> _deviceProofFields() {
    if (session.publicKeyPem == null || session.privateKeyD == null) {
      return {'device_name': AppLayout.deviceDisplayName()};
    }
    final challenge = session.challenge;
    if (challenge == null || challenge.isEmpty) {
      return {
        'public_key': session.publicKeyPem,
        'device_name': AppLayout.deviceDisplayName(),
      };
    }
    return {
      'public_key': session.publicKeyPem,
      'device_signature':
          DeviceCrypto.signChallenge(session.privateKeyD!, challenge),
      'device_name': AppLayout.deviceDisplayName(),
    };
  }

  Future<LoginResult> _storeLogin(LoginResult result) async {
    if (result.challenge != null) {
      await session.saveChallenge(
        challenge: result.challenge,
        challengeRef: result.challengeReferenceNumber,
      );
    }
    if (result.hasSession) {
      await session.saveUser(
        token: result.token!,
        userRef: result.userReferenceNumber,
        deviceRef: result.deviceReferenceNumber,
      );
    } else if (result.userReferenceNumber != null) {
      session.userReferenceNumber = result.userReferenceNumber;
    }
    return result;
  }

  Future<Map<String, dynamic>> listVehicles({String? familyRef}) {
    return _client.getJson(
      AppConstants.vehiclesEndpoint,
      query: {
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
  }

  Future<Map<String, dynamic>> createVehicle({
    required String familyRef,
    String? make,
    String? model,
    String? registrationNumber,
    int? year,
    String? rcDocumentRef,
  }) {
    return _client.postJson(
      AppConstants.vehiclesEndpoint,
      body: {
        'family_reference_number': familyRef,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (registrationNumber != null) 'registration_number': registrationNumber,
        if (year != null) 'year': year,
        if (rcDocumentRef != null) 'rc_document_reference_number': rcDocumentRef,
      },
    );
  }

  Future<Map<String, dynamic>> listInsurance({String? familyRef}) {
    return _client.getJson(
      AppConstants.insuranceEndpoint,
      query: {
        if (familyRef != null) 'family_reference_number': familyRef,
      },
    );
  }

  Future<Map<String, dynamic>> createInsurance({
    required String familyRef,
    String? provider,
    String? policyNumber,
    String? startDate,
    String? expiryDate,
    String? vehicleRef,
    String? documentRef,
  }) {
    return _client.postJson(
      AppConstants.insuranceEndpoint,
      body: {
        'family_reference_number': familyRef,
        if (provider != null) 'provider': provider,
        if (policyNumber != null) 'policy_number': policyNumber,
        if (startDate != null) 'start_date': startDate,
        if (expiryDate != null) 'expiry_date': expiryDate,
        if (vehicleRef != null) 'vehicle_reference_number': vehicleRef,
        if (documentRef != null) 'document_reference_number': documentRef,
      },
    );
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'android';
  }

  String _osName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }

  String _osVersion() => kIsWeb ? 'Browser' : Platform.operatingSystemVersion;

  String _manufacturer() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'Apple';
    if (Platform.isAndroid) return 'Android';
    return 'Unknown';
  }

  String _model() {
    if (kIsWeb) return 'Browser';
    if (Platform.isIOS) return 'iPhone';
    return 'Phone';
  }
}
