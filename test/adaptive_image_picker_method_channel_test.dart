import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelAdaptiveImagePicker platform = MethodChannelAdaptiveImagePicker();
  const MethodChannel channel = MethodChannel('adaptive_image_picker');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getPlatformVersion') {
        return 'Android 14';
      }
      if (methodCall.method == 'pickImages') {
        return [
          {
            'path': '/tmp/test_image.jpg',
            'name': 'test_image.jpg',
            'size': 1024,
            'mimeType': 'image/jpeg',
          }
        ];
      }
      if (methodCall.method == 'takePhoto') {
        return {
          'path': '/tmp/camera_photo.jpg',
          'name': 'camera_photo.jpg',
          'size': 2048,
          'mimeType': 'image/jpeg',
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), 'Android 14');
  });

  test('pickImages invokes channel and parses Map result', () async {
    final results = await platform.pickImages(const PickerOptions(source: ImageSource.gallery));
    expect(results.length, 1);
    expect(results.first.name, 'test_image.jpg');
    expect(results.first.path, '/tmp/test_image.jpg');
    expect(results.first.size, 1024);
  });

  test('takePhoto invokes channel and parses result', () async {
    final result = await platform.takePhoto(const PickerOptions(source: ImageSource.camera));
    expect(result, isNotNull);
    expect(result!.name, 'camera_photo.jpg');
    expect(result.path, '/tmp/camera_photo.jpg');
  });
}
