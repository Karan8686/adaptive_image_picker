import 'dart:async';
import 'package:file_selector/file_selector.dart';

import 'src/models/adaptive_file.dart';
import 'src/models/picker_options.dart';
import 'adaptive_image_picker_platform_interface.dart';

/// A desktop (Windows, macOS, Linux) implementation of [AdaptiveImagePickerPlatform].
class AdaptiveImagePickerDesktop extends AdaptiveImagePickerPlatform {
  /// Constructs an [AdaptiveImagePickerDesktop] instance.
  AdaptiveImagePickerDesktop();

  /// Registers this class as the default instance of [AdaptiveImagePickerPlatform].
  static void registerWith() {
    AdaptiveImagePickerPlatform.instance = AdaptiveImagePickerDesktop();
  }

  @override
  Future<String?> getPlatformVersion() async {
    return 'Desktop';
  }

  @override
  Future<List<AdaptiveFile>> pickImages(PickerOptions options) async {
    final extensions = <String>[
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
      'bmp',
      'heic',
      'heif',
    ];

    if (options.mediaType == MediaType.video) {
      extensions.addAll(['mp4', 'mov', 'avi', 'mkv']);
    } else if (options.mediaType == MediaType.all) {
      extensions.addAll(['mp4', 'mov', 'avi', 'mkv']);
    }

    final typeGroup = XTypeGroup(
      label: options.mediaType == MediaType.video
          ? 'Videos'
          : (options.mediaType == MediaType.all ? 'Media Files' : 'Images'),
      extensions: extensions,
    );

    if (options.isMultiple) {
      final files = await openFiles(acceptedTypeGroups: [typeGroup]);
      if (files.isEmpty) return [];

      final List<AdaptiveFile> results = [];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        results.add(
          AdaptiveFile.fromBytes(
            bytes,
            name: file.name,
            mimeType: file.mimeType,
            size: await file.length(),
            lastModified: await file.lastModified(),
          ).copyWith(path: file.path),
        );
      }
      return results;
    } else {
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return [];

      final bytes = await file.readAsBytes();
      return [
        AdaptiveFile.fromBytes(
          bytes,
          name: file.name,
          mimeType: file.mimeType,
          size: await file.length(),
          lastModified: await file.lastModified(),
        ).copyWith(path: file.path),
      ];
    }
  }

  @override
  Future<AdaptiveFile?> takePhoto(PickerOptions options) async {
    // On desktop platforms where a direct system camera modal isn't standard,
    // fallback gracefully to standard file selection.
    final files = await pickImages(options);
    return files.isNotEmpty ? files.first : null;
  }
}
