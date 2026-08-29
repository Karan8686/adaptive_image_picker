import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdaptiveImagePickerPlatform
    with MockPlatformInterfaceMixin
    implements AdaptiveImagePickerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('iOS 17.0');

  @override
  Future<List<AdaptiveFile>> pickImages(PickerOptions options) {
    return Future.value([
      AdaptiveFile.fromBytes(Uint8List.fromList([1, 2, 3]), name: 'mock_gallery.jpg'),
    ]);
  }

  @override
  Future<AdaptiveFile?> takePhoto(PickerOptions options) {
    return Future.value(
      AdaptiveFile.fromBytes(Uint8List.fromList([4, 5, 6]), name: 'mock_camera.jpg'),
    );
  }
}

void main() {
  final AdaptiveImagePickerPlatform initialPlatform = AdaptiveImagePickerPlatform.instance;

  test('$MethodChannelAdaptiveImagePicker is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAdaptiveImagePicker>());
  });

  group('AdaptiveImagePicker high-level API', () {
    setUp(() {
      AdaptiveImagePickerPlatform.instance = MockAdaptiveImagePickerPlatform();
    });

    test('pickImage from gallery invokes platform and returns file', () async {
      final file = await AdaptiveImagePicker.pickImage(source: ImageSource.gallery);
      expect(file, isNotNull);
      expect(file!.name, 'mock_gallery.jpg');
    });

    test('pickImage from camera invokes platform and returns file', () async {
      final file = await AdaptiveImagePicker.pickImage(source: ImageSource.camera);
      expect(file, isNotNull);
      expect(file!.name, 'mock_camera.jpg');
    });

    test('pickMultiple returns list of files', () async {
      final files = await AdaptiveImagePicker.pickMultiple(maxCount: 5);
      expect(files.length, 1);
      expect(files.first.name, 'mock_gallery.jpg');
    });
  });
}
