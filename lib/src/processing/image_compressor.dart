import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/compression_options.dart';

/// Pure-Dart image compression and optimization engine with binary-search target-size guarantees.
class ImageCompressor {
  /// Compresses [bytes] according to the provided [options].
  ///
  /// Runs off the UI thread via [compute] where supported.
  static Future<Uint8List> compress({
    required Uint8List bytes,
    required CompressionOptions options,
    String? originalFileName,
  }) async {
    return compute(
      _compressTask,
      _CompressTaskParams(
        bytes: bytes,
        options: options,
        originalFileName: originalFileName,
      ),
    );
  }

  /// Synchronous compression for pure-Dart execution, CLI, or unit tests.
  static Uint8List compressSync({
    required Uint8List bytes,
    required CompressionOptions options,
    String? originalFileName,
  }) {
    return _compressTask(
      _CompressTaskParams(
        bytes: bytes,
        options: options,
        originalFileName: originalFileName,
      ),
    );
  }

  static Uint8List _compressTask(_CompressTaskParams params) {
    final options = params.options;
    img.Image? image = img.decodeImage(params.bytes);
    if (image == null) {
      throw FormatException('Failed to decode image data for compression.');
    }

    // 1. Bake EXIF orientation if requested
    if (options.autoOrientation) {
      image = img.bakeOrientation(image);
    }

    // 2. Initial dimension constraint resize
    image = _applyMaxDimensions(image, options.maxWidth, options.maxHeight);

    // 3. Resolve target encoding format
    final format = _resolveFormat(options.format, params.originalFileName, image.hasAlpha);

    // 4. Target size compression or standard quality encoding
    if (options.maxBytes != null && options.maxBytes! > 0) {
      return _compressToTargetBytes(
        image: image,
        format: format,
        maxBytes: options.maxBytes!,
        targetQuality: options.quality,
        minQuality: options.minQuality,
      );
    } else {
      return _encode(image, format, options.quality);
    }
  }

  /// Scales down image proportionally if it exceeds [maxWidth] or [maxHeight].
  static img.Image _applyMaxDimensions(img.Image image, int? maxWidth, int? maxHeight) {
    if (maxWidth == null && maxHeight == null) return image;

    final int currentW = image.width;
    final int currentH = image.height;

    double scale = 1.0;
    if (maxWidth != null && currentW > maxWidth) {
      scale = math.min(scale, maxWidth / currentW);
    }
    if (maxHeight != null && currentH > maxHeight) {
      scale = math.min(scale, maxHeight / currentH);
    }

    if (scale < 1.0) {
      final int targetW = (currentW * scale).round().clamp(1, currentW);
      final int targetH = (currentH * scale).round().clamp(1, currentH);
      return img.copyResize(
        image,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.cubic,
      );
    }
    return image;
  }

  /// Binary search quality reduction and progressive downscaling to guarantee [maxBytes].
  static Uint8List _compressToTargetBytes({
    required img.Image image,
    required OutputFormat format,
    required int maxBytes,
    required int targetQuality,
    required int minQuality,
  }) {
    img.Image currentImage = image;
    const int maxDownscaleIterations = 8;

    for (int iteration = 0; iteration < maxDownscaleIterations; iteration++) {
      // 1. First test targetQuality
      final initialEncoded = _encode(currentImage, format, targetQuality);
      if (initialEncoded.lengthInBytes <= maxBytes) {
        return initialEncoded;
      }

      // 2. Binary search on quality range [minQuality, targetQuality]
      int low = minQuality;
      int high = targetQuality - 1;
      Uint8List? bestFit;

      while (low <= high) {
        final int mid = (low + high) ~/ 2;
        final candidate = _encode(currentImage, format, mid);

        if (candidate.lengthInBytes <= maxBytes) {
          bestFit = candidate;
          // Try higher quality to get closer to maxBytes without exceeding
          low = mid + 1;
        } else {
          // Exceeds maxBytes, lower quality
          high = mid - 1;
        }
      }

      if (bestFit != null) {
        return bestFit;
      }

      // 3. If even minQuality exceeds maxBytes, downscale current image by 0.8x
      final int newW = (currentImage.width * 0.8).round();
      final int newH = (currentImage.height * 0.8).round();

      if (newW < 32 || newH < 32) {
        // Cannot downscale further, return lowest quality produced
        return _encode(currentImage, format, minQuality);
      }

      currentImage = img.copyResize(
        currentImage,
        width: newW,
        height: newH,
        interpolation: img.Interpolation.cubic,
      );
    }

    return _encode(currentImage, format, minQuality);
  }

  static OutputFormat _resolveFormat(OutputFormat requested, String? fileName, bool hasAlpha) {
    if (requested != OutputFormat.preserve) {
      return requested;
    }
    if (fileName != null) {
      final ext = fileName.split('.').last.toLowerCase();
      switch (ext) {
        case 'png':
          return OutputFormat.png;
        case 'webp':
          return OutputFormat.webp;
        case 'jpg':
        case 'jpeg':
          return OutputFormat.jpeg;
      }
    }
    return hasAlpha ? OutputFormat.png : OutputFormat.jpeg;
  }

  static Uint8List _encode(img.Image image, OutputFormat format, int quality) {
    switch (format) {
      case OutputFormat.png:
        // PNG level 6 provides standard balance between speed and size
        return Uint8List.fromList(img.encodePng(image, level: 6));
      case OutputFormat.webp:
        return Uint8List.fromList(img.encodeWebP(image));
      case OutputFormat.jpeg:
      case OutputFormat.preserve:
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }
  }
}

class _CompressTaskParams {
  final Uint8List bytes;
  final CompressionOptions options;
  final String? originalFileName;

  _CompressTaskParams({
    required this.bytes,
    required this.options,
    this.originalFileName,
  });
}
