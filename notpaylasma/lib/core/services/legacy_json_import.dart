import 'dart:convert';

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';
import 'json_data_service.dart';
import 'json_file_system.dart';
import 'local_database_factory.dart';
import 'local_mock_database.dart';
import 'persistent_file_storage_service.dart';

import 'package:sembast/sembast.dart';

/// Eski depo sadece bir kez okunur. Yeni kayıtlar bu depoya yazılmaz.
Future<Map<String, dynamic>?> importLegacyJson(
  JsonFileSystem fs,
  JsonAttachmentStorage files, {
  Database? sourceDatabase,
}) async {
  final database = sourceDatabase ?? await openLocalDatabase();
  try {
    final state = await LocalMockDatabase(database).load();
    if (state == null) return null;
    final oldFiles = PersistentFileStorageService(database);
    final paths = <String>{
      for (final note in state['notes'] as List) note['storagePath'] as String,
      for (final user in state['users'] as List)
        if (user['photoUrl'] != null) user['photoUrl'] as String,
    };
    for (final path in paths) {
      final SelectedFile file = await oldFiles.read(path);
      await files.put(path, file);
    }
    // Kaynak depo ve ayrı JSON yedeği korunur; eksik ek varsa geçiş iptal olur.
    await fs.write('legacy-import.json', utf8.encode(jsonEncode(state)));
    return state;
  } catch (error) {
    throw AppException(
      'Önceki kayıtlar JSON’a aktarılamadı; eski veriler korundu. $error',
    );
  } finally {
    await database.close();
  }
}
