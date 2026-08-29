import 'package:flutter/material.dart';
import 'crop_options.dart';
import 'compression_options.dart';
import 'picker_theme.dart';

/// The origin source for picking or capturing media.
enum ImageSource {
  /// Open device photo library / gallery picker (zero-permission on modern OS).
  gallery,

  /// Launch device camera to capture a new photo or video.
  camera,

  /// Fetch an image from an internet URL / web link.
  url,
}

/// The media filter type.
enum MediaType {
  /// Images only (e.g. JPEG, PNG, HEIC, WebP, GIF).
  image,

  /// Videos only (e.g. MP4, MOV).
  video,

  /// Both images and videos.
  all,
}

/// Preferred physical camera lens.
enum CameraDevice {
  /// Rear / back-facing camera.
  rear,

  /// Front-facing / selfie camera.
  front,
}

/// Custom builder signature for creating fully customized picker sheets.
typedef CustomModalBuilder = Widget Function(
  BuildContext context,
  PickerOptions options,
  void Function(ImageSource? source) onSelectSource,
);

/// Complete configuration options for launching image picker sessions.
class PickerOptions {
  /// The source to pick media from.
  final ImageSource source;

  /// List of sources to display in the modal bottom sheet.
  final List<ImageSource> sources;

  /// Media type filter. Defaults to [MediaType.image].
  final MediaType mediaType;

  /// Maximum number of items allowed to be picked in a single session.
  /// If null or 1, single item picking is used.
  final int? maxCount;

  /// Preferred camera lens when [source] is [ImageSource.camera].
  final CameraDevice preferredCameraDevice;

  /// Optional cropping options to automatically trigger after picking.
  final CropOptions? cropOptions;

  /// Optional compression options to automatically process picked files.
  final CompressionOptions? compressionOptions;

  /// Styling and theme configuration for modal bottom sheets.
  final PickerTheme? theme;

  /// Optional custom builder allowing complete replacement of the bottom sheet UI.
  final CustomModalBuilder? customModalBuilder;

  /// Title text for the picker modal bottom sheet.
  final String? modalTitle;

  /// Custom label for the Camera option in the modal.
  final String? cameraOptionText;

  /// Custom label for the Gallery option in the modal.
  final String? galleryOptionText;

  /// Custom label for the URL option in the modal.
  final String? urlOptionText;

  /// Custom label for the Cancel button in the modal.
  final String? cancelButtonText;

  /// Creates a new [PickerOptions] configuration instance.
  const PickerOptions({
    this.source = ImageSource.gallery,
    this.sources = const [ImageSource.camera, ImageSource.gallery, ImageSource.url],
    this.mediaType = MediaType.image,
    this.maxCount,
    this.preferredCameraDevice = CameraDevice.rear,
    this.cropOptions,
    this.compressionOptions,
    this.theme,
    this.customModalBuilder,
    this.modalTitle = 'Select Media Source',
    this.cameraOptionText = 'Take Photo',
    this.galleryOptionText = 'Choose from Gallery',
    this.urlOptionText = 'Import from URL',
    this.cancelButtonText = 'Cancel',
  });

  /// True if multiple items can be picked.
  bool get isMultiple => maxCount != null && maxCount! > 1;

  /// Creates a copy of this [PickerOptions] with specified properties updated.
  PickerOptions copyWith({
    ImageSource? source,
    List<ImageSource>? sources,
    MediaType? mediaType,
    int? maxCount,
    CameraDevice? preferredCameraDevice,
    CropOptions? cropOptions,
    CompressionOptions? compressionOptions,
    PickerTheme? theme,
    CustomModalBuilder? customModalBuilder,
    String? modalTitle,
    String? cameraOptionText,
    String? galleryOptionText,
    String? urlOptionText,
    String? cancelButtonText,
  }) {
    return PickerOptions(
      source: source ?? this.source,
      sources: sources ?? this.sources,
      mediaType: mediaType ?? this.mediaType,
      maxCount: maxCount ?? this.maxCount,
      preferredCameraDevice: preferredCameraDevice ?? this.preferredCameraDevice,
      cropOptions: cropOptions ?? this.cropOptions,
      compressionOptions: compressionOptions ?? this.compressionOptions,
      theme: theme ?? this.theme,
      customModalBuilder: customModalBuilder ?? this.customModalBuilder,
      modalTitle: modalTitle ?? this.modalTitle,
      cameraOptionText: cameraOptionText ?? this.cameraOptionText,
      galleryOptionText: galleryOptionText ?? this.galleryOptionText,
      urlOptionText: urlOptionText ?? this.urlOptionText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
    );
  }
}
