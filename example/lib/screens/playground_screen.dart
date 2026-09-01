import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_image_picker/adaptive_image_picker.dart';
import '../widgets/comparison_card.dart';

class PlaygroundScreen extends StatefulWidget {
  final Function(AdaptiveFile) onMediaAdded;

  const PlaygroundScreen({super.key, required this.onMediaAdded});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  // Source config
  ImageSource _selectedSource = ImageSource.gallery;

  // Cropping config
  bool _enableCropping = true;
  CropShape _cropShape = CropShape.rectangle;
  CropAspectRatio _aspectRatioPreset = CropAspectRatio.free;
  bool _showGrid = true;
  bool _allowRotation = true;
  bool _allowFlipping = true;
  bool _lockAspectRatio = false;

  // Compression config
  bool _enableCompression = true;
  double _targetSizeKb = 250;
  OutputFormat _outputFormat = OutputFormat.webp;
  final int _maxWidth = 1920;
  final int _maxHeight = 1080;

  // Result state
  bool _isProcessing = false;
  AdaptiveFile? _rawPickedFile;
  AdaptiveFile? _processedFile;

  Future<void> _runPipeline() async {
    setState(() {
      _isProcessing = true;
      _rawPickedFile = null;
      _processedFile = null;
    });

    try {
      AdaptiveFile? initialFile;

      if (_selectedSource == ImageSource.gallery) {
        final list = await AdaptiveImagePicker.pickMultiple(maxCount: 1);
        if (list.isNotEmpty) initialFile = list.first;
      } else if (_selectedSource == ImageSource.camera) {
        initialFile = await AdaptiveImagePicker.pickImage(source: ImageSource.camera);
      } else if (_selectedSource == ImageSource.url) {
        if (mounted) {
          final url = await MediaBottomSheet.showUrlInputDialog(context);
          if (url != null && url.isNotEmpty) {
            initialFile = await AdaptiveImagePicker.fromUrl(url);
          }
        }
      }

      if (initialFile == null) return;
      _rawPickedFile = initialFile;

      var currentFile = initialFile;

      // 1. Crop Step if enabled
      if (_enableCropping && mounted) {
        final cropped = await AdaptiveImagePicker.cropImage(
          file: currentFile,
          context: context,
          options: CropOptions(
            title: 'Interactive Studio Cropper',
            shape: _cropShape,
            aspectRatioPreset: _aspectRatioPreset,
            showGrid: _showGrid,
            allowRotation: _allowRotation,
            allowFlipping: _allowFlipping,
            lockAspectRatio: _lockAspectRatio,
          ),
        );
        if (cropped == null) return; // User cancelled cropping
        currentFile = cropped;
      }

      // 2. Compress Step if enabled
      if (_enableCompression) {
        currentFile = await AdaptiveImagePicker.compressImage(
          file: currentFile,
          options: CompressionOptions(
            maxBytes: (_targetSizeKb * 1024).round(),
            format: _outputFormat,
            maxWidth: _maxWidth > 0 ? _maxWidth : null,
            maxHeight: _maxHeight > 0 ? _maxHeight : null,
          ),
        );
      }

      setState(() {
        _processedFile = currentFile;
      });

      widget.onMediaAdded(currentFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processing failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveResultToDisk() async {
    if (_processedFile == null) return;
    if (kIsWeb) {
      await _processedFile!.saveToBrowser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to browser: ${_processedFile!.name}'),
            backgroundColor: Colors.teal.shade700,
          ),
        );
      }
      return;
    }
    final tempDir = Directory.systemTemp;
    final saved = await _processedFile!.saveToDirectory(tempDir.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to: ${saved.path}'),
          backgroundColor: Colors.teal.shade700,
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
        // Section: Studio Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.tertiaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: theme.colorScheme.onPrimaryContainer, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Live Pipeline Studio',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Customize inputs, test zero-permission channels, interactive cropping handles, and binary search quality compression in real-time.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Section 1: Media Source Selection
        _buildSectionHeader('1. Media Source', Icons.cloud_download_outlined, theme),
        const SizedBox(height: 8),
        SegmentedButton<ImageSource>(
          segments: const [
            ButtonSegment(
              value: ImageSource.gallery,
              label: Text('Gallery'),
              icon: Icon(Icons.photo_library_outlined),
            ),
            ButtonSegment(
              value: ImageSource.camera,
              label: Text('Camera'),
              icon: Icon(Icons.camera_alt_outlined),
            ),
            ButtonSegment(
              value: ImageSource.url,
              label: Text('Web URL'),
              icon: Icon(Icons.link_rounded),
            ),
          ],
          selected: {_selectedSource},
          onSelectionChanged: (set) => setState(() => _selectedSource = set.first),
        ),

        const SizedBox(height: 20),

        // Section 2: Pure-Dart Interactive Cropper
        _buildSectionHeader('2. Cropper & Transform Options', Icons.crop_rotate_rounded, theme),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Interactive Cropping', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Pure-Dart pinch-zoom, pan, grid, and touch handles'),
                  value: _enableCropping,
                  onChanged: (val) => setState(() => _enableCropping = val),
                ),
                if (_enableCropping) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Crop Mask Shape', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  SegmentedButton<CropShape>(
                    segments: const [
                      ButtonSegment(value: CropShape.rectangle, label: Text('Rectangle / Box'), icon: Icon(Icons.crop_square)),
                      ButtonSegment(value: CropShape.circle, label: Text('Circular Avatar'), icon: Icon(Icons.account_circle_outlined)),
                    ],
                    selected: {_cropShape},
                    onSelectionChanged: (set) => setState(() => _cropShape = set.first),
                  ),
                  const SizedBox(height: 14),
                  const Text('Initial Aspect Ratio Preset', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRatioChip(CropAspectRatio.free, 'Freeform'),
                      _buildRatioChip(CropAspectRatio.ratio1x1, '1:1 Square'),
                      _buildRatioChip(CropAspectRatio.ratio16x9, '16:9 Landscape'),
                      _buildRatioChip(CropAspectRatio.ratio4x3, '4:3 Standard'),
                      _buildRatioChip(CropAspectRatio.ratio9x16, '9:16 Story'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    children: [
                      _buildCheckbox('Show Grid', _showGrid, (v) => setState(() => _showGrid = v!)),
                      _buildCheckbox('Rotation', _allowRotation, (v) => setState(() => _allowRotation = v!)),
                      _buildCheckbox('Flipping', _allowFlipping, (v) => setState(() => _allowFlipping = v!)),
                      _buildCheckbox('Lock Ratio', _lockAspectRatio, (v) => setState(() => _lockAspectRatio = v!)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Section 3: Smart Target-Size Compressor
        _buildSectionHeader('3. Target-Size Compressor (Binary Search)', Icons.compress_rounded, theme),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Target-Size Compression', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Guarantees output size strictly under specified threshold'),
                  value: _enableCompression,
                  onChanged: (val) => setState(() => _enableCompression = val),
                ),
                if (_enableCompression) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Strict Max File Size Target:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        '${_targetSizeKb.round()} KB',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 15),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetSizeKb,
                    min: 50,
                    max: 1500,
                    divisions: 29,
                    label: '${_targetSizeKb.round()} KB',
                    onChanged: (val) => setState(() => _targetSizeKb = val),
                  ),
                  const SizedBox(height: 8),
                  const Text('Output Image Format', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<OutputFormat>(
                    initialValue: _outputFormat,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: OutputFormat.webp, child: Text('WebP (Recommended - Ultra Efficient)')),
                      DropdownMenuItem(value: OutputFormat.jpeg, child: Text('JPEG (Universal Compatibility)')),
                      DropdownMenuItem(value: OutputFormat.png, child: Text('PNG (Lossless / Transparent)')),
                      DropdownMenuItem(value: OutputFormat.preserve, child: Text('Preserve Source Format')),
                    ],
                    onChanged: (fmt) => setState(() => _outputFormat = fmt!),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action: Run Pipeline
        FilledButton.icon(
          onPressed: _isProcessing ? null : _runPipeline,
          icon: _isProcessing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.play_arrow_rounded, size: 24),
          label: Text(
            _isProcessing ? 'Executing Pipeline...' : 'Run Pipeline (Pick & Process)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        const SizedBox(height: 24),

        // Section 4: Live Comparison Results
        if (_rawPickedFile != null && _processedFile != null) ...[
          _buildSectionHeader('Pipeline Results & Comparison', Icons.analytics_outlined, theme),
          const SizedBox(height: 8),
          ComparisonCard(
            original: _rawPickedFile!,
            processed: _processedFile!,
            onSave: _saveResultToDisk,
            onReCrop: () async {
              final cropped = await AdaptiveImagePicker.cropImage(
                file: _processedFile!,
                context: context,
              );
              if (cropped != null && mounted) {
                setState(() => _processedFile = cropped);
                widget.onMediaAdded(cropped);
              }
            },
            onReCompress: () async {
              final compressed = await AdaptiveImagePicker.compressImage(
                file: _processedFile!,
                options: CompressionOptions.targetSize(100 * 1024),
              );
              if (mounted) {
                setState(() => _processedFile = compressed);
                widget.onMediaAdded(compressed);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRatioChip(CropAspectRatio ratio, String label) {
    final isSelected = _aspectRatioPreset == ratio;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _aspectRatioPreset = ratio);
      },
    );
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
