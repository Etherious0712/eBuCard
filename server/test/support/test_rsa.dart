// RSA key pairs made fresh for each test run, standing in for Apple's and
// Google's signing keys. Generated at run time so no private key is ever
// stored in the repository.

import 'dart:math';
import 'dart:typed_data';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:pointycastle/export.dart' as pc;

/// A private key and its public JWK.
class TestRsaKey {
  TestRsaKey._(this.privateKey, this.publicJwk);

  /// Generates a 2048-bit key pair with key id [kid].
  factory TestRsaKey.generate(String kid) {
    final random = pc.FortunaRandom()
      ..seed(
        pc.KeyParameter(
          Uint8List.fromList(
            List.generate(32, (_) => Random.secure().nextInt(256)),
          ),
        ),
      );
    final generator = pc.RSAKeyGenerator()
      ..init(
        pc.ParametersWithRandom(
          pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
          random,
        ),
      );
    final pair = generator.generateKeyPair();
    final private = pair.privateKey;
    final public = pair.publicKey;
    return TestRsaKey._(
      RSAPrivateKey.raw(private),
      RSAPublicKey.raw(public).toJWK(keyID: kid)..['kid'] = kid,
    );
  }

  /// Signs tokens.
  final RSAPrivateKey privateKey;

  /// The public key as published in a JWKS.
  final Map<String, dynamic> publicJwk;
}
