import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';

class RecipesScreen extends StatefulWidget {
  final Function(AdaptiveFile) onMediaAdded;
  final Function(List<AdaptiveFile>) onMultipleMediaAdded;

  const RecipesScreen({
    super.key,
    required this.onMediaAdded,
    required this.onMultipleMediaAdded,
  });

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  bool _isBusy = false;

  Future<void> _runRecipe({
    required String title,
    required Future<void> Function() action,
  }) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // Recipe 1: Profile Avatar (Circle Mask + 100KB WebP)
  Future<void> _recipeProfileAvatar() async {
    await _runRecipe(
      title: 'Profile Avatar',
      action: () async {
        final file = await AdaptiveImagePicker.pickImage(
          source: ImageSource.gallery,
          context: context,
          cropOptions: CropOptions.circle(
            title: 'Set Profile Picture',
            showGrid: true,
          ),
          compressionOptions: CompressionOptions.avatar(
            maxBytes: 100 * 1024, // <= 100 KB
          ),
        );
        if (file != null && mounted) {
          widget.onMediaAdded(file);
          _showToast('Avatar saved: ${file.name} (${file.formattedSize})');
        }
      },
    );
  }

  // Recipe 2: Social Media 16:9 Landscape Banner
  Future<void> _recipeSocialBanner() async {
    await _runRecipe(
      title: 'Social Banner',
      action: () async {
        final file = await AdaptiveImagePicker.pickImage(
          source: ImageSource.gallery,
          context: context,
          cropOptions: const CropOptions(
            title: '16:9 Landscape Banner',
            aspectRatioPreset: CropAspectRatio.ratio16x9,
            lockAspectRatio: true,
          ),
          compressionOptions: CompressionOptions.webOptimized(
            maxBytes: 500 * 1024,
          ),
        );
        if (file != null && mounted) {
          widget.onMediaAdded(file);
          _showToast('Banner created: ${file.name} (${file.formattedSize})');
        }
      },
    );
  }

  // Recipe 3: Document / Receipt Camera Scanner
  Future<void> _recipeDocumentScan() async {
    await _runRecipe(
      title: 'Document Scanner',
      action: () async {
        final file = await AdaptiveImagePicker.pickImage(
          source: ImageSource.camera,
          context: context,
          cropOptions: const CropOptions(
            title: 'Crop Document Bounds',
            showGrid: true,
            allowRotation: true,
            allowFlipping: true,
          ),
          compressionOptions: const CompressionOptions(
            maxBytes: 300 * 1024,
            format: OutputFormat.jpeg,
            maxWidth: 1600,
          ),
        );
        if (file != null && mounted) {
          widget.onMediaAdded(file);
          _showToast('Document saved: ${file.name} (${file.formattedSize})');
        }
      },
    );
  }

  // Recipe 4: Multi-Photo Batch Picker (Up to 5 photos)
  Future<void> _recipeBatchMultiPick() async {
    await _runRecipe(
      title: 'Batch Pick',
      action: () async {
        final files = await AdaptiveImagePicker.pickMultiple(
          maxCount: 5,
          compressionOptions: const CompressionOptions(
            maxBytes: 250 * 1024,
            format: OutputFormat.webp,
          ),
        );
        if (files.isNotEmpty && mounted) {
          widget.onMultipleMediaAdded(files);
          _showToast('Imported and compressed ${files.length} photos!');
        }
      },
    );
  }

  // Recipe 5: Download from URL + Auto-Save to Disk
  Future<void> _recipeUrlDownloadAndSave() async {
    await _runRecipe(
      title: 'URL Import & Save',
      action: () async {
        final sampleUrls = [
          'https://picsum.photos/800/600',
          'https://raw.githubusercontent.com/flutter/website/main/src/assets/images/docs/owl.jpg',
          'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=800',
        ];

        final chosenUrl = await showDialog<String>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Choose Test Image URL'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, sampleUrls[0]),
                child: const ListTile(
                  leading: Icon(Icons.image),
                  title: Text('Picsum Landscape (800x600)'),
                  subtitle: Text('Fast public test image'),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, sampleUrls[1]),
                child: const ListTile(
                  leading: Icon(Icons.flutter_dash),
                  title: Text('Flutter Owl (Official Sample)'),
                  subtitle: Text('GitHub raw asset'),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, sampleUrls[2]),
                child: const ListTile(
                  leading: Icon(Icons.art_track),
                  title: Text('Unsplash Artwork'),
                  subtitle: Text('High resolution sample'),
                ),
              ),
            ],
          ),
        );

        if (chosenUrl == null || !mounted) return;

        // Download, crop, compress
        final file = await AdaptiveImagePicker.fromUrl(
          chosenUrl,
          context: context,
          cropOptions: const CropOptions(title: 'Crop Downloaded Image'),
          compressionOptions: const CompressionOptions(
            maxBytes: 350 * 1024,
            format: OutputFormat.webp,
          ),
        );

        // Save to local temporary disk
        if (!kIsWeb) {
          final tempDir = Directory.systemTemp;
          final saved = await file.saveToDirectory(tempDir.path);
          widget.onMediaAdded(saved);
          _showToast('Downloaded & saved to disk: ${saved.path}');
        } else {
          widget.onMediaAdded(file);
          _showToast('Downloaded in Web memory: ${file.formattedSize}');
        }
      },
    );
  }

  // Recipe 6: Full Adaptive Action Sheet Flow
  Future<void> _recipeAdaptiveModal() async {
    await _runRecipe(
      title: 'Adaptive Modal Sheet',
      action: () async {
        final file = await AdaptiveImagePicker.showPickerModal(
          context: context,
          options: const PickerOptions(
            modalTitle: 'Select Profile Photo',
            sources: [ImageSource.camera, ImageSource.gallery, ImageSource.url],
          ),
          cropOptions: CropOptions.circle(title: 'Adjust Avatar'),
          compressionOptions: const CompressionOptions(
            maxBytes: 150 * 1024,
            format: OutputFormat.webp,
          ),
        );
        if (file != null && mounted) {
          widget.onMediaAdded(file);
          _showToast('Picked: ${file.name} (${file.formattedSize})');
        }
      },
    );
  }

  void _showToast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          'Production Ready Recipes',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Pre-configured end-to-end workflows demonstrating real-world mobile app integration patterns.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 16),

        if (_isBusy) const LinearProgressIndicator(),
        const SizedBox(height: 8),

        // Recipe 1: Profile Avatar
        _buildRecipeCard(
          title: 'User Profile Avatar',
          description: 'Zero-permission gallery pick ➔ Circular alpha crop mask ➔ 100 KB WebP compression.',
          icon: Icons.account_circle_rounded,
          color: Colors.blue,
          onTap: _isBusy ? null : _recipeProfileAvatar,
          theme: theme,
        ),
        const SizedBox(height: 12),

        // Recipe 2: Social Media Banner
        _buildRecipeCard(
          title: '16:9 Landscape Banner',
          description: 'Picks image ➔ Locks 16:9 aspect ratio ➔ Downscales & compresses to WebP for fast web delivery.',
          icon: Icons.panorama_rounded,
          color: Colors.deepPurple,
          onTap: _isBusy ? null : _recipeSocialBanner,
          theme: theme,
        ),
        const SizedBox(height: 12),

        // Recipe 3: Document & Receipt Capture
        _buildRecipeCard(
          title: 'Document / Receipt Scanner',
          description: 'Camera capture via FileProvider ➔ Pure-Dart EXIF orientation & crop bounds ➔ High-contrast JPEG.',
          icon: Icons.document_scanner_rounded,
          color: Colors.amber.shade800,
          onTap: _isBusy ? null : _recipeDocumentScan,
          theme: theme,
        ),
        const SizedBox(height: 12),

        // Recipe 4: Batch Multi-Photo Picker
        _buildRecipeCard(
          title: 'Batch Multi-Photo Uploader',
          description: 'Selects up to 5 photos simultaneously from native PhotoPicker ➔ Compresses each photo concurrently.',
          icon: Icons.collections_bookmark_rounded,
          color: Colors.teal,
          onTap: _isBusy ? null : _recipeBatchMultiPick,
          theme: theme,
        ),
        const SizedBox(height: 12),

        // Recipe 5: URL Download & Auto-Save to Disk
        _buildRecipeCard(
          title: 'URL Downloader & Local Disk Saver',
          description: 'Fetches image over HTTP ➔ Interactive crop ➔ Binary compression ➔ Writes directly to device storage.',
          icon: Icons.cloud_download_rounded,
          color: Colors.indigo,
          onTap: _isBusy ? null : _recipeUrlDownloadAndSave,
          theme: theme,
        ),
        const SizedBox(height: 12),

        // Recipe 6: Full Adaptive Action Sheet
        _buildRecipeCard(
          title: 'Adaptive Native Modal Sheet',
          description: 'Renders Cupertino Action Sheet on iOS, Material 3 Bottom Sheet on Android, and responsive dialogs on Web.',
          icon: Icons.view_comfortable_rounded,
          color: Colors.pink,
          onTap: _isBusy ? null : _recipeAdaptiveModal,
          theme: theme,
        ),
        const SizedBox(height: 12),

        // Recipe 7: Custom Branded Theme & Custom Builder
        _buildRecipeCard(
          title: 'Custom Branded Theme & Builder',
          description: 'Showcases custom colors, dark palette, rounded cards, custom icons, or full customModalBuilder.',
          icon: Icons.palette_rounded,
          color: Colors.orange.shade800,
          onTap: _isBusy ? null : _recipeCustomThemedModal,
          theme: theme,
        ),
      ],
    );
  }

  // Recipe 7: Custom Themed Bottom Sheet Flow
  Future<void> _recipeCustomThemedModal() async {
    await _runRecipe(
      title: 'Custom Themed Modal',
      action: () async {
        final file = await AdaptiveImagePicker.showPickerModal(
          context: context,
          options: PickerOptions(
            modalTitle: 'Custom Branded Picker',
            theme: PickerTheme(
              backgroundColor: const Color(0xFF181A20),
              tileBackgroundColor: const Color(0xFF262A34),
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
                color: Colors.white60,
                fontSize: 12,
              ),
              cameraIconBackgroundColor: Colors.orange.withAlpha(50),
              cameraIconColor: Colors.orangeAccent,
              galleryIconBackgroundColor: Colors.teal.withAlpha(50),
              galleryIconColor: Colors.tealAccent,
              urlIconBackgroundColor: Colors.purple.withAlpha(50),
              urlIconColor: Colors.purpleAccent,
              dragHandleColor: Colors.white24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              tileBorderRadius: BorderRadius.circular(18),
            ),
          ),
          cropOptions: CropOptions(
            title: 'Branded Cropper',
            toolbarColor: const Color(0xFF181A20),
            backgroundColor: const Color(0xFF101216),
            activeHandleColor: Colors.orangeAccent,
            gridColor: Colors.orangeAccent.withAlpha(80),
          ),
          compressionOptions: const CompressionOptions(
            maxBytes: 300 * 1024,
            format: OutputFormat.webp,
          ),
        );
        if (file != null && mounted) {
          widget.onMediaAdded(file);
          _showToast('Picked with Custom Theme: ${file.name}');
        }
      },
    );
  }

  Widget _buildRecipeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
