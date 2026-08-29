import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

void main() {
  group('CropOptions and Presets', () {
    test('circle preset initializes circle shape and square ratio', () {
      final options = CropOptions.circle(title: 'Avatar');
      expect(options.shape, CropShape.circle);
      expect(options.aspectRatio, CropAspectRatio.square);
      expect(options.lockAspectRatio, isTrue);
      expect(options.showAspectRatios, isFalse);
      expect(options.title, 'Avatar');
    });

    test('square preset initializes square ratio', () {
      final options = CropOptions.square(title: 'Square Crop');
      expect(options.aspectRatio, CropAspectRatio.square);
      expect(options.lockAspectRatio, isTrue);
    });

    test('CropAspectRatio calculates ratios correctly', () {
      expect(CropAspectRatio.square.ratio, 1.0);
      expect(CropAspectRatio.ratio16_9.ratio, closeTo(16 / 9, 0.001));
      expect(CropAspectRatio.ratio4_3.ratio, closeTo(4 / 3, 0.001));
      expect(CropAspectRatio.freeform.ratio, isNull);
      expect(CropAspectRatio.freeform.isFreeform, isTrue);
    });
  });

  group('CompressionOptions and Presets', () {
    test('avatar preset sets dimensions and maxBytes', () {
      final options = CompressionOptions.avatar();
      expect(options.maxWidth, 512);
      expect(options.maxHeight, 512);
      expect(options.maxBytes, 200 * 1024);
      expect(options.format, OutputFormat.jpeg);
    });

    test('webOptimized preset sets webp format', () {
      final options = CompressionOptions.webOptimized();
      expect(options.maxWidth, 1920);
      expect(options.maxHeight, 1080);
      expect(options.format, OutputFormat.webp);
    });

    test('thumbnail preset sets thumbnail constraints', () {
      final options = CompressionOptions.thumbnail();
      expect(options.maxWidth, 256);
      expect(options.maxHeight, 256);
      expect(options.maxBytes, 50 * 1024);
    });
  });

  group('PickerOptions', () {
    test('isMultiple returns true when maxCount > 1', () {
      const single = PickerOptions(maxCount: 1);
      expect(single.isMultiple, isFalse);

      const multiple = PickerOptions(maxCount: 5);
      expect(multiple.isMultiple, isTrue);
    });

    test('PickerTheme presets initialize default color palettes', () {
      final darkTheme = PickerTheme.dark();
      expect(darkTheme.backgroundColor, isNotNull);
      expect(darkTheme.titleTextStyle?.color, isNotNull);

      final lightTheme = PickerTheme.light();
      expect(lightTheme.backgroundColor, isNotNull);
      expect(lightTheme.borderRadius, isNotNull);
    });
  });
}
