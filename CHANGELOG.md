# Changelog

All notable changes to this project will be documented in this file.

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
