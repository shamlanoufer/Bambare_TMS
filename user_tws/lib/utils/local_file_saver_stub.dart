import 'dart:typed_data';

/// Web/unsupported fallback: return null (caller can show message).
Future<String?> saveToAppDocuments({
  required Uint8List bytes,
  required String filenameWithExt,
}) async {
  return null;
}

