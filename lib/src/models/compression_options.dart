/// Output encoding format for compressed images.
enum OutputFormat {
  /// Keep the original image format (or fallback to JPEG if unsupported).
  preserve,

  /// Encode as JPEG format (.jpg / .jpeg).
  jpeg,

  /// Encode as PNG format (.png, lossless with alpha support).
  png,

  /// Encode as WebP format (.webp, high compression efficiency).
  webp,
}

/// Configuration options for image compression and format optimization.
class CompressionOptions {
  /// Target maximum file size in bytes (e.g., 500 * 1024 for 500 KB).
  ///
  /// When specified, binary search quality adjustment
  /// and progressive downscaling are used to guarantee the output size is strictly
  /// less than or equal to [maxBytes].
  final int? maxBytes;

  /// Compression quality factor from 1 (lowest) to 100 (highest).
  ///
  /// Default is 85.
  final int quality;

  /// Minimum acceptable quality factor when performing binary search compression.
  ///
  /// Default is 10.
  final int minQuality;

  /// Maximum pixel width of the output image.
  /// If specified and the image exceeds this width, it will be proportionally scaled down.
  final int? maxWidth;

  /// Maximum pixel height of the output image.
  /// If specified and the image exceeds this height, it will be proportionally scaled down.
  final int? maxHeight;

  /// Target encoding format.
  ///
  /// Defaults to [OutputFormat.preserve].
  final OutputFormat format;

  /// Whether to automatically bake EXIF orientation into the image pixels.
  ///
  /// Defaults to true.
  final bool autoOrientation;

  /// Whether to preserve EXIF metadata if supported by the encoder.
  final bool keepExif;

  /// Creates a new [CompressionOptions] instance.
  const CompressionOptions({
    this.maxBytes,
    this.quality = 85,
    this.minQuality = 10,
    this.maxWidth,
    this.maxHeight,
    this.format = OutputFormat.preserve,
    this.autoOrientation = true,
    this.keepExif = false,
  }) : assert(quality >= 1 && quality <= 100, 'quality must be between 1 and 100'),
       assert(minQuality >= 1 && minQuality <= quality, 'minQuality must be between 1 and quality');

  /// Profile avatar preset (512x512, max 200 KB, quality 85).
  factory CompressionOptions.avatar({int maxBytes = 200 * 1024}) {
    return CompressionOptions(
      maxWidth: 512,
      maxHeight: 512,
      maxBytes: maxBytes,
      quality: 85,
      format: OutputFormat.jpeg,
    );
  }

  /// Web-optimized preset (max 1920x1080, max 500 KB, WebP format).
  factory CompressionOptions.webOptimized({int maxBytes = 500 * 1024}) {
    return CompressionOptions(
      maxWidth: 1920,
      maxHeight: 1080,
      maxBytes: maxBytes,
      quality: 80,
      format: OutputFormat.webp,
    );
  }

  /// Thumbnail preset (max 256x256, max 50 KB).
  factory CompressionOptions.thumbnail({int maxBytes = 50 * 1024}) {
    return CompressionOptions(
      maxWidth: 256,
      maxHeight: 256,
      maxBytes: maxBytes,
      quality: 75,
      format: OutputFormat.jpeg,
    );
  }

  /// Target size compressor preset with binary search.
  factory CompressionOptions.targetSize(int bytes, {OutputFormat format = OutputFormat.preserve}) {
    return CompressionOptions(
      maxBytes: bytes,
      quality: 85,
      format: format,
    );
  }

  /// Creates a copy of this [CompressionOptions] with specified attributes updated.
  CompressionOptions copyWith({
    int? maxBytes,
    int? quality,
    int? minQuality,
    int? maxWidth,
    int? maxHeight,
    OutputFormat? format,
    bool? autoOrientation,
    bool? keepExif,
  }) {
    return CompressionOptions(
      maxBytes: maxBytes ?? this.maxBytes,
      quality: quality ?? this.quality,
      minQuality: minQuality ?? this.minQuality,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      format: format ?? this.format,
      autoOrientation: autoOrientation ?? this.autoOrientation,
      keepExif: keepExif ?? this.keepExif,
    );
  }
}
