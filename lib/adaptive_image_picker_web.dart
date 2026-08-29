import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'src/models/adaptive_file.dart';
import 'src/models/picker_options.dart';
import 'adaptive_image_picker_platform_interface.dart';

/// A web implementation of the AdaptiveImagePickerPlatform of the AdaptiveImagePicker plugin.
class AdaptiveImagePickerWeb extends AdaptiveImagePickerPlatform {
  /// Constructs a AdaptiveImagePickerWeb
  AdaptiveImagePickerWeb();

  /// Registers this class as the default instance of [AdaptiveImagePickerPlatform].
  static void registerWith(Registrar registrar) {
    AdaptiveImagePickerPlatform.instance = AdaptiveImagePickerWeb();
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = web.window.navigator.userAgent;
    return version;
  }

  @override
  Future<List<AdaptiveFile>> pickImages(PickerOptions options) async {
    final completer = Completer<List<AdaptiveFile>>();

    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.style.display = 'none';

    switch (options.mediaType) {
      case MediaType.image:
        input.accept = 'image/*';
        break;
      case MediaType.video:
        input.accept = 'video/*';
        break;
      case MediaType.all:
        input.accept = 'image/*,video/*';
        break;
    }

    if (options.isMultiple) {
      input.multiple = true;
    }

    input.onchange = ((web.Event event) {
      final fileList = input.files;
      if (fileList == null || fileList.length == 0) {
        if (!completer.isCompleted) completer.complete([]);
        input.remove();
        return;
      }

      final List<Future<AdaptiveFile>> fileFutures = [];
      for (int i = 0; i < fileList.length; i++) {
        final web.File? file = fileList.item(i);
        if (file != null) {
          fileFutures.add(_readWebFile(file));
        }
      }

      Future.wait(fileFutures).then((files) {
        if (!completer.isCompleted) completer.complete(files);
      }).catchError((err) {
        if (!completer.isCompleted) completer.completeError(err);
      }).whenComplete(() {
        input.remove();
      });
    }).toJS;

    // Handle cancel / window focus back
    web.window.addEventListener(
      'focus',
      ((web.Event event) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!completer.isCompleted && (input.files == null || input.files?.length == 0)) {
            completer.complete([]);
            input.remove();
          }
        });
      }).toJS,
      true.toJS,
    );

    web.document.body?.appendChild(input);
    input.click();

    return completer.future;
  }

  @override
  Future<AdaptiveFile?> takePhoto(PickerOptions options) async {
    final completer = Completer<AdaptiveFile?>();

    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = 'image/*';
    input.style.display = 'none';

    // Specify capture device
    if (options.preferredCameraDevice == CameraDevice.front) {
      input.setAttribute('capture', 'user');
    } else {
      input.setAttribute('capture', 'environment');
    }

    input.onchange = ((web.Event event) {
      final fileList = input.files;
      if (fileList == null || fileList.length == 0) {
        if (!completer.isCompleted) completer.complete(null);
        input.remove();
        return;
      }

      final web.File? file = fileList.item(0);
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        input.remove();
        return;
      }

      _readWebFile(file).then((adaptiveFile) {
        if (!completer.isCompleted) completer.complete(adaptiveFile);
      }).catchError((err) {
        if (!completer.isCompleted) completer.completeError(err);
      }).whenComplete(() {
        input.remove();
      });
    }).toJS;

    web.document.body?.appendChild(input);
    input.click();

    return completer.future;
  }

  static Future<AdaptiveFile> _readWebFile(web.File file) {
    final completer = Completer<AdaptiveFile>();
    final reader = web.FileReader();

    reader.onload = ((web.Event event) {
      final result = reader.result;
      if (result != null && result.isA<JSArrayBuffer>()) {
        final bytes = Uint8List.view((result as JSArrayBuffer).toDart);
        final adaptiveFile = AdaptiveFile.fromBytes(
          bytes,
          name: file.name,
          mimeType: file.type.isNotEmpty ? file.type : null,
          size: file.size,
          lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified),
        );
        completer.complete(adaptiveFile);
      } else {
        completer.completeError(StateError('Failed to read web file buffer.'));
      }
    }).toJS;

    reader.onerror = ((web.Event event) {
      completer.completeError(StateError('FileReader error occurred reading web file.'));
    }).toJS;

    reader.readAsArrayBuffer(file);
    return completer.future;
  }
}
