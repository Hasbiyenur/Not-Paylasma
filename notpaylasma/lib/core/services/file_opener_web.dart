import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';
import 'file_export_web.dart';
import 'web_file_bytes.dart';

Future<void> openDocument(SelectedFile file) async {
  if (file.extension == 'docx') {
    downloadToDevice(file);
    return;
  }
  final blob = web.Blob(
    [toWebFileBytes(file.bytes)].toJS,
    web.BlobPropertyBag(type: file.mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final opened = web.window.open('about:blank', '_blank');
  if (opened == null) {
    web.URL.revokeObjectURL(url);
    throw const AppException(
      'Tarayıcı yeni pencereyi engelledi. İndir seçeneğini kullanın.',
    );
  }
  opened.location.href = url;
  Future<void>.delayed(
    const Duration(minutes: 2),
    () => web.URL.revokeObjectURL(url),
  );
}
