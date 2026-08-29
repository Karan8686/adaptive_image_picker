import 'dart:math' as math;
import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/crop_options.dart';
import '../models/compression_options.dart';

/// Pure-Dart image cropping, rotation, flipping, and circular masking engine.
class ImageCropperEngine {
  /// Crops, rotates, flips, and masks an image represented as raw bytes.
  ///
  /// [bytes] is the raw image file data (JPEG, PNG, WebP, etc.).
  /// [cropRectNormalized] is the cropping rectangle normalized between 0.0 and 1.0
  /// relative to the displayed/transformed image bounds.
  /// [rotation] is the rotation angle in degrees (0, 90, 180, 270).
  /// [flipHorizontal] whether to mirror horizontally.
  /// [flipVertical] whether to mirror vertically.
  /// [shape] rectangle or circle mask.
  /// [format] output encoding format.
  /// [quality] encoding quality (1-100).
  static Future<Uint8List> crop({
    required Uint8List bytes,
    required Rect cropRectNormalized,
    int rotation = 0,
    bool flipHorizontal = false,
    bool flipVertical = false,
    CropShape shape = CropShape.rectangle,
    OutputFormat format = OutputFormat.preserve,
    int quality = 90,
  }) async {
    return compute(
      _cropTask,
      _CropTaskParams(
        bytes: bytes,
        cropRectNormalized: cropRectNormalized,
        rotation: rotation,
        flipHorizontal: flipHorizontal,
        flipVertical: flipVertical,
        shape: shape,
        format: format,
        quality: quality,
      ),
    );
  }

  /// Synchronous version of [crop] for pure-Dart environments or unit tests.
  static Uint8List cropSync({
    required Uint8List bytes,
    required Rect cropRectNormalized,
    int rotation = 0,
    bool flipHorizontal = false,
    bool flipVertical = false,
    CropShape shape = CropShape.rectangle,
    OutputFormat format = OutputFormat.preserve,
    int quality = 90,
  }) {
    return _cropTask(
      _CropTaskParams(
        bytes: bytes,
        cropRectNormalized: cropRectNormalized,
        rotation: rotation,
        flipHorizontal: flipHorizontal,
        flipVertical: flipVertical,
        shape: shape,
        format: format,
        quality: quality,
      ),
    );
  }

  static Uint8List _cropTask(_CropTaskParams params) {
    img.Image? image = img.decodeImage(params.bytes);
    if (image == null) {
      throw FormatException('Failed to decode image from provided byte buffer.');
    }

    // 1. Bake EXIF orientation so pixel data is correctly oriented
    image = img.bakeOrientation(image);

    // 2. Apply initial rotation if needed
    final normalizedRotation = (params.rotation % 360 + 360) % 360;
    if (normalizedRotation != 0) {
      image = img.copyRotate(image, angle: normalizedRotation.toDouble());
    }

    // 3. Flip
    if (params.flipHorizontal) {
      image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
    }
    if (params.flipVertical) {
      image = img.copyFlip(image, direction: img.FlipDirection.vertical);
    }

    // 4. Calculate pixel crop coordinates from normalized rect
    final rect = params.cropRectNormalized;
    final int cropX = (rect.left * image.width).round().clamp(0, image.width - 1);
    final int cropY = (rect.top * image.height).round().clamp(0, image.height - 1);
    final int cropW = (rect.width * image.width).round().clamp(1, image.width - cropX);
    final int cropH = (rect.height * image.height).round().clamp(1, image.height - cropY);

    // 5. Perform rectangle crop
    image = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // 6. Apply circular mask if requested
    if (params.shape == CropShape.circle) {
      image = _applyCircularMask(image);
    }

    // 7. Encode output
    return _encodeImage(image, params.format, params.quality, isCircle: params.shape == CropShape.circle);
  }

  /// Masks pixels outside the inscribed circle with transparent alpha (A=0).
  static img.Image _applyCircularMask(img.Image source) {
    final int w = source.width;
    final int h = source.height;
    final double radius = math.min(w, h) / 2.0;
    final double centerX = w / 2.0;
    final double centerY = h / 2.0;
    final double radiusSq = radius * radius;

    final img.Image masked = source.hasAlpha ? source : source.convert(numChannels: 4);

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final double dx = x + 0.5 - centerX;
        final double dy = y + 0.5 - centerY;
        final double distSq = dx * dx + dy * dy;

        if (distSq > radiusSq) {
          final pixel = masked.getPixel(x, y);
          pixel.a = 0;
        } else if (distSq > (radius - 1.0) * (radius - 1.0)) {
          final double dist = math.sqrt(distSq);
          final double edgeDist = radius - dist;
          final double alphaMultiplier = edgeDist.clamp(0.0, 1.0);
          final pixel = masked.getPixel(x, y);
          pixel.a = (pixel.a * alphaMultiplier).round();
        }
      }
    }
    return masked;
  }

  static Uint8List _encodeImage(
    img.Image image,
    OutputFormat format,
    int quality, {
    bool isCircle = false,
  }) {
    switch (format) {
      case OutputFormat.png:
        return Uint8List.fromList(img.encodePng(image));
      case OutputFormat.webp:
        return Uint8List.fromList(img.encodeWebP(image));
      case OutputFormat.jpeg:
        if (isCircle) {
          return Uint8List.fromList(img.encodePng(image));
        }
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
      case OutputFormat.preserve:
        if (isCircle || image.hasAlpha) {
          return Uint8List.fromList(img.encodePng(image));
        }
        return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    }
  }
}

class _CropTaskParams {
  final Uint8List bytes;
  final Rect cropRectNormalized;
  final int rotation;
  final bool flipHorizontal;
  final bool flipVertical;
  final CropShape shape;
  final OutputFormat format;
  final int quality;

  _CropTaskParams({
    required this.bytes,
    required this.cropRectNormalized,
    required this.rotation,
    required this.flipHorizontal,
    required this.flipVertical,
    required this.shape,
    required this.format,
    required this.quality,
  });
}
