import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/adaptive_file.dart';
import '../models/crop_options.dart';
import '../models/compression_options.dart';
import '../processing/image_cropper_engine.dart';

/// An interactive, gesture-driven Flutter crop view with live grid overlay,
/// aspect ratio presets, rotation, flipping, and circular mask preview.
class AdaptiveCropView extends StatefulWidget {
  /// The input file to be cropped and transformed.
  final AdaptiveFile file;

  /// Crop configuration and visual theme options.
  final CropOptions options;

  /// Compression options to apply to cropped result, if any.
  final CompressionOptions? compressionOptions;

  /// Creates an [AdaptiveCropView] widget for interactive image cropping.
  const AdaptiveCropView({
    super.key,
    required this.file,
    this.options = const CropOptions(),
    this.compressionOptions,
  });

  /// Opens the [AdaptiveCropView] full-screen modal route.
  static Future<AdaptiveFile?> show(
    BuildContext context, {
    required AdaptiveFile file,
    CropOptions? options,
    CompressionOptions? compressionOptions,
  }) {
    return Navigator.of(context).push<AdaptiveFile>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => AdaptiveCropView(
          file: file,
          options: options ?? const CropOptions(),
          compressionOptions: compressionOptions,
        ),
      ),
    );
  }

  @override
  State<AdaptiveCropView> createState() => _AdaptiveCropViewState();
}

class _AdaptiveCropViewState extends State<AdaptiveCropView> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  // Transform states
  int _rotation = 0; // 0, 90, 180, 270
  bool _flipHorizontal = false;
  bool _flipVertical = false;
  late CropShape _cropShape;
  late CropAspectRatio _selectedRatio;

  // Normalized crop rectangle: 0.0 to 1.0 relative to layout box
  Rect _cropRectNormalized = const Rect.fromLTWH(0.05, 0.05, 0.90, 0.90);

  // Active handle drag touch tracking
  _CropHandle? _activeHandle;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _rotation = widget.options.initialRotation;
    _cropShape = widget.options.shape;
    _selectedRatio = widget.options.aspectRatio ??
        (widget.options.availableAspectRatios.isNotEmpty
            ? widget.options.availableAspectRatios.first
            : CropAspectRatio.original);

    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      final bytes = await widget.file.readAsBytes();
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load image: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _resetTransformations() {
    setState(() {
      _rotation = widget.options.initialRotation;
      _flipHorizontal = false;
      _flipVertical = false;
      _cropShape = widget.options.shape;
      _selectedRatio = widget.options.aspectRatio ?? CropAspectRatio.original;
      _cropRectNormalized = const Rect.fromLTWH(0.05, 0.05, 0.90, 0.90);
    });
  }

  void _rotateClockwise() {
    setState(() {
      _rotation = (_rotation + 90) % 360;
    });
  }

  void _toggleFlipHorizontal() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
  }

  void _toggleFlipVertical() {
    setState(() {
      _flipVertical = !_flipVertical;
    });
  }

  void _onSelectAspectRatio(CropAspectRatio ratio) {
    setState(() {
      _selectedRatio = ratio;
      _adjustCropRectForRatio(ratio);
    });
  }

  void _adjustCropRectForRatio(CropAspectRatio ratio) {
    final double? targetRatio = ratio.ratio;
    if (targetRatio == null) return; // Freeform / Original

    // Keep center of current rect
    final center = _cropRectNormalized.center;
    double currentW = _cropRectNormalized.width;
    double currentH = _cropRectNormalized.height;

    if (currentW / currentH > targetRatio) {
      currentW = currentH * targetRatio;
    } else {
      currentH = currentW / targetRatio;
    }

    // Clamp inside [0, 1]
    currentW = currentW.clamp(0.1, 0.95);
    currentH = currentH.clamp(0.1, 0.95);

    double left = (center.dx - currentW / 2).clamp(0.0, 1.0 - currentW);
    double top = (center.dy - currentH / 2).clamp(0.0, 1.0 - currentH);

    _cropRectNormalized = Rect.fromLTWH(left, top, currentW, currentH);
  }

  Future<void> _applyCrop() async {
    if (_imageBytes == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final croppedBytes = await ImageCropperEngine.crop(
        bytes: _imageBytes!,
        cropRectNormalized: _cropRectNormalized,
        rotation: _rotation,
        flipHorizontal: _flipHorizontal,
        flipVertical: _flipVertical,
        shape: _cropShape,
        format: widget.compressionOptions?.format ?? OutputFormat.preserve,
        quality: widget.compressionOptions?.quality ?? 90,
      );

      final ext = _cropShape == CropShape.circle
          ? 'png'
          : (widget.file.extension.isNotEmpty ? widget.file.extension : 'jpg');
      final newName = '${widget.file.nameWithoutExtension}_cropped.$ext';

      final resultFile = AdaptiveFile.fromBytes(
        croppedBytes,
        name: newName,
        mimeType: _cropShape == CropShape.circle ? 'image/png' : widget.file.mimeType,
      );

      if (mounted) {
        Navigator.of(context).pop(resultFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cropping failed: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = widget.options.backgroundColor ??
        (isDark ? const Color(0xFF121212) : const Color(0xFF1E1E1E));
    final activeColor = widget.options.activeHandleColor ?? theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.options.toolbarColor ?? backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          tooltip: widget.options.cancelButtonText,
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          widget.options.title ?? 'Crop & Edit',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (widget.options.showReset)
            TextButton(
              onPressed: _isProcessing ? null : _resetTransformations,
              child: Text(
                widget.options.resetButtonText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isProcessing
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : TextButton(
                    onPressed: _applyCrop,
                    child: Text(
                      widget.options.doneButtonText,
                      style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : Column(
                  children: [
                    // Main interactive crop area
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildCropArea(constraints, activeColor);
                        },
                      ),
                    ),

                    // Aspect ratio selector chips
                    if (widget.options.showAspectRatios &&
                        widget.options.availableAspectRatios.isNotEmpty &&
                        !widget.options.lockAspectRatio)
                      _buildAspectRatioBar(activeColor),

                    // Transformation toolbar (rotate, flip, shape)
                    _buildTransformBar(activeColor),
                  ],
                ),
    );
  }

  Widget _buildCropArea(BoxConstraints constraints, Color activeColor) {
    final areaWidth = constraints.maxWidth;
    final areaHeight = constraints.maxHeight;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Rotated & Flipped Image Preview
        Center(
          child: Transform.rotate(
            angle: _rotation * math.pi / 180,
            child: Transform.scale(
              scaleX: _flipHorizontal ? -1.0 : 1.0,
              scaleY: _flipVertical ? -1.0 : 1.0,
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Interactive Crop Frame & Overlay Painter
        Positioned.fill(
          child: GestureDetector(
            onPanStart: (details) => _onPanStart(details, areaWidth, areaHeight),
            onPanUpdate: (details) => _onPanUpdate(details, areaWidth, areaHeight),
            onPanEnd: (_) => _onPanEnd(),
            child: CustomPaint(
              painter: _CropOverlayPainter(
                cropRectNormalized: _cropRectNormalized,
                shape: _cropShape,
                showGrid: widget.options.showGrid,
                gridColor: widget.options.gridColor ?? Colors.white.withAlpha(80),
                overlayColor: widget.options.overlayColor ?? Colors.black.withAlpha(160),
                cropFrameColor: widget.options.cropFrameColor ?? Colors.white,
                activeHandleColor: activeColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAspectRatioBar(Color activeColor) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.black.withAlpha(80),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.options.availableAspectRatios.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final ratio = widget.options.availableAspectRatios[index];
          final isSelected = _selectedRatio == ratio;

          return Center(
            child: ChoiceChip(
              label: Text(
                ratio.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: activeColor,
              backgroundColor: Colors.white10,
              onSelected: (_) => _onSelectAspectRatio(ratio),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransformBar(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black.withAlpha(120),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.options.showRotate && widget.options.allowRotation)
              IconButton(
                icon: const Icon(Icons.rotate_90_degrees_cw, color: Colors.white),
                tooltip: 'Rotate 90°',
                onPressed: _rotateClockwise,
              ),
            if (widget.options.showFlip && widget.options.allowFlipping) ...[
              IconButton(
                icon: const Icon(Icons.flip, color: Colors.white),
                tooltip: 'Flip Horizontal',
                onPressed: _toggleFlipHorizontal,
              ),
              IconButton(
                icon: Transform.rotate(
                  angle: math.pi / 2,
                  child: const Icon(Icons.flip, color: Colors.white),
                ),
                tooltip: 'Flip Vertical',
                onPressed: _toggleFlipVertical,
              ),
            ],
            // Shape Switch (Rect <-> Circle)
            if (!widget.options.lockAspectRatio)
              IconButton(
                icon: Icon(
                  _cropShape == CropShape.circle ? Icons.crop_square : Icons.circle_outlined,
                  color: Colors.white,
                ),
                tooltip: _cropShape == CropShape.circle ? 'Switch to Rectangle' : 'Switch to Circle',
                onPressed: () {
                  setState(() {
                    _cropShape = _cropShape == CropShape.circle ? CropShape.rectangle : CropShape.circle;
                    if (_cropShape == CropShape.circle) {
                      _selectedRatio = CropAspectRatio.square;
                      _adjustCropRectForRatio(CropAspectRatio.square);
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details, double areaWidth, double areaHeight) {
    final local = details.localPosition;
    final normX = local.dx / areaWidth;
    final normY = local.dy / areaHeight;
    _lastPanPosition = local;

    // Detect which handle was touched (tolerance ~ 30px)
    final tolX = 30.0 / areaWidth;
    final tolY = 30.0 / areaHeight;
    final r = _cropRectNormalized;

    if ((normX - r.left).abs() < tolX && (normY - r.top).abs() < tolY) {
      _activeHandle = _CropHandle.topLeft;
    } else if ((normX - r.right).abs() < tolX && (normY - r.top).abs() < tolY) {
      _activeHandle = _CropHandle.topRight;
    } else if ((normX - r.left).abs() < tolX && (normY - r.bottom).abs() < tolY) {
      _activeHandle = _CropHandle.bottomLeft;
    } else if ((normX - r.right).abs() < tolX && (normY - r.bottom).abs() < tolY) {
      _activeHandle = _CropHandle.bottomRight;
    } else if (r.contains(Offset(normX, normY))) {
      _activeHandle = _CropHandle.inside;
    } else {
      _activeHandle = null;
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double areaWidth, double areaHeight) {
    if (_activeHandle == null || _lastPanPosition == null) return;

    final dx = (details.localPosition.dx - _lastPanPosition!.dx) / areaWidth;
    final dy = (details.localPosition.dy - _lastPanPosition!.dy) / areaHeight;
    _lastPanPosition = details.localPosition;

    setState(() {
      var r = _cropRectNormalized;
      final double minSize = 0.1;

      switch (_activeHandle!) {
        case _CropHandle.inside:
          final newLeft = (r.left + dx).clamp(0.0, 1.0 - r.width);
          final newTop = (r.top + dy).clamp(0.0, 1.0 - r.height);
          _cropRectNormalized = Rect.fromLTWH(newLeft, newTop, r.width, r.height);
          break;
        case _CropHandle.topLeft:
          final newLeft = (r.left + dx).clamp(0.0, r.right - minSize);
          final newTop = (r.top + dy).clamp(0.0, r.bottom - minSize);
          _cropRectNormalized = Rect.fromLTRB(newLeft, newTop, r.right, r.bottom);
          break;
        case _CropHandle.topRight:
          final newRight = (r.right + dx).clamp(r.left + minSize, 1.0);
          final newTop = (r.top + dy).clamp(0.0, r.bottom - minSize);
          _cropRectNormalized = Rect.fromLTRB(r.left, newTop, newRight, r.bottom);
          break;
        case _CropHandle.bottomLeft:
          final newLeft = (r.left + dx).clamp(0.0, r.right - minSize);
          final newBottom = (r.bottom + dy).clamp(r.top + minSize, 1.0);
          _cropRectNormalized = Rect.fromLTRB(newLeft, r.top, r.right, newBottom);
          break;
        case _CropHandle.bottomRight:
          final newRight = (r.right + dx).clamp(r.left + minSize, 1.0);
          final newBottom = (r.bottom + dy).clamp(r.top + minSize, 1.0);
          _cropRectNormalized = Rect.fromLTRB(r.left, r.top, newRight, newBottom);
          break;
      }

      if (_cropShape == CropShape.circle || (_selectedRatio.ratio != null && widget.options.lockAspectRatio)) {
        _adjustCropRectForRatio(_selectedRatio);
      }
    });
  }

  void _onPanEnd() {
    _activeHandle = null;
    _lastPanPosition = null;
  }
}

enum _CropHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  inside,
}

/// Custom painter for dimmed exterior overlay, 3x3 grid, and corner handles.
class _CropOverlayPainter extends CustomPainter {
  final Rect cropRectNormalized;
  final CropShape shape;
  final bool showGrid;
  final Color gridColor;
  final Color overlayColor;
  final Color cropFrameColor;
  final Color activeHandleColor;

  _CropOverlayPainter({
    required this.cropRectNormalized,
    required this.shape,
    required this.showGrid,
    required this.gridColor,
    required this.overlayColor,
    required this.cropFrameColor,
    required this.activeHandleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixelRect = Rect.fromLTWH(
      cropRectNormalized.left * size.width,
      cropRectNormalized.top * size.height,
      cropRectNormalized.width * size.width,
      cropRectNormalized.height * size.height,
    );

    // 1. Draw exterior dimmed overlay with cutout
    final overlayPaint = Paint()..color = overlayColor;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    if (shape == CropShape.circle) {
      path.addOval(pixelRect);
    } else {
      path.addRect(pixelRect);
    }
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    // 2. Draw border frame
    final framePaint = Paint()
      ..color = cropFrameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (shape == CropShape.circle) {
      canvas.drawOval(pixelRect, framePaint);
    } else {
      canvas.drawRect(pixelRect, framePaint);
    }

    // 3. Draw Rule-of-Thirds Grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final stepX = pixelRect.width / 3;
      final stepY = pixelRect.height / 3;

      // Vertical lines
      canvas.drawLine(
        Offset(pixelRect.left + stepX, pixelRect.top),
        Offset(pixelRect.left + stepX, pixelRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(pixelRect.left + stepX * 2, pixelRect.top),
        Offset(pixelRect.left + stepX * 2, pixelRect.bottom),
        gridPaint,
      );

      // Horizontal lines
      canvas.drawLine(
        Offset(pixelRect.left, pixelRect.top + stepY),
        Offset(pixelRect.right, pixelRect.top + stepY),
        gridPaint,
      );
      canvas.drawLine(
        Offset(pixelRect.left, pixelRect.top + stepY * 2),
        Offset(pixelRect.right, pixelRect.top + stepY * 2),
        gridPaint,
      );
    }

    // 4. Draw Corner Handles
    final handlePaint = Paint()
      ..color = activeHandleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const handleLength = 18.0;

    // Top-Left
    canvas.drawLine(pixelRect.topLeft, pixelRect.topLeft + const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(pixelRect.topLeft, pixelRect.topLeft + const Offset(0, handleLength), handlePaint);

    // Top-Right
    canvas.drawLine(pixelRect.topRight, pixelRect.topRight - const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(pixelRect.topRight, pixelRect.topRight + const Offset(0, handleLength), handlePaint);

    // Bottom-Left
    canvas.drawLine(pixelRect.bottomLeft, pixelRect.bottomLeft + const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(pixelRect.bottomLeft, pixelRect.bottomLeft - const Offset(0, handleLength), handlePaint);

    // Bottom-Right
    canvas.drawLine(pixelRect.bottomRight, pixelRect.bottomRight - const Offset(handleLength, 0), handlePaint);
    canvas.drawLine(pixelRect.bottomRight, pixelRect.bottomRight - const Offset(0, handleLength), handlePaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRectNormalized != cropRectNormalized ||
        oldDelegate.shape != shape ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.activeHandleColor != activeHandleColor;
  }
}
