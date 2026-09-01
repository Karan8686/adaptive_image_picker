import 'dart:typed_data';

/// Reads file bytes from disk (stub for non-IO / web platforms).
Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('Filesystem operations are not supported on this platform.');
}

/// Reads file bytes synchronously (stub for non-IO / web platforms).
Uint8List? readFileBytesSync(String path) {
  return null;
}

/// Writes file bytes to disk (stub for non-IO / web platforms).
Future<void> saveFileBytes(String destinationPath, Uint8List bytes) {
  throw UnsupportedError('Filesystem operations are not supported on this platform.');
}

/// Deletes file from disk (stub for non-IO / web platforms).
Future<bool> deleteFilePath(String path) {
  return Future.value(false);
}

/// Triggers a browser file download saving the file to the user's local Downloads folder (stub).
Future<void> downloadFileToBrowser(Uint8List bytes, String fileName, {String? mimeType}) {
  throw UnsupportedError('Browser download is only supported on web.');
}
