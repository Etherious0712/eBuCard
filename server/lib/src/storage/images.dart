// Card images: upload (signed-in users), public download by unguessable id,
// and deletion. Images are referenced from card JSON by their public URL.

import 'dart:typed_data';

import 'package:ebucard_server/src/http/api_error.dart';
import 'package:ebucard_server/src/http/request_helpers.dart';
import 'package:ebucard_server/src/storage/image_storage.dart';
import 'package:postgres/postgres.dart';

/// Upload, read and delete card images.
class Images {
  /// Creates the service.
  Images(this._db, this.storage, this.publicBaseUrl);

  final Pool<void> _db;

  /// Where the bytes live.
  final ImageStorage storage;

  /// Base of the public image URLs.
  final Uri publicBaseUrl;

  /// Largest accepted upload. The app sends ≤ 1024 px JPEGs, well below.
  static const maxBytes = 2 * 1024 * 1024;

  /// Stores [bytes] for [userId]; returns `{id, url}`. Only JPEG and PNG
  /// are accepted, recognised by their first bytes (not by what the client
  /// claims).
  Future<Map<String, String>> upload(String userId, Uint8List bytes) async {
    if (bytes.length > maxBytes) {
      throw const ApiException(413, 'image_too_large');
    }
    final contentType = _detectType(bytes);
    if (contentType == null) {
      throw const ApiException(415, 'unsupported_image_type');
    }
    final rows = await _db.execute(
      Sql.named(
        'INSERT INTO images (id, user_id, content_type, size) '
        'VALUES (gen_random_uuid(), @user::uuid, @type, @size) '
        'RETURNING id::text',
      ),
      parameters: {'user': userId, 'type': contentType, 'size': bytes.length},
    );
    final id = rows.first.first! as String;
    await storage.put(key(id), bytes, contentType);
    return {'id': id, 'url': urlFor(id).toString()};
  }

  /// The image's bytes and content type, or null if unknown.
  Future<(Uint8List, String)?> read(String id) async {
    if (!isUuid(id)) return null;
    final rows = await _db.execute(
      Sql.named('SELECT content_type FROM images WHERE id = @id::uuid'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    final bytes = await storage.get(key(id));
    return bytes == null ? null : (bytes, rows.first.first! as String);
  }

  /// Deletes image [id] of [userId]; 404 if it isn't theirs.
  Future<void> delete(String userId, String id) async {
    if (!isUuid(id)) throw const ApiException.notFound();
    final rows = await _db.execute(
      Sql.named(
        'DELETE FROM images WHERE id = @id::uuid AND user_id = @user::uuid '
        'RETURNING id',
      ),
      parameters: {'id': id, 'user': userId},
    );
    if (rows.isEmpty) throw const ApiException.notFound();
    await storage.delete(key(id));
  }

  /// Storage key of image [id].
  static String key(String id) => 'images/$id';

  /// Public URL of image [id].
  Uri urlFor(String id) => publicBaseUrl.replace(path: '/images/$id');

  /// `image/jpeg` or `image/png` from the file's magic bytes, else null.
  static String? _detectType(Uint8List b) {
    if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'image/jpeg';
    }
    const png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (b.length > 8 &&
        List.generate(8, (i) => b[i] == png[i]).every((x) => x)) {
      return 'image/png';
    }
    return null;
  }
}
