# Changelog

All notable changes to this project will be documented in this file.

## 1.0.2

* **Feature**: Added full native Desktop support for **Windows**, **macOS**, and **Linux** using Flutter's `dartPluginClass` and `file_selector`.
* **Improvement**: Streamlined multi-platform file picking and camera fallbacks across desktop platforms.

## 1.0.1

* **Fix**: Bumped `image` dependency constraint to `^4.9.2` to resolve `encodeWebP` compilation errors during lower bounds downgrade analysis.
* **Fix**: Replaced direct `dart:io` imports with conditional imports and `defaultTargetPlatform` to ensure full Web and WASM runtime compatibility.
* **Docs**: Added docstrings and private constructors for utility classes to achieve 100% public API documentation coverage.
* **Docs**: Corrected repository and issue tracker URLs in `pubspec.yaml`.

## 1.0.0

* Initial release of `adaptive_image_picker`.
* Modern Android 13+ Photo Picker integration (`PickVisualMedia` / `PickMultipleVisualMedia`) with zero runtime storage permissions.
* iOS 14+ `PHPickerViewController` integration for zero-permission photo library access.
* Device camera capture with automated `FileProvider` setup on Android and `UIImagePickerController` on iOS.
* Pure-Dart image cropping engine with preset aspect ratios, freeform cropping, 90° clockwise rotation, and horizontal/vertical flipping.
* Circular avatar crop masking with antialiased transparent alpha channel.
* Binary search target-size image compression engine guaranteeing file size $\le$ `maxBytes`.
* WebP, JPEG, and PNG output format encoding.
* Adaptive UI bottom sheet and modal source selector (Cupertino on iOS, Material 3 on Android, Dialog on Web/Desktop).
* Full web support using `package:web` and JS interop.
* Rich `AdaptiveFile` representation with size formatting, lazy byte streaming, and disk persistence helpers.
* Direct URL import and image downloading with integrated crop and compression pipeline.
* Comprehensive unit, widget, and integration test coverage.
