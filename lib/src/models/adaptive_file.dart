import 'dart:io' as io;
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Represents a cross-platform media file with rich metadata,
/// lazy byte loading, format conversion, and disk/memory helpers.
class AdaptiveFile {
  /// The local filesystem path of the file, or null if in-memory/web.
  final String? path;

  /// The name of the file including extension (e.g. "photo.jpg").
  final String name;

  /// In-memory byte buffer (optional / cached).
  final Uint8List? bytes;

  /// MIME type string (e.g. "image/jpeg", "image/png", "image/webp").
  final String? mimeType;

  /// Width of the image in pixels, if known.
  final int? width;

  /// Height of the image in pixels, if known.
  final int? height;

  /// Size of the file in bytes, if known.
  final int? size;

  /// Last modified timestamp, if known.
  final DateTime? lastModified;

  /// Creates a new [AdaptiveFile] instance.
  const AdaptiveFile({
    this.path,
    required this.name,
    this.bytes,
    this.mimeType,
    this.width,
    this.height,
    this.size,
    this.lastModified,
  });

  /// Creates an [AdaptiveFile] from raw in-memory bytes.
  factory AdaptiveFile.fromBytes(
    Uint8List bytes, {
    required String name,
    String? mimeType,
    int? width,
    int? height,
    int? size,
    DateTime? lastModified,
  }) {
    final inferredMime = mimeType ?? _inferMimeType(name);
    return AdaptiveFile(
      path: null,
      name: name,
      bytes: bytes,
      mimeType: inferredMime,
      width: width,
      height: height,
      size: size ?? bytes.lengthInBytes,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  /// Creates an [AdaptiveFile] from a local file path.
  factory AdaptiveFile.fromPath(
    String path, {
    String? name,
    String? mimeType,
    int? width,
    int? height,
    int? size,
    Uint8List? bytes,
    DateTime? lastModified,
  }) {
    final fileName = name ?? _extractFileName(path);
    final inferredMime = mimeType ?? _inferMimeType(fileName);
    return AdaptiveFile(
      path: path,
      name: fileName,
      bytes: bytes,
      mimeType: inferredMime,
      width: width,
      height: height,
      size: size,
      lastModified: lastModified,
    );
  }

  /// Creates an [AdaptiveFile] from a Map (e.g. from MethodChannel).
  factory AdaptiveFile.fromMap(Map<dynamic, dynamic> map) {
    final path = map['path'] as String?;
    final name = map['name'] as String? ?? (path != null ? _extractFileName(path) : 'file');
    final bytesList = map['bytes'];
    final Uint8List? bytes = bytesList is Uint8List
        ? bytesList
        : (bytesList is List<int> ? Uint8List.fromList(bytesList) : null);

    return AdaptiveFile(
      path: path,
      name: name,
      bytes: bytes,
      mimeType: map['mimeType'] as String? ?? _inferMimeType(name),
      width: map['width'] as int?,
      height: map['height'] as int?,
      size: map['size'] as int? ?? bytes?.lengthInBytes,
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
    );
  }

  /// Serializes to a Map representation.
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'mimeType': mimeType,
      'width': width,
      'height': height,
      'size': size ?? bytes?.lengthInBytes,
      'lastModified': lastModified?.millisecondsSinceEpoch,
    };
  }

  /// Whether the file is backed by a local filesystem path.
  bool get hasPath => path != null && path!.isNotEmpty;

  /// Whether bytes are already loaded in memory.
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  /// Reads and returns the raw file bytes.
  /// If bytes are already cached in memory, returns them immediately.
  /// Otherwise, reads from the local filesystem path on IO platforms.
  Future<Uint8List> readAsBytes() async {
    if (bytes != null && bytes!.isNotEmpty) {
      return bytes!;
    }
    if (!kIsWeb && path != null && path!.isNotEmpty) {
      final file = io.File(path!);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    throw StateError('Cannot read bytes for AdaptiveFile: no in-memory bytes and path is unavailable or does not exist ($path).');
  }

  /// Synchronously reads the file bytes if in-memory, or from filesystem on IO.
  Uint8List? readAsBytesSync() {
    if (bytes != null && bytes!.isNotEmpty) {
      return bytes!;
    }
    if (!kIsWeb && path != null && path!.isNotEmpty) {
      final file = io.File(path!);
      if (file.existsSync()) {
        return file.readAsBytesSync();
      }
    }
    return null;
  }

  /// Saves the file bytes to a local destination file path.
  /// Returns a new [AdaptiveFile] pointing to the saved destination.
  Future<AdaptiveFile> saveTo(String destinationPath) async {
    if (kIsWeb) {
      throw UnsupportedError('saveTo() filesystem is not supported on web platform.');
    }
    final rawBytes = await readAsBytes();
    final file = io.File(destinationPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(rawBytes);

    return copyWith(
      path: destinationPath,
      name: _extractFileName(destinationPath),
      size: rawBytes.lengthInBytes,
    );
  }

  /// Saves the file into a directory folder using its current [name].
  /// Returns a new [AdaptiveFile] pointing to the saved file in [directoryPath].
  Future<AdaptiveFile> saveToDirectory(String directoryPath) {
    final separator = directoryPath.endsWith('/') || directoryPath.endsWith('\\') ? '' : '/';
    return saveTo('$directoryPath$separator$name');
  }

  /// Copies the file to a new path.
  Future<AdaptiveFile> copy(String newPath) => saveTo(newPath);

  /// Deletes the file if it exists on disk.
  Future<bool> delete() async {
    if (!kIsWeb && path != null && path!.isNotEmpty) {
      final file = io.File(path!);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    }
    return false;
  }

  /// Returns the file extension in lowercase with leading dot (e.g. ".jpg").
  String get extensionWithDot {
    final idx = name.lastIndexOf('.');
    if (idx < 0) return '';
    return name.substring(idx).toLowerCase();
  }

  /// Returns the file extension in lowercase without leading dot (e.g. "jpg").
  String get extension {
    final ext = extensionWithDot;
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  /// Returns the file name without extension.
  String get nameWithoutExtension {
    final idx = name.lastIndexOf('.');
    if (idx < 0) return name;
    return name.substring(0, idx);
  }

  /// Returns the aspect ratio (width / height) if dimensions are known.
  double? get aspectRatio {
    if (width != null && height != null && height! > 0) {
      return width! / height!;
    }
    return null;
  }

  /// Returns a human-readable formatted file size string (e.g. "1.4 MB", "340 KB").
  String get formattedSize {
    final numBytes = size ?? bytes?.lengthInBytes;
    if (numBytes == null || numBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(numBytes) / log(1024)).floor();
    final clampedI = i.clamp(0, suffixes.length - 1);
    final value = numBytes / pow(1024, clampedI);
    return '${value.toStringAsFixed(value < 10 && clampedI > 0 ? 1 : 0)} ${suffixes[clampedI]}';
  }

  /// Returns a copy of this file with modified attributes.
  AdaptiveFile copyWith({
    String? path,
    String? name,
    Uint8List? bytes,
    String? mimeType,
    int? width,
    int? height,
    int? size,
    DateTime? lastModified,
  }) {
    return AdaptiveFile(
      path: path ?? this.path,
      name: name ?? this.name,
      bytes: bytes ?? this.bytes,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  static String _extractFileName(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx >= 0 ? normalized.substring(idx + 1) : normalized;
  }

  static String _inferMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  String toString() {
    return 'AdaptiveFile(name: $name, size: $formattedSize, dimensions: ${width}x$height, mime: $mimeType, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdaptiveFile &&
        other.path == path &&
        other.name == name &&
        other.size == size &&
        other.width == width &&
        other.height == height &&
        other.mimeType == mimeType;
  }

  @override
  int get hashCode => Object.hash(path, name, size, width, height, mimeType);
}
