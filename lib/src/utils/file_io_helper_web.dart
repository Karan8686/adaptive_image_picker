import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Reads file bytes from disk (stub for non-IO / web platforms).
Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('Filesystem operations are not supported on web.');
}

/// Reads file bytes synchronously (stub for non-IO / web platforms).
Uint8List? readFileBytesSync(String path) {
  return null;
}

/// Writes file bytes to disk (stub for non-IO / web platforms).
Future<void> saveFileBytes(String destinationPath, Uint8List bytes) {
  throw UnsupportedError('Filesystem operations are not supported on web.');
}

/// Deletes file from disk (stub for non-IO / web platforms).
Future<bool> deleteFilePath(String path) {
  return Future.value(false);
}

/// Triggers a browser file download saving the file to the user's local Downloads folder.
Future<void> downloadFileToBrowser(Uint8List bytes, String fileName, {String? mimeType}) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
