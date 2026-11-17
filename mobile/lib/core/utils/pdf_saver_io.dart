import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> savePdfFileLocally(Uint8List bytes, String fileName) async {
  // On Windows/macOS/Linux laptop, save directly into the user's Downloads folder
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    final userProfile =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (userProfile != null && userProfile.isNotEmpty) {
      final downloadsDir = Directory('$userProfile${Platform.pathSeparator}Downloads');
      if (await downloadsDir.exists()) {
        final filePath =
            '${downloadsDir.path}${Platform.pathSeparator}$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        return filePath;
      }
    }
  }

  // Fallback to Downloads / Documents directory via path_provider
  final dir = await getDownloadsDirectory() ??
      await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes, flush: true);
  return filePath;
}

