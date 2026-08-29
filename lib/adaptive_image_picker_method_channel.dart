import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/models/adaptive_file.dart';
import 'src/models/picker_options.dart';
import 'adaptive_image_picker_platform_interface.dart';

/// An implementation of [AdaptiveImagePickerPlatform] that uses method channels.
class MethodChannelAdaptiveImagePicker extends AdaptiveImagePickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('adaptive_image_picker');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<AdaptiveFile>> pickImages(PickerOptions options) async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'pickImages',
      {
        'mediaType': options.mediaType.name,
        'maxCount': options.maxCount ?? 1,
        'isMultiple': options.isMultiple,
      },
    );

    if (result == null || result.isEmpty) {
      return [];
    }

    return result.map<AdaptiveFile>((item) {
      if (item is Map) {
        return AdaptiveFile.fromMap(item);
      } else if (item is String) {
        return AdaptiveFile.fromPath(item);
      } else {
        throw FormatException('Unexpected item type from pickImages: ${item.runtimeType}');
      }
    }).toList();
  }

  @override
  Future<AdaptiveFile?> takePhoto(PickerOptions options) async {
    final result = await methodChannel.invokeMethod<dynamic>(
      'takePhoto',
      {
        'preferredCameraDevice': options.preferredCameraDevice.name,
      },
    );

    if (result == null) {
      return null;
    }

    if (result is Map) {
      return AdaptiveFile.fromMap(result);
    } else if (result is String) {
      return AdaptiveFile.fromPath(result);
    } else {
      throw FormatException('Unexpected result type from takePhoto: ${result.runtimeType}');
    }
  }
}
