import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Local-only PIN hashing for the on-device unlock gate. This is deliberately
/// separate from the server-mirrored PIN verification used for new-device
/// re-establishment (see AuthService.verifyPin) — routine unlock never hits
/// the network.
class PinHasher {
  PinHasher._();

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }
}
