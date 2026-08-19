class LoginResult {
  LoginResult({
    this.token,
    this.isNewUser = false,
    this.isNewDevice = false,
    this.requiresDeviceRegistration = false,
    this.challenge,
    this.challengeReferenceNumber,
    this.userReferenceNumber,
    this.deviceReferenceNumber,
    this.message,
  });

  final String? token;
  final bool isNewUser;
  final bool isNewDevice;
  final bool requiresDeviceRegistration;
  final String? challenge;
  final String? challengeReferenceNumber;
  final String? userReferenceNumber;
  final String? deviceReferenceNumber;
  final String? message;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String?,
      isNewUser: json['is_new_user'] == true,
      isNewDevice: json['is_new_device'] == true,
      requiresDeviceRegistration: json['requires_device_registration'] == true,
      challenge: json['challenge'] as String?,
      challengeReferenceNumber: json['challenge_reference_number'] as String?,
      userReferenceNumber: json['user_reference_number'] as String?,
      deviceReferenceNumber: json['device_reference_number'] as String?,
      message: json['message'] as String?,
    );
  }

  bool get hasSession => token != null && token!.isNotEmpty;
}
