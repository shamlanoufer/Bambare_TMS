import 'dart:io';
import 'dart:typed_data';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> saveToAppDocuments({
  required Uint8List bytes,
  required String filenameWithExt,
}) async {
  if (Platform.isAndroid) {
    // Save into real user-visible Downloads using Android MediaStore.
    final tmpDir = await getTemporaryDirectory();
    final tmpPath = '${tmpDir.path}${Platform.pathSeparator}$filenameWithExt';
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsBytes(bytes, flush: true);

    final ms = MediaStore();
    await ms.saveFile(
      tempFilePath: tmpFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
      relativePath: 'Bambare Travel',
    );

    // MediaStore returns a Uri internally; keep UX simple by returning a Downloads hint.
    return 'Downloads/Bambare Travel/$filenameWithExt';
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$filenameWithExt');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

