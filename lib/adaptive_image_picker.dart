import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'adaptive_image_picker_platform_interface.dart';
import 'src/models/adaptive_file.dart';
import 'src/models/crop_options.dart';
import 'src/models/compression_options.dart';
import 'src/models/picker_options.dart';
import 'src/processing/image_compressor.dart';
import 'src/widgets/adaptive_crop_view.dart';
import 'src/widgets/media_bottom_sheet.dart';

export 'src/models/adaptive_file.dart';
export 'src/models/crop_options.dart';
export 'src/models/compression_options.dart';
export 'src/models/picker_options.dart';
export 'src/models/picker_theme.dart';
export 'src/processing/image_cropper_engine.dart';
export 'src/processing/image_compressor.dart';
export 'src/widgets/adaptive_crop_view.dart';
export 'src/widgets/media_bottom_sheet.dart';
export 'adaptive_image_picker_platform_interface.dart';
export 'adaptive_image_picker_method_channel.dart';

/// The primary public interface for `adaptive_image_picker`.
/// Provides zero-permission native picking, pure-Dart cropping,
/// binary search compression, and adaptive UI components.
class AdaptiveImagePicker {
  const AdaptiveImagePicker._();

  /// Returns the platform version (for diagnostics/testing).
  static Future<String?> getPlatformVersion() {
    return AdaptiveImagePickerPlatform.instance.getPlatformVersion();
  }
  /// Picks a single image from the specified [source] (Gallery, Camera, or URL).
  ///
  /// Optionally chains cropping ([cropOptions]) and/or compression ([compressionOptions]).
  static Future<AdaptiveFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    CropOptions? cropOptions,
    CompressionOptions? compressionOptions,
    BuildContext? context,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    MediaType mediaType = MediaType.image,
  }) async {
    AdaptiveFile? pickedFile;

    if (source == ImageSource.camera) {
      pickedFile = await AdaptiveImagePickerPlatform.instance.takePhoto(
        PickerOptions(
          source: ImageSource.camera,
          mediaType: mediaType,
          preferredCameraDevice: preferredCameraDevice,
        ),
      );
    } else if (source == ImageSource.gallery) {
      final results = await AdaptiveImagePickerPlatform.instance.pickImages(
        PickerOptions(
          source: ImageSource.gallery,
          mediaType: mediaType,
          maxCount: 1,
        ),
      );
      if (results.isNotEmpty) {
        pickedFile = results.first;
      }
    } else if (source == ImageSource.url) {
      if (context == null) {
        throw ArgumentError('BuildContext is required when source is ImageSource.url');
      }
      final url = await MediaBottomSheet.showUrlInputDialog(context);
      if (url != null && url.isNotEmpty) {
        pickedFile = await fromUrl(url);
      }
    }

    if (pickedFile == null) return null;

    // Apply crop if requested and context is available
    if (cropOptions != null && context != null && context.mounted) {
      pickedFile = await cropImage(
        file: pickedFile,
        context: context,
        options: cropOptions,
      );
      if (pickedFile == null) return null;
    }

    // Apply compression if requested
    if (compressionOptions != null) {
      pickedFile = await compressImage(
        file: pickedFile,
        options: compressionOptions,
      );
    }

    return pickedFile;
  }

  /// Picks multiple images from the photo gallery.
  ///
  /// [maxCount] optionally limits the maximum number of items.
  /// [compressionOptions] optionally compresses all picked images.
  static Future<List<AdaptiveFile>> pickMultiple({
    int? maxCount,
    CompressionOptions? compressionOptions,
    MediaType mediaType = MediaType.image,
  }) async {
    final results = await AdaptiveImagePickerPlatform.instance.pickImages(
      PickerOptions(
        source: ImageSource.gallery,
        mediaType: mediaType,
        maxCount: maxCount ?? 10,
      ),
    );

    if (results.isEmpty) return [];

    if (compressionOptions != null) {
      final List<AdaptiveFile> compressed = [];
      for (final file in results) {
        compressed.add(await compressImage(file: file, options: compressionOptions));
      }
      return compressed;
    }

    return results;
  }

  /// Opens the interactive UI cropper for [file].
  static Future<AdaptiveFile?> cropImage({
    required AdaptiveFile file,
    required BuildContext context,
    CropOptions? options,
    CompressionOptions? compressionOptions,
  }) async {
    return AdaptiveCropView.show(
      context,
      file: file,
      options: options ?? const CropOptions(),
      compressionOptions: compressionOptions,
    );
  }

  /// Compresses [file] to meet [options] targets (such as `maxBytes`, `maxWidth`, `quality`).
  static Future<AdaptiveFile> compressImage({
    required AdaptiveFile file,
    required CompressionOptions options,
  }) async {
    final rawBytes = await file.readAsBytes();
    final compressedBytes = await ImageCompressor.compress(
      bytes: rawBytes,
      options: options,
      originalFileName: file.name,
    );

    final ext = options.format == OutputFormat.webp
        ? 'webp'
        : (options.format == OutputFormat.png
            ? 'png'
            : (options.format == OutputFormat.jpeg ? 'jpg' : file.extension));

    final newName = '${file.nameWithoutExtension}_compressed.$ext';

    return file.copyWith(
      bytes: compressedBytes,
      name: newName,
      size: compressedBytes.lengthInBytes,
      mimeType: options.format == OutputFormat.webp
          ? 'image/webp'
          : (options.format == OutputFormat.png
              ? 'image/png'
              : (options.format == OutputFormat.jpeg ? 'image/jpeg' : file.mimeType)),
    );
  }

  /// Displays an adaptive bottom sheet / modal action sheet allowing the user to select
  /// the media source (Camera, Gallery, URL), then launches the corresponding picker flow.
  static Future<AdaptiveFile?> showPickerModal({
    required BuildContext context,
    PickerOptions? options,
    CropOptions? cropOptions,
    CompressionOptions? compressionOptions,
  }) async {
    final opts = options ?? const PickerOptions();
    final source = await MediaBottomSheet.show(context, options: opts);
    if (source == null) return null;

    if (!context.mounted) return null;

    return pickImage(
      source: source,
      cropOptions: cropOptions ?? opts.cropOptions,
      compressionOptions: compressionOptions ?? opts.compressionOptions,
      context: context,
      preferredCameraDevice: opts.preferredCameraDevice,
      mediaType: opts.mediaType,
    );
  }

  /// Downloads an image from an internet [url] and returns an [AdaptiveFile].
  static Future<AdaptiveFile> fromNetwork(String url) => fromUrl(url);

  /// Downloads an image from an internet [url] and returns an [AdaptiveFile].
  static Future<AdaptiveFile> fromUrl(
    String url, {
    CompressionOptions? compressionOptions,
    CropOptions? cropOptions,
    BuildContext? context,
  }) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw StateError('Failed to fetch image from URL ($url): HTTP ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    final fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'downloaded_image.jpg';
    final mimeType = response.headers['content-type'] ?? 'image/jpeg';

    var file = AdaptiveFile.fromBytes(
      bytes,
      name: fileName,
      mimeType: mimeType,
    );

    if (cropOptions != null && context != null && context.mounted) {
      final cropped = await cropImage(
        file: file,
        context: context,
        options: cropOptions,
      );
      if (cropped != null) file = cropped;
    }

    if (compressionOptions != null) {
      file = await compressImage(file: file, options: compressionOptions);
    }

    return file;
  }
}
