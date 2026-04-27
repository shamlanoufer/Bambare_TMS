import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';

import 'local_file_saver.dart' as local;

/// IO platforms:
/// - Android: always save into real user-visible Downloads via MediaStore.
/// - Others: try FileSaver first, then fall back to app documents.
Future<String?> savePdfBytes({
  required Uint8List bytes,
  required String baseName,
}) async {
  if (Platform.isAndroid) {
    return local.saveToAppDocuments(
      bytes: bytes,
      filenameWithExt: '$baseName.pdf',
    );
  }

  try {
    final path = await FileSaver.instance.saveFile(
      name: baseName,
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
    if (path.toString().trim().isNotEmpty) return path;
  } catch (_) {
    // Fall back below.
  }

  return local.saveToAppDocuments(
    bytes: bytes,
    filenameWithExt: '$baseName.pdf',
  );
}

