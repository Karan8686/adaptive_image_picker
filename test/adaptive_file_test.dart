import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_image_picker/src/models/adaptive_file.dart';

void main() {
  group('AdaptiveFile', () {
    test('creates from in-memory bytes and calculates metadata correctly', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final file = AdaptiveFile.fromBytes(
        bytes,
        name: 'sample_photo.JPG',
        width: 1920,
        height: 1080,
      );

      expect(file.name, 'sample_photo.JPG');
      expect(file.nameWithoutExtension, 'sample_photo');
      expect(file.extension, 'jpg');
      expect(file.extensionWithDot, '.jpg');
      expect(file.mimeType, 'image/jpeg');
      expect(file.width, 1920);
      expect(file.height, 1080);
      expect(file.size, 8);
      expect(file.aspectRatio, closeTo(1920 / 1080, 0.001));
      expect(file.hasBytes, isTrue);
      expect(file.hasPath, isFalse);

      final readBytes = await file.readAsBytes();
      expect(readBytes, bytes);
    });

    test('formats file sizes accurately', () {
      final b1 = AdaptiveFile.fromBytes(Uint8List(500), name: 'f1.png');
      expect(b1.formattedSize, '500 B');

      final b2 = AdaptiveFile.fromBytes(Uint8List(1024 * 350), name: 'f2.png');
      expect(b2.formattedSize, '350 KB');

      final b3 = AdaptiveFile.fromBytes(Uint8List(1024 * 1024 * 5), name: 'f3.png');
      expect(b3.formattedSize, '5.0 MB');
    });

    test('serializes to and from Map', () {
      final original = AdaptiveFile(
        path: '/tmp/photo.png',
        name: 'photo.png',
        mimeType: 'image/png',
        width: 800,
        height: 600,
        size: 12345,
      );

      final map = original.toMap();
      final restored = AdaptiveFile.fromMap(map);

      expect(restored.path, original.path);
      expect(restored.name, original.name);
      expect(restored.mimeType, original.mimeType);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
      expect(restored.size, original.size);
    });

    test('copyWith updates specified attributes', () {
      final file = AdaptiveFile.fromBytes(
        Uint8List(10),
        name: 'test.jpg',
      );

      final updated = file.copyWith(
        name: 'new_name.png',
        mimeType: 'image/png',
        width: 100,
        height: 100,
      );

      expect(updated.name, 'new_name.png');
      expect(updated.mimeType, 'image/png');
      expect(updated.width, 100);
      expect(updated.height, 100);
      expect(updated.size, 10);
    });

    test('saveTo and saveToDirectory saves bytes to disk', () async {
      final bytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      final file = AdaptiveFile.fromBytes(bytes, name: 'saved_sample.bin');
      
      final tempDir = Directory.systemTemp.createTempSync('adaptive_test_');
      try {
        final savedFile = await file.saveToDirectory(tempDir.path);
        expect(savedFile.path, isNotNull);
        expect(savedFile.name, 'saved_sample.bin');
        expect(File(savedFile.path!).existsSync(), isTrue);
        expect(File(savedFile.path!).readAsBytesSync(), bytes);

        final directSaved = await file.saveTo('${tempDir.path}/custom_name.bin');
        expect(directSaved.name, 'custom_name.bin');
        expect(File(directSaved.path!).existsSync(), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
