// Where uploaded card images (profile photos, logos) are kept.

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ebucard_server/src/config.dart';
import 'package:ebucard_server/src/storage/s3_signer.dart';
import 'package:http/http.dart' as http;

/// Stores image bytes under a key.
abstract class ImageStorage {
  /// Saves [bytes] as [key].
  Future<void> put(String key, Uint8List bytes, String contentType);

  /// The bytes of [key], or null if there are none.
  Future<Uint8List?> get(String key);

  /// Removes [key]; missing keys are ignored.
  Future<void> delete(String key);
}

/// Keeps images in memory: for development without a bucket, and tests.
class MemoryImageStorage implements ImageStorage {
  /// Stored objects, visible to tests.
  final objects = <String, Uint8List>{};

  @override
  Future<void> put(String key, Uint8List bytes, String contentType) async =>
      objects[key] = bytes;

  @override
  Future<Uint8List?> get(String key) async => objects[key];

  @override
  Future<void> delete(String key) async => objects.remove(key);
}

/// Stores images in an S3-compatible bucket (see [StorageConfig]). The
/// bucket stays private; the server reads images back and serves them.
class S3ImageStorage implements ImageStorage {
  /// Creates the storage for [config], sending requests with [client].
  S3ImageStorage(this.config, this.client, {DateTime Function()? now})
    : _signer = S3Signer(
        accessKey: config.accessKey,
        secretKey: config.secretKey,
        region: config.region,
      ),
      _now = now ?? DateTime.now;

  /// Bucket settings.
  final StorageConfig config;

  /// HTTP client.
  final http.Client client;

  final S3Signer _signer;
  final DateTime Function() _now;

  @override
  Future<void> put(String key, Uint8List bytes, String contentType) async {
    final response = await _send(
      'PUT',
      key,
      body: bytes,
      headers: {'content-type': contentType},
    );
    if (response.statusCode != 200) {
      throw StorageException('PUT $key', response.statusCode);
    }
  }

  @override
  Future<Uint8List?> get(String key) async {
    final response = await _send('GET', key);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw StorageException('GET $key', response.statusCode);
    }
    return response.bodyBytes;
  }

  @override
  Future<void> delete(String key) async {
    final response = await _send('DELETE', key);
    if (response.statusCode != 204 &&
        response.statusCode != 200 &&
        response.statusCode != 404) {
      throw StorageException('DELETE $key', response.statusCode);
    }
  }

  /// The object URL for [key], path-style or virtual-hosted style.
  Uri objectUri(String key) {
    final endpoint = config.endpoint;
    return config.pathStyle
        ? endpoint.replace(path: '/${config.bucket}/$key')
        : endpoint.replace(
            host: '${config.bucket}.${endpoint.host}',
            path: '/$key',
          );
  }

  /// Sends a signed request for [key].
  Future<http.Response> _send(
    String method,
    String key, {
    Uint8List? body,
    Map<String, String> headers = const {},
  }) async {
    final uri = objectUri(key);
    final payloadHash = body == null
        ? emptyPayloadHash
        : sha256.convert(body).toString();
    final signed = _signer.sign(
      method: method,
      uri: uri,
      headers: {'host': uri.authority, ...headers},
      payloadHash: payloadHash,
      now: _now(),
    )..remove('host'); // The HTTP client sets Host itself.
    final request = http.Request(method, uri)..headers.addAll(signed);
    if (body != null) request.bodyBytes = body;
    return http.Response.fromStream(await client.send(request));
  }
}

/// A storage request failed.
class StorageException implements Exception {
  /// Creates the exception for [operation] with HTTP [status].
  const StorageException(this.operation, this.status);

  /// What was attempted, e.g. `PUT images/x.jpg`.
  final String operation;

  /// HTTP status returned by the storage service.
  final int status;

  @override
  String toString() => 'StorageException: $operation → $status';
}
