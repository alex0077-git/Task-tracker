import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 password hashing for local auth.
class PasswordHasher {
  static const _algorithm = 'pbkdf2_sha256';
  static const _iterations = 100000;
  static const _saltBytes = 16;
  static const _keyBytes = 32;

  static String hash(String password) {
    final salt = _randomSalt();
    final derived = _pbkdf2(password, salt, _iterations, _keyBytes);
    return '$_algorithm\$$_iterations\$${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  static bool verify(String password, String stored) {
    final parts = stored.split('\$');
    if (parts.length != 4 || parts[0] != _algorithm) {
      return false;
    }
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) {
      return false;
    }
    late final Uint8List salt;
    late final Uint8List expected;
    try {
      salt = Uint8List.fromList(base64Decode(parts[2]));
      expected = Uint8List.fromList(base64Decode(parts[3]));
    } catch (_) {
      return false;
    }
    final actual = _pbkdf2(password, salt, iterations, expected.length);
    return _constantTimeEquals(actual, expected);
  }

  static Uint8List _randomSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(_saltBytes, (_) => random.nextInt(256)),
    );
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018).
  static Uint8List _pbkdf2(
    String password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);
    final blockCount = (keyLength + 31) ~/ 32;
    final result = BytesBuilder(copy: false);

    for (var block = 1; block <= blockCount; block++) {
      final blockSalt = BytesBuilder(copy: false)
        ..add(salt)
        ..add([
          (block >> 24) & 0xff,
          (block >> 16) & 0xff,
          (block >> 8) & 0xff,
          block & 0xff,
        ]);
      var u = Uint8List.fromList(hmac.convert(blockSalt.toBytes()).bytes);
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      result.add(t);
    }

    return Uint8List.fromList(result.toBytes().sublist(0, keyLength));
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
