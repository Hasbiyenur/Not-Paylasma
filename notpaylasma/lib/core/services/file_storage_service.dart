import 'dart:typed_data';

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';

abstract class FileStorageService {
  Future<void> put(
    String key,
    SelectedFile file, {
    void Function(double)? onProgress,
  });
  Future<SelectedFile> read(String key);
  Future<void> delete(String key);
}

/// İzole testler ve bellek modu için oturumluk dosya deposu.
class MemoryFileStorageService implements FileStorageService {
  final Map<String, SelectedFile> _files = {};
  @override
  Future<void> put(
    String key,
    SelectedFile file, {
    void Function(double)? onProgress,
  }) async {
    final copy = Uint8List(file.size);
    for (var offset = 0; offset < file.size; offset += 65536) {
      final end = (offset + 65536).clamp(0, file.size);
      copy.setRange(offset, end, file.bytes, offset);
      onProgress?.call(end / file.size);
      await Future<void>.delayed(Duration.zero);
    }
    _files[key] = SelectedFile(file.name, copy);
  }

  @override
  Future<SelectedFile> read(String key) async =>
      _files[key] ??
      (throw const AppException('Dosya bulunamadı. Notu yeniden yükleyin.'));
  @override
  Future<void> delete(String key) async {
    _files.remove(key);
  }
}
