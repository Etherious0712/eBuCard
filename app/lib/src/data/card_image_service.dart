// Profile photo and company logo handling: pick from library or camera, crop
// to a square, store in the app's documents folder, and display.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Where a new image comes from.
enum CardImageSource {
  /// The phone's photo library.
  gallery,

  /// Take a new photo with the camera.
  camera,
}

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

/// The real [CardImageService], using image_picker and image_cropper.
class DeviceCardImageService implements CardImageService {
  /// Creates the service; [picker] and [cropper] can be replaced in tests.
  DeviceCardImageService({ImagePicker? picker, ImageCropper? cropper})
    : _picker = picker ?? ImagePicker(),
      _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

  /// Longest side of stored images, in pixels.
  static const _maxSize = 1024;

  @override
  Future<String?> pickSquareImage(
    CardImageSource source, {
    required String cropTitle,
  }) async {
    // 1. Pick, already scaled down so cropping is fast.
    final picked = await _picker.pickImage(
      source: source == CardImageSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxSize.toDouble(),
      maxHeight: _maxSize.toDouble(),
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    // 2. Square crop with the platform's native crop screen.
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

    // 3. Copy out of the temporary folder so the image survives.
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
    // Only ever delete files this service created.
    if (p.isWithin(dir.path, file.path) && await file.exists()) {
      await file.delete();
    }
  }

  /// `<documents>/card_images`, created on first use.
  Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'card_images')).create(recursive: true);
  }
}

/// Shows a card image from a `file:` or `http(s):` URI, or [fallback] if
/// there is none.
class CardImage extends StatelessWidget {
  /// Shows [uri], falling back to [fallback].
  const CardImage({super.key, required this.uri, required this.fallback});

  /// `file:` or `http(s):` URI of the image, or null.
  final String? uri;

  /// Shown when there is no image or it fails to load.
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
