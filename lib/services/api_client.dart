import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/app_constants.dart';
import 'payload_crypto.dart';
import 'session_store.dart';

enum AuthMode { none, visitor, user, refresh }

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode = 0, this.type});

  final String message;
  final int statusCode;
  final String? type;

  bool get isUnauthorized => statusCode == 401 || type == 'UNAUTHORIZED';

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final SessionStore _session = SessionStore.instance;
  bool _refreshing = false;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({
    required AuthMode auth,
    bool json = true,
    String? overrideToken,
  }) {
    final headers = <String, String>{
      'X-Request-ID':
          'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      'Accept': 'application/json',
    };
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final token = overrideToken ??
        (auth == AuthMode.visitor
            ? _session.visitorToken
            : (auth == AuthMode.user || auth == AuthMode.refresh)
                ? _session.userToken
                : null);
    if (token != null && token.isNotEmpty && auth != AuthMode.none) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    AuthMode auth = AuthMode.user,
    Map<String, String>? query,
  }) {
    return _json('GET', path, auth: auth, query: query);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    AuthMode auth = AuthMode.user,
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) {
    return _json('POST', path, auth: auth, body: body, query: query);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    AuthMode auth = AuthMode.user,
    Map<String, String> fields = const {},
    Map<String, File> files = const {},
  }) async {
    return _send(
      'POST',
      path,
      auth: auth,
      jsonContent: false,
      body: {'fields': fields, 'files': files.keys.toList()},
      request: (headers) async {
        final req = http.MultipartRequest('POST', _uri(path));
        req.headers.addAll(headers);
        req.fields.addAll(fields);
        for (final entry in files.entries) {
          req.files.add(await http.MultipartFile.fromPath(
            entry.key,
            entry.value.path,
            filename: entry.value.path.split(RegExp(r'[\\/]')).last,
          ));
        }
        final streamed = await req.send().timeout(
              Duration(seconds: AppConstants.connectionTimeout),
            );
        return http.Response.fromStream(streamed);
      },
    );
  }

  Future<Uint8List> getBytes(
    String path, {
    AuthMode auth = AuthMode.user,
  }) async {
    final response = await _raw(
      'GET',
      path,
      auth: auth,
      jsonContent: false,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw _fromResponse(response);
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    required AuthMode auth,
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) {
    return _send(
      method,
      path,
      auth: auth,
      body: body,
      request: (headers) {
        final url = _uri(path, query);
        final payload = body == null ? null : PayloadCrypto.seal(body);
        final encoded = payload == null ? null : jsonEncode(payload);
        if (method == 'GET') {
          return http.get(url, headers: headers).timeout(
                Duration(seconds: AppConstants.connectionTimeout),
              );
        }
        return http
            .post(url, headers: headers, body: encoded)
            .timeout(Duration(seconds: AppConstants.connectionTimeout));
      },
    );
  }

  Future<http.Response> _raw(
    String method,
    String path, {
    required AuthMode auth,
    bool jsonContent = true,
  }) async {
    final headers = _headers(auth: auth, json: jsonContent);
    final url = _uri(path);
    _logRequest(method, url, headers, null);
    final response = await http.get(url, headers: headers).timeout(
          Duration(seconds: AppConstants.connectionTimeout),
        );
    _logResponse(method, url, response);
    return response;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    required AuthMode auth,
    required Future<http.Response> Function(Map<String, String> headers) request,
    Object? body,
    bool jsonContent = true,
    bool retried = false,
  }) async {
    final headers = _headers(auth: auth, json: jsonContent);
    final url = _uri(path);
    _logRequest(method, url, headers, body);
    final response = await request(headers);
    _logResponse(method, url, response);

    if (response.statusCode == 401 &&
        auth == AuthMode.user &&
        !retried &&
        _session.userToken != null) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        return _send(
          method,
          path,
          auth: auth,
          request: request,
          body: body,
          jsonContent: jsonContent,
          retried: true,
        );
      }
    }

    return _decode(response);
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final headers = _headers(auth: AuthMode.refresh);
      final url = _uri(AppConstants.refreshEndpoint);
      final refreshBody = jsonEncode(PayloadCrypto.seal(<String, dynamic>{}));
      final response = await http
          .post(url, headers: headers, body: refreshBody)
          .timeout(Duration(seconds: AppConstants.connectionTimeout));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _decode(response);
        final token = decoded['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _session.saveUser(token: token);
          return true;
        }
      }
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
    return false;
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json;
    try {
      var raw = response.body;
      if (PayloadCrypto.enabled) {
        raw = PayloadCrypto.openString(raw) ?? raw;
      }
      final decoded = jsonDecode(raw);
      json = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
    } catch (_) {
      throw ApiException(
        'Unexpected response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json['data'];
      if (data is Map<String, dynamic>) return data;
      if (data == null) return json;
      return {'value': data};
    }
    throw _fromJson(response.statusCode, json);
  }

  ApiException _fromResponse(http.Response response) {
    try {
      var raw = response.body;
      if (PayloadCrypto.enabled) {
        raw = PayloadCrypto.openString(raw) ?? raw;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _fromJson(response.statusCode, decoded);
      }
    } catch (_) {}
    return ApiException(
      'Request failed (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  ApiException _fromJson(int status, Map<String, dynamic> json) {
    final error = json['error'];
    String? type;
    if (error is Map) {
      type = error['type']?.toString();
    }
    final message = (json['message'] as String?)?.trim();
    return ApiException(
      (message != null && message.isNotEmpty)
          ? message
          : 'Request failed ($status)',
      statusCode: status,
      type: type,
    );
  }

  void _logRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    Object? body,
  ) {
    if (!kDebugMode) return;
    debugPrint('[API REQUEST] $method $url');
    debugPrint('[API REQUEST] Headers: ${_sanitize(headers)}');
    if (body != null) debugPrint('[API REQUEST] Body: $body');
  }

  void _logResponse(String method, Uri url, http.Response response) {
    if (!kDebugMode) return;
    debugPrint(
        '[API RESPONSE] $method $url status=${response.statusCode}');
    final body = response.body;
    debugPrint(
      '[API RESPONSE] Body: ${body.length > 800 ? '${body.substring(0, 800)}…' : body}',
    );
  }

  Map<String, String> _sanitize(Map<String, String> headers) {
    return headers.map((key, value) => MapEntry(
          key,
          key.toLowerCase() == 'authorization' ? 'Bearer ***' : value,
        ));
  }
}
