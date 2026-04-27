import 'dart:typed_data';

import 'pdf_save_stub.dart' if (dart.library.io) 'pdf_save_io.dart' as impl;

Future<String?> savePdfBytes({
  required Uint8List bytes,
  required String baseName,
}) =>
    impl.savePdfBytes(bytes: bytes, baseName: baseName);

