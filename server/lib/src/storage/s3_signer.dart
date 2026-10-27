// AWS Signature Version 4 for S3-compatible storage. Google Cloud Storage
// accepts it on its XML API with HMAC keys, as do AWS S3, R2 and MinIO.
// https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 of an empty body, used for GET and DELETE.
const emptyPayloadHash =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

/// Signs S3 requests.
class S3Signer {
  /// Creates a signer for one key pair and region.
  const S3Signer({
    required this.accessKey,
    required this.secretKey,
    required this.region,
  });

  /// HMAC access key id.
  final String accessKey;

  /// HMAC secret.
  final String secretKey;

  /// Signing region (e.g. `us-east-1`, or `auto` for GCS/R2).
  final String region;

  /// Returns [headers] plus `x-amz-date`, `x-amz-content-sha256` and
  /// `Authorization` for a request. [headers] must include `host`; every
  /// header given is signed.
  Map<String, String> sign({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String payloadHash,
    required DateTime now,
  }) {
    final time = now.toUtc();
    final amzDate = _amzDate(time);
    final date = amzDate.substring(0, 8);
    final all = {
      for (final e in headers.entries) e.key.toLowerCase(): e.value.trim(),
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
    };
    final names = all.keys.toList()..sort();
    final signedHeaders = names.join(';');
    final canonicalRequest = [
      method,
      _canonicalPath(uri),
      _canonicalQuery(uri),
      for (final n in names) '$n:${all[n]}',
      '',
      signedHeaders,
      payloadHash,
    ].join('\n');
    final scope = '$date/$region/s3/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      scope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');

    var key = _hmac(utf8.encode('AWS4$secretKey'), date);
    key = _hmac(key, region);
    key = _hmac(key, 's3');
    key = _hmac(key, 'aws4_request');
    final signature = Hmac(sha256, key).convert(utf8.encode(stringToSign));

    return {
      ...all,
      'authorization':
          'AWS4-HMAC-SHA256 Credential=$accessKey/$scope, '
          'SignedHeaders=$signedHeaders, Signature=$signature',
    };
  }

  /// HMAC-SHA256 of [message] with [key].
  static List<int> _hmac(List<int> key, String message) =>
      Hmac(sha256, key).convert(utf8.encode(message)).bytes;

  /// `YYYYMMDDTHHMMSSZ`.
  static String _amzDate(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}T'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}Z';
  }

  /// Path with each segment URI-encoded (slashes kept).
  static String _canonicalPath(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return path.split('/').map(_encode).join('/');
  }

  /// Query parameters sorted by name, each encoded.
  static String _canonicalQuery(Uri uri) {
    final pairs = [
      for (final e in uri.queryParametersAll.entries)
        for (final v in e.value) '${_encode(e.key)}=${_encode(v)}',
    ]..sort();
    return pairs.join('&');
  }

  /// RFC 3986 encoding: only unreserved characters stay as they are.
  static String _encode(String s) {
    final out = StringBuffer();
    for (final byte in utf8.encode(Uri.decodeComponent(s))) {
      final c = String.fromCharCode(byte);
      if (RegExp(r'[A-Za-z0-9\-_.~]').hasMatch(c)) {
        out.write(c);
      } else {
        out.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return out.toString();
  }
}
