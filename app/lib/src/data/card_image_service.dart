import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum CardImageSource { gallery, camera }

/// Picks, crops and stores card images (profile photo, company logo).
///
/// Images are kept in the app's documents folder and referenced by `file:`
/// URI. They are never put into shared vCards; remote URLs replace them once
/// cards sync to the server.
abstract class CardImageService {
  /// Returns the `file:` URI of the stored square image, or null if the user
  /// cancelled.
  Future<String?> pickSquareImage(
    CardImageSource source, {
    required String cropTitle,
  });

  /// Deletes an image previously returned by [pickSquareImage]. Other URIs are
  /// ignored.
  Future<void> delete(String? uri);
}

class DeviceCardImageService implements CardImageService {
  DeviceCardImageService({ImagePicker? picker, ImageCropper? cropper})
    : _picker = picker ?? ImagePicker(),
      _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

  static const _maxSize = 1024;

  @override
  Future<String?> pickSquareImage(
    CardImageSource source, {
    required String cropTitle,
  }) async {
    final picked = await _picker.pickImage(
      source: source == CardImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxSize.toDouble(),
      maxHeight: _maxSize.toDouble(),
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    final cropped = await _cropper.cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      maxWidth: _maxSize,
      maxHeight: _maxSize,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: cropTitle,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(
          title: cropTitle,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );
    if (cropped == null) return null;

    final dir = await _imagesDir();
    final target = File(p.join(dir.path, '${const Uuid().v4()}.jpg'));
    await File(cropped.path).copy(target.path);
    return target.uri.toString();
  }

  @override
  Future<void> delete(String? uri) async {
    if (uri == null) return;
    final parsed = Uri.tryParse(uri);
    if (parsed == null || parsed.scheme != 'file') return;
    final file = File.fromUri(parsed);
    final dir = await _imagesDir();
    if (p.isWithin(dir.path, file.path) && await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'card_images')).create(recursive: true);
  }
}

/// Shows a card image from a `file:` or `http(s):` URI, or [fallback] if
/// there is none.
class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.uri, required this.fallback});

  final String? uri;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final parsed = uri == null ? null : Uri.tryParse(uri!);
    final ImageProvider? image = switch (parsed?.scheme) {
      'file' => FileImage(File.fromUri(parsed!)),
      'http' || 'https' => NetworkImage(uri!),
      _ => null,
    };
    if (image == null) return fallback;
    return Image(
      image: image,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
