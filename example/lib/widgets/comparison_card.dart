import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

class ComparisonCard extends StatelessWidget {
  final AdaptiveFile original;
  final AdaptiveFile processed;
  final VoidCallback? onSave;
  final VoidCallback? onReCrop;
  final VoidCallback? onReCompress;

  const ComparisonCard({
    super.key,
    required this.original,
    required this.processed,
    this.onSave,
    this.onReCrop,
    this.onReCompress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final origBytes = original.size ?? 0;
    final procBytes = processed.size ?? 0;
    final savedBytes = origBytes > procBytes ? origBytes - procBytes : 0;
    final percentSaved = origBytes > 0 ? ((savedBytes / origBytes) * 100).round() : 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Optimization Results',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (percentSaved > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-$percentSaved% Size Saved',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Side by Side Previews
                Row(
                  children: [
                    // Original Column
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Original', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          _buildImageThumbnail(original),
                          const SizedBox(height: 8),
                          Text(
                            original.formattedSize,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            original.mimeType?.split('/').last.toUpperCase() ?? 'ORIGINAL',
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),

                    // Arrow Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
                    ),

                    // Processed Column
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Optimized',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildImageThumbnail(processed),
                          const SizedBox(height: 8),
                          Text(
                            processed.formattedSize,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            processed.mimeType?.split('/').last.toUpperCase() ?? 'OUTPUT',
                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onReCrop != null)
                      TextButton.icon(
                        onPressed: onReCrop,
                        icon: const Icon(Icons.crop, size: 16),
                        label: const Text('Crop'),
                      ),
                    if (onReCompress != null)
                      TextButton.icon(
                        onPressed: onReCompress,
                        icon: const Icon(Icons.compress, size: 16),
                        label: const Text('Compress'),
                      ),
                    if (onSave != null)
                      FilledButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.save_alt_rounded, size: 16),
                        label: const Text('Save to Disk'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(AdaptiveFile file) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black12,
          child: FutureBuilder<Uint8List>(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            },
          ),
        ),
      ),
    );
  }
}
