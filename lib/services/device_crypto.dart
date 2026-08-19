import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class DeviceCrypto {
  static const _spkiPrefix = <int>[
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
    0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00,
  ];

  static FortunaRandom _random() {
    final random = FortunaRandom();
    final seed = Uint8List(32);
    final dartRandom = Random.secure();
    for (var i = 0; i < seed.length; i++) {
      seed[i] = dartRandom.nextInt(256);
    }
    random.seed(KeyParameter(seed));
    return random;
  }

  static Map<String, String> generateKeyPair() {
    final params = ECKeyGeneratorParameters(ECCurve_secp256r1());
    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(params, _random()));
    final pair = generator.generateKeyPair();
    final pub = pair.publicKey as ECPublicKey;
    final priv = pair.privateKey as ECPrivateKey;
    return {
      'public_key_pem': _publicKeyPem(pub),
      'private_d': priv.d!.toRadixString(16),
    };
  }

  static String signChallenge(String privateDHex, String challenge) {
    final d = BigInt.parse(privateDHex, radix: 16);
    final priv = ECPrivateKey(d, ECDomainParameters('secp256r1'));
    final signer = Signer('SHA-256/ECDSA')
      ..init(
        true,
        ParametersWithRandom(PrivateKeyParameter(priv), _random()),
      );
    final sig = signer.generateSignature(
      Uint8List.fromList(utf8.encode(challenge)),
    ) as ECSignature;
    final bytes = Uint8List.fromList([
      ..._pad32(sig.r),
      ..._pad32(sig.s),
    ]);
    return base64Encode(bytes);
  }

  static String _publicKeyPem(ECPublicKey pub) {
    final x = _pad32(pub.Q!.x!.toBigInteger()!);
    final y = _pad32(pub.Q!.y!.toBigInteger()!);
    final der = Uint8List.fromList([..._spkiPrefix, 0x04, ...x, ...y]);
    final b64 = base64Encode(der);
    final lines = <String>[];
    for (var i = 0; i < b64.length; i += 64) {
      final end = min(i + 64, b64.length);
      lines.add(b64.substring(i, end));
    }
    return '-----BEGIN PUBLIC KEY-----\n${lines.join('\n')}\n-----END PUBLIC KEY-----';
  }

  static Uint8List _pad32(BigInt value) {
    final hex = value.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
  }
}
