import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sembast/sembast.dart';

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';
import 'file_storage_service.dart';

/// Dosyalar metadata'dan önce yazılır; kesintide kalan ekler güvenle temizlenir.
class PersistentFileStorageService implements FileStorageService {
  PersistentFileStorageService(
    this.database, {
    this.maxTotalBytes = 64 * 1024 * 1024,
  });
  final Database database;
  final int maxTotalBytes;
  static final records = stringMapStoreFactory.store('files');

  @override
  Future<void> put(
    String key,
    SelectedFile file, {
    void Function(double)? onProgress,
  }) async {
    if (file.size == 0 || file.size > 20 * 1024 * 1024) {
      throw const AppException('Dosya boş olamaz ve 20 MiB sınırını aşamaz.');
    }
    onProgress?.call(0);
    // Oturum değişikliği ve arayüz olaylarına fırsat ver.
    await Future<void>.delayed(Duration.zero);
    try {
      final encoded = base64Encode(file.bytes);
      final hash = sha256.convert(file.bytes).toString();
      await database.transaction((txn) async {
        final existing = await records.find(txn);
        final used = existing
            .where((e) => e.key != key)
            .fold<int>(0, (total, e) => total + (e.value['size'] as int));
        if (used + file.size > maxTotalBytes) {
          throw const AppException(
            'Demo dosya alanı doldu (64 MiB). Kullanmadığınız notları silin.',
          );
        }
        await records.record(key).put(txn, {
          'name': file.name,
          'size': file.size,
          'data': encoded,
          'sha256': hash,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
      });
      onProgress?.call(1);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(
        'Dosya saklanamadı. Depolama iznini ve boş alanı kontrol edin.',
      );
    }
  }

  @override
  Future<SelectedFile> read(String key) async {
    final record = await records.record(key).get(database);
    if (record == null) {
      throw const AppException('Dosya bulunamadı. Notu yeniden yükleyin.');
    }
    try {
      final bytes = base64Decode(record['data'] as String);
      if (bytes.length != record['size'] ||
          sha256.convert(bytes).toString() != record['sha256']) {
        throw const FormatException();
      }
      return SelectedFile(record['name'] as String, bytes);
    } catch (_) {
      throw const AppException('Dosya hasarlı. Notu yeniden yükleyin.');
    }
  }

  @override
  Future<void> delete(String key) async {
    await records.record(key).delete(database);
  }

  /// Yeni yükleme yapan başka sekmeye dokunmamak için 24 saat beklenir.
  Future<void> collectOrphans(Set<String> referenced, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now().toUtc()).subtract(
      const Duration(days: 1),
    );
    await database.transaction((txn) async {
      for (final record in await records.find(txn)) {
        final created = DateTime.tryParse(
          record.value['createdAt'] as String? ?? '',
        );
        if (!referenced.contains(record.key) &&
            created != null &&
            created.isBefore(cutoff)) {
          await records.record(record.key).delete(txn);
        }
      }
    });
  }
}
