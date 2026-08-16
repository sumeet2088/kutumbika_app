import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080'; // API Gateway URL
  static const String appInitEndpoint = '/api/v1/app/init';
  
  String? _visitorToken;
  String? _userToken;
  String? _visitorReferenceNumber;
  String? _deviceReferenceNumber;

  // Getters for tokens
  String? get visitorToken => _visitorToken;
  String? get userToken => _userToken;
  String? get visitorReferenceNumber => _visitorReferenceNumber;
  String? get deviceReferenceNumber => _deviceReferenceNumber;

  // Initialize app by calling /app/init endpoint
  Future<void> initializeApp() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$appInitEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'X-Request-ID': _generateRequestId(),
        },
        body: jsonEncode({
          'platform': 'android',
          'app_version': '1.0.0',
          'build_number': '1',
          'locale': 'en-IN',
          'timezone': 'Asia/Kolkata',
          'device': {
            'type': 'phone',
            'device_id': 'device-demo-001',
            'manufacturer': 'Google',
            'model': 'Pixel',
            'os_name': 'Android',
            'os_version': '14'
          },
          'security': {
            'type': 'play_integrity',
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
        print('App initialized successfully');
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
        Uri.parse('$baseUrl/api/v1/auth/otp/send'),
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
        Uri.parse('$baseUrl/api/v1/auth/otp/verify'),
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
        Uri.parse('$baseUrl/api/v1/user/details'),
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
        Uri.parse('$baseUrl/api/v1/documents'),
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

  // Generate unique request ID
  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
