import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:adaptive_image_picker/src/models/crop_options.dart';
import 'package:adaptive_image_picker/src/models/compression_options.dart';
import 'package:adaptive_image_picker/src/processing/image_cropper_engine.dart';

void main() {
  late Uint8List testImageBytes;

  setUp(() {
    // Create a 200x100 RGB test image
    final img.Image image = img.Image(width: 200, height: 100);
    img.fill(image, color: img.ColorRgb8(255, 0, 0)); // Red background
    // Draw a blue square in the center
    img.fillRect(image, x1: 50, y1: 25, x2: 150, y2: 75, color: img.ColorRgb8(0, 0, 255));
    testImageBytes = Uint8List.fromList(img.encodePng(image));
  });

  group('ImageCropperEngine', () {
    test('crops rectangular region accurately', () {
      // Crop center 50% (from 0.25, 0.25 to 0.75, 0.75) => width = 100, height = 50
      final croppedBytes = ImageCropperEngine.cropSync(
        bytes: testImageBytes,
        cropRectNormalized: const Rect.fromLTWH(0.25, 0.25, 0.5, 0.5),
        format: OutputFormat.png,
      );

      final croppedImage = img.decodeImage(croppedBytes);
      expect(croppedImage, isNotNull);
      expect(croppedImage!.width, 100);
      expect(croppedImage.height, 50);
    });

    test('rotates image 90 degrees', () {
      final rotatedBytes = ImageCropperEngine.cropSync(
        bytes: testImageBytes,
        cropRectNormalized: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0),
        rotation: 90,
        format: OutputFormat.png,
      );

      final rotatedImage = img.decodeImage(rotatedBytes);
      expect(rotatedImage, isNotNull);
      // Original 200x100 rotated 90 deg becomes 100x200
      expect(rotatedImage!.width, 100);
      expect(rotatedImage.height, 200);
    });

    test('applies circular alpha mask', () {
      final squareImg = img.Image(width: 100, height: 100);
      img.fill(squareImg, color: img.ColorRgba8(255, 255, 255, 255));
      final squareBytes = Uint8List.fromList(img.encodePng(squareImg));

      final circularBytes = ImageCropperEngine.cropSync(
        bytes: squareBytes,
        cropRectNormalized: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0),
        shape: CropShape.circle,
        format: OutputFormat.png,
      );

      final result = img.decodeImage(circularBytes);
      expect(result, isNotNull);
      expect(result!.hasAlpha, isTrue);

      // Top-left corner (0,0) should be transparent (alpha == 0)
      final cornerPixel = result.getPixel(0, 0);
      expect(cornerPixel.a, 0);

      // Center pixel (50, 50) should be opaque (alpha == 255)
      final centerPixel = result.getPixel(50, 50);
      expect(centerPixel.a, 255);
    });

    test('flips horizontally and vertically', () {
      final flippedBytes = ImageCropperEngine.cropSync(
        bytes: testImageBytes,
        cropRectNormalized: const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0),
        flipHorizontal: true,
        flipVertical: true,
        format: OutputFormat.png,
      );

      final result = img.decodeImage(flippedBytes);
      expect(result, isNotNull);
      expect(result!.width, 200);
      expect(result.height, 100);
    });
  });
}
