import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../models/selected_file.dart';
import 'web_file_bytes.dart';

void downloadToDevice(SelectedFile file) {
  final blob = web.Blob(
    [toWebFileBytes(file.bytes)].toJS,
    web.BlobPropertyBag(type: file.mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = file.name
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
    const Duration(minutes: 1),
    () => web.URL.revokeObjectURL(url),
  );
}
