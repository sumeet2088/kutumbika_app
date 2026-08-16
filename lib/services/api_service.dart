import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_constants.dart';

class ApiService {
  String? _visitorToken;
  String? _userToken;
  String? _visitorReferenceNumber;
  String? _deviceReferenceNumber;

  // Getters for tokens
  String? get visitorToken => _visitorToken;
  String? get userToken => _userToken;
  String? get visitorReferenceNumber => _visitorReferenceNumber;
  String? get deviceReferenceNumber => _deviceReferenceNumber;

  // Check if user is authenticated
  bool get isAuthenticated => _userToken != null;

  // Set tokens (useful for persistence)
  void setTokens({
    String? visitorToken,
    String? userToken,
    String? visitorReferenceNumber,
    String? deviceReferenceNumber,
  }) {
    if (visitorToken != null) {
      _visitorToken = visitorToken;
    }
    if (userToken != null) {
      _userToken = userToken;
    }
    if (visitorReferenceNumber != null) {
      _visitorReferenceNumber = visitorReferenceNumber;
    }
    if (deviceReferenceNumber != null) {
      _deviceReferenceNumber = deviceReferenceNumber;
    }
  }

  // Clear all tokens
  void clearTokens() {
    _visitorToken = null;
    _userToken = null;
    _visitorReferenceNumber = null;
    _deviceReferenceNumber = null;
  }

  // Get platform information
  Map<String, dynamic> _getPlatformInfo() {
    if (kIsWeb) {
      return {
        'platform': 'web',
        'os_name': 'Web',
        'os_version': 'Browser',
      };
    } else {
      if (Platform.isAndroid) {
        return {
          'platform': 'android',
          'os_name': 'Android',
          'os_version': 'Unknown',
        };
      } else {
        if (Platform.isIOS) {
          return {
            'platform': 'ios',
            'os_name': 'iOS',
            'os_version': 'Unknown',
          };
        } else {
          // Default fallback
          return {
            'platform': 'unknown',
            'os_name': 'Unknown',
            'os_version': 'Unknown',
          };
        }
      }
    }
  }

  // Initialize app by calling /app/init endpoint
  Future<void> initializeApp() async {
    try {
      final platformInfo = _getPlatformInfo();
      final url = '${AppConstants.baseUrl}${AppConstants.appInitEndpoint}';
      debugPrint('Initializing app at URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': _generateRequestId(),
        },
        body: jsonEncode({
          'platform': platformInfo['platform'],
          'app_version': AppConstants.appVersion,
          'build_number': AppConstants.buildNumber,
          'locale': AppConstants.defaultLocale,
          'timezone': AppConstants.defaultTimezone,
          'device': {
            'type': 'phone',
            'device_id': 'device-demo-001',
            'manufacturer': 'Unknown',
            'model': 'Unknown',
            'os_name': platformInfo['os_name'],
            'os_version': platformInfo['os_version']
          },
          'security': {
            'type': kIsWeb ? 'web' : 'play_integrity',
            'request_hash': 'demo-hash',
            'integrity_token': 'demo-integrity-token'
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _visitorToken = responseData['token'];
        _visitorReferenceNumber = responseData['visitor_reference_number'];
        _deviceReferenceNumber = responseData['device_reference_number'];
        debugPrint('App initialized successfully');
      } else {
        throw Exception('Failed to initialize app: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during app initialization: $e');
    }
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOTP(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.otpSendEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': _generateRequestId(),
          'Authorization': 'Bearer $_visitorToken',
        },
        body: jsonEncode({'mobile': mobile}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send OTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending OTP: $e');
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String mobile, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.otpVerifyEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': _generateRequestId(),
          'Authorization': 'Bearer $_visitorToken',
        },
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _userToken = responseData['token'];
        return responseData;
      } else {
        throw Exception('Failed to verify OTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying OTP: $e');
    }
  }

  // Get user details
  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.userDetailsEndpoint}'),
        headers: {
          'X-Request-ID': _generateRequestId(),
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting user details: $e');
    }
  }

  // Get documents list
  Future<Map<String, dynamic>> getDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.documentsEndpoint}'),
        headers: {
          'X-Request-ID': _generateRequestId(),
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get documents: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting documents: $e');
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.logoutEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': _generateRequestId(),
          'Authorization': 'Bearer $_userToken',
        },
      );

      if (response.statusCode == 200) {
        _userToken = null;
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to logout: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during logout: $e');
    }
  }

  // Generate unique request ID
  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
