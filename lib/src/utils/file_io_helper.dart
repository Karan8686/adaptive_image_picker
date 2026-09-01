export 'file_io_helper_stub.dart'
    if (dart.library.io) 'file_io_helper_io.dart'
    if (dart.library.js_interop) 'file_io_helper_web.dart';
