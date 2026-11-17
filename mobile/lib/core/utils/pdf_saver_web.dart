// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> savePdfFileLocally(Uint8List bytes, String fileName) async {
  final base64Data = base64Encode(bytes);
  final dataUrl = 'data:application/pdf;base64,$base64Data';

  final anchor = html.AnchorElement(href: dataUrl)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  return 'Downloads/$fileName';
}

