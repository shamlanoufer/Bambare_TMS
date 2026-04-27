import 'dart:typed_data';

import 'local_file_saver_stub.dart'
    if (dart.library.io) 'local_file_saver_io.dart' as impl;

Future<String?> saveToAppDocuments({
  required Uint8List bytes,
  required String filenameWithExt,
}) =>
    impl.saveToAppDocuments(
      bytes: bytes,
      filenameWithExt: filenameWithExt,
    );

