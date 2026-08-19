import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_constants.dart';

class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? visitorToken;
  String? userToken;
  String? visitorReferenceNumber;
  String? deviceReferenceNumber;
  String? userReferenceNumber;
  String? familyReferenceNumber;
  String? deviceId;
  String? publicKeyPem;
  String? privateKeyD;
  String? challenge;
  String? challengeReferenceNumber;

  bool get hasUser => userToken != null && userToken!.isNotEmpty;
  bool get hasVisitor => visitorToken != null && visitorToken!.isNotEmpty;

  Future<void> load() async {
    visitorToken = await _storage.read(key: AppConstants.visitorTokenKey);
    userToken = await _storage.read(key: AppConstants.userTokenKey);
    visitorReferenceNumber =
        await _storage.read(key: AppConstants.visitorReferenceNumberKey);
    deviceReferenceNumber =
        await _storage.read(key: AppConstants.deviceReferenceNumberKey);
    userReferenceNumber =
        await _storage.read(key: AppConstants.userReferenceNumberKey);
    familyReferenceNumber =
        await _storage.read(key: AppConstants.familyReferenceNumberKey);
    deviceId = await _storage.read(key: AppConstants.deviceIdKey);
    publicKeyPem = await _storage.read(key: AppConstants.devicePublicKeyKey);
    privateKeyD = await _storage.read(key: AppConstants.devicePrivateKeyKey);
    challenge = await _storage.read(key: AppConstants.challengeKey);
    challengeReferenceNumber =
        await _storage.read(key: AppConstants.challengeRefKey);

    if (deviceId == null || deviceId!.isEmpty) {
      deviceId = const Uuid().v4();
      await _storage.write(key: AppConstants.deviceIdKey, value: deviceId);
    }
  }

  Future<void> _write(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  Future<void> saveVisitor({
    required String token,
    required String visitorRef,
    required String deviceRef,
    String? challenge,
    String? challengeRef,
  }) async {
    visitorToken = token;
    visitorReferenceNumber = visitorRef;
    deviceReferenceNumber = deviceRef;
    this.challenge = challenge;
    challengeReferenceNumber = challengeRef;
    await _write(AppConstants.visitorTokenKey, token);
    await _write(AppConstants.visitorReferenceNumberKey, visitorRef);
    await _write(AppConstants.deviceReferenceNumberKey, deviceRef);
    await _write(AppConstants.challengeKey, challenge);
    await _write(AppConstants.challengeRefKey, challengeRef);
  }

  Future<void> saveUser({
    required String token,
    String? userRef,
    String? deviceRef,
  }) async {
    userToken = token;
    if (userRef != null) userReferenceNumber = userRef;
    if (deviceRef != null) deviceReferenceNumber = deviceRef;
    await _write(AppConstants.userTokenKey, token);
    await _write(AppConstants.userReferenceNumberKey, userReferenceNumber);
    await _write(AppConstants.deviceReferenceNumberKey, deviceReferenceNumber);
  }

  Future<void> saveFamily(String? familyRef) async {
    familyReferenceNumber = familyRef;
    await _write(AppConstants.familyReferenceNumberKey, familyRef);
  }

  Future<void> saveDeviceKeys({
    required String publicKeyPem,
    required String privateKeyD,
  }) async {
    this.publicKeyPem = publicKeyPem;
    this.privateKeyD = privateKeyD;
    await _write(AppConstants.devicePublicKeyKey, publicKeyPem);
    await _write(AppConstants.devicePrivateKeyKey, privateKeyD);
  }

  Future<void> saveChallenge({String? challenge, String? challengeRef}) async {
    this.challenge = challenge;
    challengeReferenceNumber = challengeRef;
    await _write(AppConstants.challengeKey, challenge);
    await _write(AppConstants.challengeRefKey, challengeRef);
  }

  Future<void> clearUser() async {
    userToken = null;
    userReferenceNumber = null;
    familyReferenceNumber = null;
    await _storage.delete(key: AppConstants.userTokenKey);
    await _storage.delete(key: AppConstants.userReferenceNumberKey);
    await _storage.delete(key: AppConstants.familyReferenceNumberKey);
  }

  Future<void> clearAll() async {
    await clearUser();
    visitorToken = null;
    visitorReferenceNumber = null;
    deviceReferenceNumber = null;
    challenge = null;
    challengeReferenceNumber = null;
    await _storage.delete(key: AppConstants.visitorTokenKey);
    await _storage.delete(key: AppConstants.visitorReferenceNumberKey);
    await _storage.delete(key: AppConstants.deviceReferenceNumberKey);
    await _storage.delete(key: AppConstants.challengeKey);
    await _storage.delete(key: AppConstants.challengeRefKey);
  }
}
