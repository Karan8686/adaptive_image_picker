import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/models/adaptive_file.dart';
import 'src/models/picker_options.dart';
import 'adaptive_image_picker_method_channel.dart';

/// The interface that implementations of adaptive_image_picker must implement.
abstract class AdaptiveImagePickerPlatform extends PlatformInterface {
  /// Constructs an AdaptiveImagePickerPlatform.
  AdaptiveImagePickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdaptiveImagePickerPlatform _instance = MethodChannelAdaptiveImagePicker();

  /// The default instance of [AdaptiveImagePickerPlatform] to use.
  static AdaptiveImagePickerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AdaptiveImagePickerPlatform] when
  /// they register themselves.
  static set instance(AdaptiveImagePickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Picks one or more images from the device gallery/photo picker.
  Future<List<AdaptiveFile>> pickImages(PickerOptions options) {
    throw UnimplementedError('pickImages() has not been implemented.');
  }

  /// Captures a photo using the device camera.
  Future<AdaptiveFile?> takePhoto(PickerOptions options) {
    throw UnimplementedError('takePhoto() has not been implemented.');
  }

  /// Returns the platform version string (for diagnostics).
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }
}
