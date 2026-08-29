import 'package:flutter/material.dart';

/// Complete styling and theming configuration for media picker modals and dialogs.
class PickerTheme {
  /// Background color of the bottom sheet or modal dialog.
  final Color? backgroundColor;

  /// Background color for the individual option tiles/cards.
  final Color? tileBackgroundColor;

  /// Text style for the modal header title.
  final TextStyle? titleTextStyle;

  /// Text style for the option item titles.
  final TextStyle? itemTitleStyle;

  /// Text style for the option item subtitles.
  final TextStyle? itemSubtitleStyle;

  /// Text style for the cancel button.
  final TextStyle? cancelTextStyle;

  /// Custom icon widget or icon data for the Camera source.
  final Widget? cameraIcon;

  /// Custom icon widget or icon data for the Gallery source.
  final Widget? galleryIcon;

  /// Custom icon widget or icon data for the URL source.
  final Widget? urlIcon;

  /// Icon tint color for Camera.
  final Color? cameraIconColor;

  /// Icon tint color for Gallery.
  final Color? galleryIconColor;

  /// Icon tint color for URL.
  final Color? urlIconColor;

  /// Container background color for Camera icon.
  final Color? cameraIconBackgroundColor;

  /// Container background color for Gallery icon.
  final Color? galleryIconBackgroundColor;

  /// Container background color for URL icon.
  final Color? urlIconBackgroundColor;

  /// Border radius of the bottom sheet or dialog.
  final BorderRadius? borderRadius;

  /// Border radius of the individual option tiles.
  final BorderRadius? tileBorderRadius;

  /// Whether to show the top drag handle indicator on Android/Modal sheets.
  final bool showDragHandle;

  /// Color of the top drag handle indicator.
  final Color? dragHandleColor;

  /// Padding applied around the modal content.
  final EdgeInsetsGeometry? contentPadding;

  /// Creates a new [PickerTheme] configuration instance.
  const PickerTheme({
    this.backgroundColor,
    this.tileBackgroundColor,
    this.titleTextStyle,
    this.itemTitleStyle,
    this.itemSubtitleStyle,
    this.cancelTextStyle,
    this.cameraIcon,
    this.galleryIcon,
    this.urlIcon,
    this.cameraIconColor,
    this.galleryIconColor,
    this.urlIconColor,
    this.cameraIconBackgroundColor,
    this.galleryIconBackgroundColor,
    this.urlIconBackgroundColor,
    this.borderRadius,
    this.tileBorderRadius,
    this.showDragHandle = true,
    this.dragHandleColor,
    this.contentPadding,
  });

  /// Creates a sleek dark theme preset.
  factory PickerTheme.dark({
    Color backgroundColor = const Color(0xFF1E1E24),
    Color tileBackgroundColor = const Color(0xFF2A2A32),
    Color primaryAccent = const Color(0xFF7C4DFF),
  }) {
    return PickerTheme(
      backgroundColor: backgroundColor,
      tileBackgroundColor: tileBackgroundColor,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      itemTitleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      itemSubtitleStyle: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
      ),
      cancelTextStyle: const TextStyle(
        color: Colors.white60,
        fontSize: 15,
      ),
      cameraIconColor: Colors.white,
      galleryIconColor: Colors.white,
      urlIconColor: Colors.white,
      cameraIconBackgroundColor: primaryAccent.withAlpha(80),
      galleryIconBackgroundColor: primaryAccent.withAlpha(80),
      urlIconBackgroundColor: primaryAccent.withAlpha(80),
      dragHandleColor: Colors.white24,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    );
  }

  /// Creates a modern light theme preset.
  factory PickerTheme.light({
    Color backgroundColor = Colors.white,
    Color tileBackgroundColor = const Color(0xFFF4F6FB),
    Color primaryAccent = const Color(0xFF3F51B5),
  }) {
    return PickerTheme(
      backgroundColor: backgroundColor,
      tileBackgroundColor: tileBackgroundColor,
      titleTextStyle: const TextStyle(
        color: Color(0xFF1A1C1E),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      itemTitleStyle: const TextStyle(
        color: Color(0xFF1A1C1E),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      itemSubtitleStyle: const TextStyle(
        color: Color(0xFF74777F),
        fontSize: 12,
      ),
      cancelTextStyle: const TextStyle(
        color: Color(0xFF3F51B5),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      cameraIconColor: primaryAccent,
      galleryIconColor: primaryAccent,
      urlIconColor: primaryAccent,
      cameraIconBackgroundColor: primaryAccent.withAlpha(30),
      galleryIconBackgroundColor: primaryAccent.withAlpha(30),
      urlIconBackgroundColor: primaryAccent.withAlpha(30),
      dragHandleColor: const Color(0xFFC4C6D0),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    );
  }
}
