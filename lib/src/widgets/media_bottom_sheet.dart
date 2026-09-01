import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/picker_options.dart';

/// Adaptive modal bottom sheet and action dialog for selecting media sources.
class MediaBottomSheet {
  const MediaBottomSheet._();

  /// Displays an adaptive picker sheet (Cupertino on iOS, Material 3 on Android, dialog on Web/Desktop).
  static Future<ImageSource?> show(
    BuildContext context, {
    PickerOptions options = const PickerOptions(),
  }) async {
    // If a custom builder is provided by developer, render it directly
    if (options.customModalBuilder != null) {
      return showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: options.theme?.backgroundColor ?? Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => options.customModalBuilder!(
          ctx,
          options,
          (source) => Navigator.of(ctx).pop(source),
        ),
      );
    }

    final isApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isApple) {
      return _showCupertinoActionSheet(context, options);
    } else if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return _showDesktopWebDialog(context, options);
    } else {
      return _showMaterialBottomSheet(context, options);
    }
  }

  static Future<ImageSource?> _showCupertinoActionSheet(
    BuildContext context,
    PickerOptions options,
  ) {
    final theme = options.theme;

    final actions = <CupertinoActionSheetAction>[];

    if (options.sources.contains(ImageSource.camera)) {
      actions.add(
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              theme?.cameraIcon ?? const Icon(CupertinoIcons.camera, size: 22),
              const SizedBox(width: 10),
              Text(
                options.cameraOptionText ?? 'Take Photo',
                style: theme?.itemTitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    if (options.sources.contains(ImageSource.gallery)) {
      actions.add(
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              theme?.galleryIcon ?? const Icon(CupertinoIcons.photo_on_rectangle, size: 22),
              const SizedBox(width: 10),
              Text(
                options.galleryOptionText ?? 'Choose from Gallery',
                style: theme?.itemTitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    if (options.sources.contains(ImageSource.url)) {
      actions.add(
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(ImageSource.url),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              theme?.urlIcon ?? const Icon(CupertinoIcons.link, size: 22),
              const SizedBox(width: 10),
              Text(
                options.urlOptionText ?? 'Import from URL',
                style: theme?.itemTitleStyle,
              ),
            ],
          ),
        ),
      );
    }

    return showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          options.modalTitle ?? 'Select Media Source',
          style: theme?.titleTextStyle ?? const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        actions: actions,
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(null),
          child: Text(
            options.cancelButtonText ?? 'Cancel',
            style: theme?.cancelTextStyle,
          ),
        ),
      ),
    );
  }

  static Future<ImageSource?> _showMaterialBottomSheet(
    BuildContext context,
    PickerOptions options,
  ) {
    final sysTheme = Theme.of(context);
    final theme = options.theme;

    final bgColor = theme?.backgroundColor ?? sysTheme.colorScheme.surface;
    final borderRadius = theme?.borderRadius ?? const BorderRadius.vertical(top: Radius.circular(28));
    final tileRadius = theme?.tileBorderRadius ?? BorderRadius.circular(16);

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      showDragHandle: theme?.showDragHandle ?? true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: theme?.contentPadding ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (options.modalTitle != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    options.modalTitle!,
                    style: theme?.titleTextStyle ??
                        sysTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 8),

              if (options.sources.contains(ImageSource.camera))
                ListTile(
                  tileColor: theme?.tileBackgroundColor,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme?.cameraIconBackgroundColor ?? sysTheme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: theme?.cameraIcon ??
                        Icon(
                          Icons.photo_camera_rounded,
                          color: theme?.cameraIconColor ?? sysTheme.colorScheme.onPrimaryContainer,
                        ),
                  ),
                  title: Text(
                    options.cameraOptionText ?? 'Take Photo',
                    style: theme?.itemTitleStyle ?? const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Capture with device camera',
                    style: theme?.itemSubtitleStyle,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: tileRadius),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),

              if (options.sources.contains(ImageSource.gallery)) ...[
                const SizedBox(height: 8),
                ListTile(
                  tileColor: theme?.tileBackgroundColor,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme?.galleryIconBackgroundColor ?? sysTheme.colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: theme?.galleryIcon ??
                        Icon(
                          Icons.photo_library_rounded,
                          color: theme?.galleryIconColor ?? sysTheme.colorScheme.onSecondaryContainer,
                        ),
                  ),
                  title: Text(
                    options.galleryOptionText ?? 'Choose from Gallery',
                    style: theme?.itemTitleStyle ?? const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Select from photo albums',
                    style: theme?.itemSubtitleStyle,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: tileRadius),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
              ],

              if (options.sources.contains(ImageSource.url)) ...[
                const SizedBox(height: 8),
                ListTile(
                  tileColor: theme?.tileBackgroundColor,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme?.urlIconBackgroundColor ?? sysTheme.colorScheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: theme?.urlIcon ??
                        Icon(
                          Icons.link_rounded,
                          color: theme?.urlIconColor ?? sysTheme.colorScheme.onTertiaryContainer,
                        ),
                  ),
                  title: Text(
                    options.urlOptionText ?? 'Import from URL',
                    style: theme?.itemTitleStyle ?? const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Download an image from the web',
                    style: theme?.itemSubtitleStyle,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: tileRadius),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.url),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Future<ImageSource?> _showDesktopWebDialog(
    BuildContext context,
    PickerOptions options,
  ) {
    final theme = options.theme;

    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme?.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: theme?.borderRadius ?? BorderRadius.circular(24)),
        title: Text(
          options.modalTitle ?? 'Select Media Source',
          style: theme?.titleTextStyle ?? const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (options.sources.contains(ImageSource.gallery))
              ListTile(
                tileColor: theme?.tileBackgroundColor,
                leading: theme?.galleryIcon ?? const Icon(Icons.file_upload_outlined, size: 28),
                title: Text(options.galleryOptionText ?? 'Choose File / Photo', style: theme?.itemTitleStyle),
                subtitle: Text('Select local image file', style: theme?.itemSubtitleStyle),
                shape: RoundedRectangleBorder(borderRadius: theme?.tileBorderRadius ?? BorderRadius.circular(12)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            if (options.sources.contains(ImageSource.url)) ...[
              const SizedBox(height: 8),
              ListTile(
                tileColor: theme?.tileBackgroundColor,
                leading: theme?.urlIcon ?? const Icon(Icons.link_rounded, size: 28),
                title: Text(options.urlOptionText ?? 'Import from URL', style: theme?.itemTitleStyle),
                subtitle: Text('Download directly via URL', style: theme?.itemSubtitleStyle),
                shape: RoundedRectangleBorder(borderRadius: theme?.tileBorderRadius ?? BorderRadius.circular(12)),
                onTap: () => Navigator.of(ctx).pop(ImageSource.url),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(options.cancelButtonText ?? 'Cancel', style: theme?.cancelTextStyle),
          ),
        ],
      ),
    );
  }

  /// Displays a dialog prompting the user to enter a web image URL.
  static Future<String?> showUrlInputDialog(
    BuildContext context, {
    String? initialValue,
    String title = 'Import Image from URL',
    String hintText = 'https://example.com/photo.jpg',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.link, size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the direct URL of an image (JPEG, PNG, WebP, GIF):',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.http),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.clear(),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a valid URL';
                  }
                  final uri = Uri.tryParse(val.trim());
                  if (uri == null || !uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                    return 'Enter a valid http:// or https:// URL';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
