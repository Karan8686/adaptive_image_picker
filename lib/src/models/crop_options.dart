import 'package:flutter/material.dart';

/// The shape of the crop region.
enum CropShape {
  /// Standard rectangular or square bounding box.
  rectangle,

  /// Circular bounding mask (alpha mask applied on export).
  circle,
}

/// Represents a fixed or freeform aspect ratio for cropping.
class CropAspectRatio {
  /// The ratio width component (e.g. 16 in 16:9), or null for freeform/original.
  final double? ratioX;

  /// The ratio height component (e.g. 9 in 16:9), or null for freeform/original.
  final double? ratioY;

  /// Display label (e.g. "16:9", "1:1", "Original", "Free").
  final String label;

  /// Creates a [CropAspectRatio] with given [ratioX], [ratioY], and [label].
  const CropAspectRatio({
    this.ratioX,
    this.ratioY,
    required this.label,
  });

  /// Custom aspect ratio constructor.
  CropAspectRatio.custom({
    required double ratioX,
    required double ratioY,
    String? label,
  }) : this(
          ratioX: ratioX,
          ratioY: ratioY,
          label: label ?? '${ratioX.toInt()}:${ratioY.toInt()}',
        );

  /// Calculates the decimal aspect ratio (width / height), or null if freeform.
  double? get ratio {
    if (ratioX != null && ratioY != null && ratioY! > 0) {
      return ratioX! / ratioY!;
    }
    return null;
  }

  /// Whether this ratio represents freeform unconstrained cropping.
  bool get isFreeform => ratioX == null || ratioY == null;

  /// Whether this ratio represents keeping original image aspect ratio.
  bool get isOriginal => label == 'Original';

  /// Freeform unconstrained cropping preset.
  static const CropAspectRatio freeform = CropAspectRatio(label: 'Free');

  /// Keeps original image aspect ratio preset.
  static const CropAspectRatio original = CropAspectRatio(label: 'Original');

  /// 1:1 Square aspect ratio preset.
  static const CropAspectRatio square = CropAspectRatio(ratioX: 1, ratioY: 1, label: '1:1');

  /// 16:9 Landscape widescreen aspect ratio preset.
  static const CropAspectRatio ratio16_9 = CropAspectRatio(ratioX: 16, ratioY: 9, label: '16:9');

  /// 9:16 Portrait story / mobile aspect ratio preset.
  static const CropAspectRatio ratio9_16 = CropAspectRatio(ratioX: 9, ratioY: 16, label: '9:16');

  /// 4:3 Standard photo aspect ratio preset.
  static const CropAspectRatio ratio4_3 = CropAspectRatio(ratioX: 4, ratioY: 3, label: '4:3');

  /// 3:4 Portrait photo aspect ratio preset.
  static const CropAspectRatio ratio3_4 = CropAspectRatio(ratioX: 3, ratioY: 4, label: '3:4');

  /// 3:2 Classic 35mm film aspect ratio preset.
  static const CropAspectRatio ratio3_2 = CropAspectRatio(ratioX: 3, ratioY: 2, label: '3:2');

  /// 2:3 Portrait 35mm film aspect ratio preset.
  static const CropAspectRatio ratio2_3 = CropAspectRatio(ratioX: 2, ratioY: 3, label: '2:3');

  /// Freeform aspect ratio alias for [freeform].
  static const CropAspectRatio free = freeform;

  /// 1:1 Square aspect ratio alias for [square].
  static const CropAspectRatio ratio1x1 = square;

  /// 16:9 Landscape aspect ratio alias for [ratio16_9].
  static const CropAspectRatio ratio16x9 = ratio16_9;

  /// 9:16 Portrait aspect ratio alias for [ratio9_16].
  static const CropAspectRatio ratio9x16 = ratio9_16;

  /// 4:3 Aspect ratio alias for [ratio4_3].
  static const CropAspectRatio ratio4x3 = ratio4_3;

  /// 3:4 Aspect ratio alias for [ratio3_4].
  static const CropAspectRatio ratio3x4 = ratio3_4;

  /// 3:2 Aspect ratio alias for [ratio3_2].
  static const CropAspectRatio ratio3x2 = ratio3_2;

  /// 2:3 Aspect ratio alias for [ratio2_3].
  static const CropAspectRatio ratio2x3 = ratio2_3;

  /// Default list of available presets provided in the cropper UI.
  static const List<CropAspectRatio> defaultPresets = [
    original,
    freeform,
    square,
    ratio4_3,
    ratio16_9,
    ratio3_2,
    ratio9_16,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropAspectRatio &&
        other.ratioX == ratioX &&
        other.ratioY == ratioY &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(ratioX, ratioY, label);
}

/// Configuration options for the interactive image cropper.
class CropOptions {
  /// Pre-selected aspect ratio for cropping.
  final CropAspectRatio? aspectRatio;

  /// Alias for [aspectRatio].
  CropAspectRatio? get aspectRatioPreset => aspectRatio;

  /// List of aspect ratio presets available to choose in the UI.
  final List<CropAspectRatio> availableAspectRatios;

  /// The crop shape: [CropShape.rectangle] or [CropShape.circle].
  final CropShape shape;

  /// If true, the aspect ratio is locked and cannot be changed or resized freely.
  final bool lockAspectRatio;

  /// If true, rotation controls are enabled.
  final bool allowRotation;

  /// If true, flip horizontal/vertical controls are enabled.
  final bool allowFlipping;

  /// Initial rotation angle in degrees (0, 90, 180, 270).
  final int initialRotation;

  /// Title displayed in the cropper top bar.
  final String? title;

  /// Color of the toolbar/app bar.
  final Color? toolbarColor;

  /// Color of the active crop handles and frame.
  final Color? activeHandleColor;

  /// Color of the rule-of-thirds grid lines.
  final Color? gridColor;

  /// Color of the dimmed overlay outside the crop box.
  final Color? overlayColor;

  /// Color of the crop frame border.
  final Color? cropFrameColor;

  /// Background color of the crop workspace.
  final Color? backgroundColor;

  /// Whether to display the 3x3 grid lines inside the crop frame.
  final bool showGrid;

  /// Whether to display the reset button.
  final bool showReset;

  /// Whether to display the aspect ratio selection bar.
  final bool showAspectRatios;

  /// Whether to display the rotate button.
  final bool showRotate;

  /// Whether to display the flip buttons.
  final bool showFlip;

  /// Text for the "Done" confirmation button.
  final String doneButtonText;

  /// Text for the "Cancel" button.
  final String cancelButtonText;

  /// Text for the "Reset" button.
  final String resetButtonText;

  /// Creates a new [CropOptions] configuration instance.
  const CropOptions({
    CropAspectRatio? aspectRatio,
    CropAspectRatio? aspectRatioPreset,
    this.availableAspectRatios = CropAspectRatio.defaultPresets,
    this.shape = CropShape.rectangle,
    this.lockAspectRatio = false,
    this.allowRotation = true,
    this.allowFlipping = true,
    this.initialRotation = 0,
    this.title = 'Crop & Edit',
    this.toolbarColor,
    this.activeHandleColor,
    this.gridColor,
    this.overlayColor,
    this.cropFrameColor,
    this.backgroundColor,
    this.showGrid = true,
    this.showReset = true,
    this.showAspectRatios = true,
    this.showRotate = true,
    this.showFlip = true,
    this.doneButtonText = 'Done',
    this.cancelButtonText = 'Cancel',
    this.resetButtonText = 'Reset',
  }) : aspectRatio = aspectRatio ?? aspectRatioPreset;

  /// Creates a circular profile avatar crop option preset.
  factory CropOptions.circle({
    String title = 'Crop Profile Photo',
    Color? activeHandleColor,
    Color? overlayColor,
    bool showGrid = true,
  }) {
    return CropOptions(
      shape: CropShape.circle,
      aspectRatio: CropAspectRatio.square,
      lockAspectRatio: true,
      showAspectRatios: false,
      showGrid: showGrid,
      title: title,
      activeHandleColor: activeHandleColor,
      overlayColor: overlayColor,
    );
  }

  /// Creates a square crop option preset.
  factory CropOptions.square({
    String title = 'Crop Square',
    bool lockAspectRatio = true,
  }) {
    return CropOptions(
      aspectRatio: CropAspectRatio.square,
      lockAspectRatio: lockAspectRatio,
      title: title,
    );
  }

  /// Creates a copy of this [CropOptions] with specified properties updated.
  CropOptions copyWith({
    CropAspectRatio? aspectRatio,
    List<CropAspectRatio>? availableAspectRatios,
    CropShape? shape,
    bool? lockAspectRatio,
    bool? allowRotation,
    bool? allowFlipping,
    int? initialRotation,
    String? title,
    Color? toolbarColor,
    Color? activeHandleColor,
    Color? gridColor,
    Color? overlayColor,
    Color? cropFrameColor,
    Color? backgroundColor,
    bool? showGrid,
    bool? showReset,
    bool? showAspectRatios,
    bool? showRotate,
    bool? showFlip,
    String? doneButtonText,
    String? cancelButtonText,
    String? resetButtonText,
  }) {
    return CropOptions(
      aspectRatio: aspectRatio ?? this.aspectRatio,
      availableAspectRatios: availableAspectRatios ?? this.availableAspectRatios,
      shape: shape ?? this.shape,
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
      allowRotation: allowRotation ?? this.allowRotation,
      allowFlipping: allowFlipping ?? this.allowFlipping,
      initialRotation: initialRotation ?? this.initialRotation,
      title: title ?? this.title,
      toolbarColor: toolbarColor ?? this.toolbarColor,
      activeHandleColor: activeHandleColor ?? this.activeHandleColor,
      gridColor: gridColor ?? this.gridColor,
      overlayColor: overlayColor ?? this.overlayColor,
      cropFrameColor: cropFrameColor ?? this.cropFrameColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showGrid: showGrid ?? this.showGrid,
      showReset: showReset ?? this.showReset,
      showAspectRatios: showAspectRatios ?? this.showAspectRatios,
      showRotate: showRotate ?? this.showRotate,
      showFlip: showFlip ?? this.showFlip,
      doneButtonText: doneButtonText ?? this.doneButtonText,
      cancelButtonText: cancelButtonText ?? this.cancelButtonText,
      resetButtonText: resetButtonText ?? this.resetButtonText,
    );
  }
}
