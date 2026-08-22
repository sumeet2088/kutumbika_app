import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class PayloadCrypto {
  PayloadCrypto._();

  static const alg = 'AES-256-GCM';
  static Uint8List? _key;

  static void configure(String raw) {
    raw = raw.trim();
    if (raw.isEmpty) {
      _key = null;
      return;
    }
    _key = _parseKey(raw);
  }

  static bool get enabled => _key != null && _key!.length == 32;

  static Map<String, dynamic> seal(Map<String, dynamic> body) {
    if (!enabled) return body;
    final plain = Uint8List.fromList(utf8.encode(jsonEncode(body)));
    final iv = _randomBytes(12);
    final nonce = _randomBytes(16);
    final ts = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final nonceHex = _toHex(nonce);
    final aad = Uint8List.fromList(utf8.encode('$ts|$nonceHex'));
    final ct = _gcm(true, iv, aad, plain);
    return {
      'enc': 1,
      'alg': alg,
      'iv': base64Encode(iv),
      'data': base64Encode(ct),
      'ts': ts,
      'nonce': nonceHex,
    };
  }

  static String? openString(String raw) {
    if (!enabled) return raw;
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return raw;
      json = decoded;
    } catch (_) {
      return raw;
    }
    if (json['enc'] != 1 || json['data'] == null || json['iv'] == null) {
      return raw;
    }
    final ts = (json['ts'] as num?)?.toInt() ?? 0;
    final nonce = '${json['nonce'] ?? ''}';
    final iv = base64Decode('${json['iv']}');
    final ct = base64Decode('${json['data']}');
    final aad = Uint8List.fromList(utf8.encode('$ts|$nonce'));
    final plain = _gcm(false, iv, aad, Uint8List.fromList(ct));
    return utf8.decode(plain);
  }

  static bool isEnvelope(Map<String, dynamic> json) {
    return json['enc'] == 1 && json['data'] != null && json['iv'] != null;
  }

  static Uint8List _parseKey(String raw) {
    final hex = RegExp(r'^[0-9a-fA-F]{64}$');
    if (hex.hasMatch(raw)) {
      return Uint8List.fromList([
        for (var i = 0; i < raw.length; i += 2) int.parse(raw.substring(i, i + 2), radix: 16),
      ]);
    }
    try {
      final b64 = base64Decode(raw);
      if (b64.length == 32) return Uint8List.fromList(b64);
    } catch (_) {}
    final digest = SHA256Digest();
    return digest.process(Uint8List.fromList(utf8.encode(raw)));
  }

  static Uint8List _gcm(bool encrypt, Uint8List iv, Uint8List aad, Uint8List input) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(encrypt, AEADParameters(KeyParameter(_key!), 128, iv, aad));
    return cipher.process(input);
  }

  static Uint8List _randomBytes(int length) {
    final rand = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rand.nextInt(256)));
  }

  static String _toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
