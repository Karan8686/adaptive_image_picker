import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:adaptive_image_picker/src/models/compression_options.dart';
import 'package:adaptive_image_picker/src/processing/image_compressor.dart';

void main() {
  late Uint8List largeImageBytes;

  setUp(() {
    // Generate a high-resolution 1000x800 test image with complex gradients/noise
    final img.Image image = img.Image(width: 1000, height: 800);
    for (int y = 0; y < 800; y++) {
      for (int x = 0; x < 1000; x++) {
        image.setPixelRgb(x, y, (x * 255) ~/ 1000, (y * 255) ~/ 800, ((x + y) * 255) ~/ 1800);
      }
    }
    largeImageBytes = Uint8List.fromList(img.encodePng(image));
  });

  group('ImageCompressor', () {
    test('resizes image to fit within maxWidth and maxHeight', () {
      final compressedBytes = ImageCompressor.compressSync(
        bytes: largeImageBytes,
        options: const CompressionOptions(
          maxWidth: 500,
          maxHeight: 400,
          format: OutputFormat.jpeg,
        ),
      );

      final result = img.decodeImage(compressedBytes);
      expect(result, isNotNull);
      expect(result!.width, lessThanOrEqualTo(500));
      expect(result.height, lessThanOrEqualTo(400));
    });

    test('strictly enforces maxBytes threshold using binary search', () {
      const targetMaxBytes = 35 * 1024; // 35 KB

      final compressedBytes = ImageCompressor.compressSync(
        bytes: largeImageBytes,
        options: const CompressionOptions(
          maxBytes: targetMaxBytes,
          quality: 90,
          minQuality: 10,
          format: OutputFormat.jpeg,
        ),
      );

      expect(compressedBytes.lengthInBytes, lessThanOrEqualTo(targetMaxBytes));

      final result = img.decodeImage(compressedBytes);
      expect(result, isNotNull);
      expect(result!.width, greaterThan(0));
    });

    test('converts to requested OutputFormat WebP', () {
      final webpBytes = ImageCompressor.compressSync(
        bytes: largeImageBytes,
        options: const CompressionOptions(
          maxWidth: 400,
          format: OutputFormat.webp,
        ),
      );

      final result = img.decodeImage(webpBytes);
      expect(result, isNotNull);
      expect(result!.width, 400);
    });
  });
}
