import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';
import 'file_storage_service.dart';
import 'json_file_system.dart';

class JsonDataService {
  JsonDataService(this.fs);
  final JsonFileSystem fs;
  int _revision = 0;
  Future<Map<String, dynamic>?> load() async {
    final bytes = await fs.read('data.json');
    if (bytes == null) return null;
    try {
      final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      _revision = envelope['revision'] as int;
      return Map<String, dynamic>.from(envelope['data'] as Map);
    } catch (_) {
      throw const AppException(
        'JSON kaydı bozuk; dosya korunuyor. JSON yedeğinizi kontrol edin.',
      );
    }
  }

  Future<void> save(Map<String, dynamic> state) async {
    await fs.locked(() async {
      final current = await fs.read('data.json');
      final revision = current == null
          ? 0
          : (jsonDecode(utf8.decode(current)) as Map)['revision'];
      if (revision != _revision) {
        throw const AppException(
          'JSON başka bir pencerede değişti. Sayfayı yenileyin.',
        );
      }
      final bytes = Uint8List.fromList(
        utf8.encode(
          const JsonEncoder.withIndent('  ')
              .convert({'revision': _revision + 1, 'data': state}),
        ),
      );
      if (current != null) await fs.write('data.backup.json', current);
      await fs.write('data.json', bytes);
      _revision++;
    });
  }
}

class JsonAttachmentStorage implements FileStorageService {
  JsonAttachmentStorage(this.fs);
  final JsonFileSystem fs;
  String _path(String key) => 'files/${safeLocalPath(key)}';
  @override
  Future<void> put(
    String key,
    SelectedFile file, {
    void Function(double)? onProgress,
  }) async {
    onProgress?.call(0);
    final path = _path(key);
    await fs.write(path, file.bytes);
    await fs.write(
      '$path.meta.json',
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'name': file.name,
            'size': file.size,
            'sha256': sha256.convert(file.bytes).toString(),
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          }),
        ),
      ),
    );
    onProgress?.call(1);
  }

  @override
  Future<SelectedFile> read(String key) async {
    final path = _path(key);
    final metaBytes = await fs.read('$path.meta.json');
    final bytes = await fs.read(path);
    if (metaBytes == null || bytes == null) {
      throw const AppException(
        'Yerel dosya bulunamadı. Dosyayı yeniden yükleyin.',
      );
    }
    final meta = jsonDecode(utf8.decode(metaBytes)) as Map;
    if (bytes.length != meta['size'] ||
        sha256.convert(bytes).toString() != meta['sha256']) {
      throw const AppException('Yerel dosya hasarlı. Yedeğinizi kontrol edin.');
    }
    return SelectedFile(meta['name'] as String, bytes);
  }

  @override
  Future<void> delete(String key) async {
    await fs.delete(_path(key));
    await fs.delete('${_path(key)}.meta.json');
  }
}
