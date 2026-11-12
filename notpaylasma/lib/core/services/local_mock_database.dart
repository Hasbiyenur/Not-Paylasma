import 'package:sembast/sembast.dart';

import '../utils/app_exception.dart';

/// Metadata atomik kaydedilir. Revision başka sekmenin kaydını ezmeyi engeller.
class LocalMockDatabase {
  LocalMockDatabase(this.database);
  final Database database;
  static final metadata = stringMapStoreFactory.store('metadata');
  int _revision = 0;

  Future<Map<String, dynamic>?> load() async {
    final record = await metadata.record('state').get(database);
    if (record == null) {
      if (await metadata.record('initialized').exists(database)) {
        throw const AppException(
          'Yerel ana kayıt eksik. Mevcut dosyalar korunuyor.',
        );
      }
      return null;
    }
    if (record['revision'] is! int || record['state'] is! Map) {
      throw const AppException(
        'Yerel kayıt okunamadı. Veriler korunuyor; kayıt dosyasını kontrol edin.',
      );
    }
    _revision = record['revision'] as int;
    return Map<String, dynamic>.from(record['state'] as Map);
  }

  Future<void> save(Map<String, dynamic> state) async {
    try {
      await database.transaction((txn) async {
        final record = await metadata.record('state').get(txn);
        if ((record?['revision'] ?? 0) != _revision) {
          throw const AppException(
            'Veriler başka bir pencerede değişti. Uygulamayı yenileyin.',
          );
        }
        await metadata.record('state').put(txn, {
          'revision': _revision + 1,
          'state': state,
        });
        await metadata.record('initialized').put(txn, {'schemaVersion': 1});
      });
      _revision++;
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(
        'Yerel kayıt yazılamadı. Depolama alanını kontrol edip yeniden deneyin.',
      );
    }
  }
}
