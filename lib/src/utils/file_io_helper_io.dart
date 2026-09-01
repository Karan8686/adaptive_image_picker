import 'dart:io' as io;
import 'dart:typed_data';

/// Reads file bytes from local disk on IO platforms.
Future<Uint8List> readFileBytes(String path) async {
  final file = io.File(path);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  throw StateError('File does not exist: $path');
}

/// Reads file bytes synchronously from local disk on IO platforms.
Uint8List? readFileBytesSync(String path) {
  final file = io.File(path);
  if (file.existsSync()) {
    return file.readAsBytesSync();
  }
  return null;
}

/// Writes file bytes to local disk on IO platforms.
Future<void> saveFileBytes(String destinationPath, Uint8List bytes) async {
  final file = io.File(destinationPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}

/// Deletes file from local disk on IO platforms.
Future<bool> deleteFilePath(String path) async {
  final file = io.File(path);
  if (await file.exists()) {
    await file.delete();
    return true;
  }
  return false;
}

/// Triggers a browser file download (unsupported on native IO).
Future<void> downloadFileToBrowser(Uint8List bytes, String fileName, {String? mimeType}) async {
  throw UnsupportedError('Browser download is only supported on web platforms.');
}
