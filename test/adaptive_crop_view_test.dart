import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

void main() {
  late Uint8List sampleImageBytes;

  setUp(() {
    final image = img.Image(width: 100, height: 100);
    img.fill(image, color: img.ColorRgb8(0, 255, 0));
    sampleImageBytes = Uint8List.fromList(img.encodePng(image));
  });

  testWidgets('AdaptiveCropView renders image and toolbar controls', (WidgetTester tester) async {
    final file = AdaptiveFile.fromBytes(sampleImageBytes, name: 'green.png');

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveCropView(
          file: file,
          options: const CropOptions(
            title: 'Custom Cropper',
            showAspectRatios: true,
            showRotate: true,
            showFlip: true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Done Button
    expect(find.text('Custom Cropper'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Verify Aspect Ratio chips
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('16:9'), findsOneWidget);

    // Verify Rotation & Flip icons
    expect(find.byIcon(Icons.rotate_90_degrees_cw), findsOneWidget);
    expect(find.byIcon(Icons.flip), findsNWidgets(2));
  });
}
