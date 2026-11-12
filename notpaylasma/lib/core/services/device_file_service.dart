import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';
import '../utils/file_validator.dart';
import '../utils/image_file_validator.dart';
import 'file_opener_stub.dart'
    if (dart.library.io) 'file_opener_io.dart'
    if (dart.library.js_interop) 'file_opener_web.dart'
    as opener;
import 'file_export_stub.dart'
    if (dart.library.js_interop) 'file_export_web.dart'
    as exporter;

enum ExportResult { cancelled, saved, started }

abstract class DeviceFileService {
  Future<SelectedFile?> pick({bool avatar = false});
  Future<ExportResult> export(SelectedFile file);
  Future<void> open(SelectedFile file);
}

class PlatformDeviceFileService implements DeviceFileService {
  @override
  Future<SelectedFile?> pick({bool avatar = false}) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: avatar
          ? ['png', 'jpg', 'jpeg']
          : ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (picked == null) return null;
    final size = await picked.length();
    if (size == null || size == 0 || size > (avatar ? 5 : 20) * 1024 * 1024) {
      throw AppException(
        'Dosya okunamıyor, boş veya ${avatar ? 5 : 20} MiB sınırını aşıyor.',
      );
    }
    final file = SelectedFile(picked.name, await picked.readAsBytes());
    if (['png', 'jpg', 'jpeg'].contains(file.extension)) {
      await ImageFileValidator.validate(file, avatar: avatar);
    } else {
      FileValidator.validate(file, avatar: avatar);
    }
    return file;
  }

  @override
  Future<ExportResult> export(SelectedFile file) async {
    if (kIsWeb) {
      exporter.downloadToDevice(file);
      return ExportResult.started;
    }
    final uri = await FilePicker.saveFile(
      fileName: file.name,
      bytes: file.copyBytes(),
      mimeType: file.mimeType,
    );
    // file_picker_web varsayılan download modunda indirmeyi başlatıp null döner.
    // Bu sonuç mobildeki seçici iptali ile aynı anlamda değildir.
    return uri == null ? ExportResult.cancelled : ExportResult.saved;
  }

  @override
  Future<void> open(SelectedFile file) => opener.openDocument(file);
}
