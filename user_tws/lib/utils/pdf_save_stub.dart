import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';

/// Web: save via browser download.
Future<String?> savePdfBytes({
  required Uint8List bytes,
  required String baseName,
}) async {
  final path = await FileSaver.instance.saveFile(
    name: baseName,
    bytes: bytes,
    ext: 'pdf',
    mimeType: MimeType.pdf,
  );
  return path.toString().trim().isEmpty ? null : path;
}

