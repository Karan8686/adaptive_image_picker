import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';
import '../widgets/media_detail_sheet.dart';

class GalleryScreen extends StatefulWidget {
  final List<AdaptiveFile> files;
  final Function(int, AdaptiveFile) onFileUpdated;
  final Function(int) onFileDeleted;
  final VoidCallback onClearAll;

  const GalleryScreen({
    super.key,
    required this.files,
    required this.onFileUpdated,
    required this.onFileDeleted,
    required this.onClearAll,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isGridView = false;

  Future<void> _handleSaveToDisk(AdaptiveFile file) async {
    if (kIsWeb) {
      await file.saveToBrowser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to browser: ${file.name}'),
            backgroundColor: Colors.teal.shade700,
          ),
        );
      }
      return;
    }
    final tempDir = Directory.systemTemp;
    final saved = await file.saveToDirectory(tempDir.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to disk: ${saved.path}'),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 72,
                color: theme.hintColor.withAlpha(80),
              ),
              const SizedBox(height: 16),
              Text(
                'No media collected yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the Studio or Recipes tab to pick, crop, compress, or download images.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Controls Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${widget.files.length} Item${widget.files.length == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear Gallery',
                onPressed: widget.onClearAll,
              ),
            ],
          ),
        ),

        Expanded(
          child: _isGridView ? _buildGrid(theme) : _buildList(theme),
        ),
      ],
    );
  }

  Widget _buildList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.files.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final file = widget.files[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              MediaDetailSheet.show(
                context,
                file: file,
                onFileUpdated: (updated) => widget.onFileUpdated(index, updated),
                onDelete: () => widget.onFileDeleted(index),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: _buildThumbnail(file),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildBadge(file.formattedSize, theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer),
                            const SizedBox(width: 6),
                            _buildBadge(file.mimeType?.split('/').last.toUpperCase() ?? 'FILE', theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Save to Disk',
                    onPressed: () => _handleSaveToDisk(file),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: widget.files.length,
      itemBuilder: (context, index) {
        final file = widget.files[index];
        return InkWell(
          onTap: () {
            MediaDetailSheet.show(
              context,
              file: file,
              onFileUpdated: (updated) => widget.onFileUpdated(index, updated),
              onDelete: () => widget.onFileDeleted(index),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildThumbnail(file),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    file.formattedSize,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(AdaptiveFile file) {
    return Container(
      color: Colors.black12,
      child: FutureBuilder<Uint8List>(
        future: file.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      ),
    );
  }

  Widget _buildBadge(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}
