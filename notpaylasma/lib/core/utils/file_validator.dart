import 'dart:convert';

import 'package:archive/archive.dart';

import '../../models/selected_file.dart';
import 'app_exception.dart';

abstract final class FileValidator {
  static void validate(SelectedFile file, {bool avatar = false}) {
    if (file.size == 0 || file.size > (avatar ? 5 : 20) * 1024 * 1024) {
      throw AppException(
        'Dosya boş olamaz ve ${avatar ? 5 : 20} MiB sınırını aşamaz.',
      );
    }
    final bytes = file.bytes;
    bool starts(List<int> prefix) =>
        bytes.length >= prefix.length &&
        List.generate(
          prefix.length,
          (i) => bytes[i] == prefix[i],
        ).every((v) => v);
    var valid = false;
    switch (file.extension) {
      case 'pdf':
        valid =
            !avatar &&
            starts(ascii.encode('%PDF-')) &&
            latin1
                .decode(
                  bytes.sublist(
                    (bytes.length - 2048).clamp(0, bytes.length),
                    bytes.length,
                  ),
                )
                .contains('%%EOF');
      case 'png':
        valid = starts([137, 80, 78, 71, 13, 10, 26, 10]);
      case 'jpg':
      case 'jpeg':
        valid = starts([255, 216, 255]);
      case 'docx':
        if (!avatar) {
          try {
            final zip = ZipDecoder().decodeBytes(bytes, verify: true);
            valid =
                zip.length < 2000 &&
                zip.fold<int>(0, (s, f) => s + f.size) <= 100 * 1024 * 1024 &&
                zip.findFile('[Content_Types].xml') != null &&
                zip.findFile('word/document.xml') != null;
          } catch (_) {
            valid = false;
          }
        }
    }
    if (!valid) {
      throw const AppException(
        'Dosya türü veya içeriği geçersiz. PDF, DOCX veya görsel seçin.',
      );
    }
  }
}
