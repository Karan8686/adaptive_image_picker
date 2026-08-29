import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

class MediaDetailSheet extends StatelessWidget {
  final AdaptiveFile file;
  final Function(AdaptiveFile) onFileUpdated;
  final VoidCallback onDelete;

  const MediaDetailSheet({
    super.key,
    required this.file,
    required this.onFileUpdated,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required AdaptiveFile file,
    required Function(AdaptiveFile) onFileUpdated,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaDetailSheet(
        file: file,
        onFileUpdated: onFileUpdated,
        onDelete: onDelete,
      ),
    );
  }

  Future<void> _handleCrop(BuildContext context) async {
    Navigator.pop(context);
    final cropped = await AdaptiveImagePicker.cropImage(
      file: file,
      context: context,
      options: const CropOptions(
        title: 'Crop Image',
        showGrid: true,
        allowRotation: true,
        allowFlipping: true,
      ),
    );
    if (cropped != null) {
      onFileUpdated(cropped);
    }
  }

  Future<void> _handleCompress(BuildContext context) async {
    int targetKb = 150;
    final selectedKb = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int tempKb = targetKb;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Target Size Compression'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Target max size: $tempKb KB', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Slider(
                    value: tempKb.toDouble(),
                    min: 20,
                    max: 1000,
                    divisions: 49,
                    label: '${tempKb}KB',
                    onChanged: (val) {
                      setDialogState(() => tempKb = val.round());
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, tempKb), child: const Text('Compress')),
              ],
            );
          },
        );
      },
    );

    if (selectedKb != null && context.mounted) {
      Navigator.pop(context);
      final compressed = await AdaptiveImagePicker.compressImage(
        file: file,
        options: CompressionOptions.targetSize(
          selectedKb * 1024,
          format: OutputFormat.webp,
        ),
      );
      onFileUpdated(compressed);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Compressed to ${compressed.formattedSize} (<${selectedKb}KB)'),
            backgroundColor: Colors.teal.shade700,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveToDisk(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File is stored in Web browser memory.')),
      );
      return;
    }
    final tempDir = Directory.systemTemp;
    final saved = await file.saveToDirectory(tempDir.path);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to disk: ${saved.path}'),
          backgroundColor: Colors.teal.shade700,
          action: SnackBarAction(
            label: 'Copy Path',
            textColor: Colors.white,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: saved.path ?? ''));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Image Preview Container
          Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return InteractiveViewer(
                    maxScale: 4.0,
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          // Metadata Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMetaRow('File Size', file.formattedSize, Icons.data_usage_rounded, theme),
                  const SizedBox(height: 8),
                  _buildMetaRow('MIME Type', file.mimeType ?? 'Unknown', Icons.image_outlined, theme),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    'Dimensions',
                    file.width != null && file.height != null ? '${file.width} x ${file.height} px' : 'Calculated on load',
                    Icons.aspect_ratio_rounded,
                    theme,
                  ),
                  if (file.path != null) ...[
                    const SizedBox(height: 8),
                    _buildMetaRow('Storage Path', file.path!, Icons.folder_open_rounded, theme),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleCrop(context),
                    icon: const Icon(Icons.crop),
                    label: const Text('Crop'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleCompress(context),
                    icon: const Icon(Icons.compress),
                    label: const Text('Compress'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _handleSaveToDisk(context),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
