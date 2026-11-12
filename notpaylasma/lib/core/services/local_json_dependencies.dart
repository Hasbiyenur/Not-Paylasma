import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, debugPrintStack, kDebugMode;

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';
import '../../repositories/local/local_json_store.dart';
import '../../repositories/local/local_auth_repository.dart';
import '../../repositories/local/local_note_repository.dart';
import '../../repositories/local/local_favorite_repository.dart';
import '../../repositories/local/local_category_repository.dart';
import '../../repositories/auth_repository.dart';
import 'app_dependencies.dart';
import 'device_file_service.dart';
import 'json_data_service.dart';
import 'json_file_system.dart';
import 'json_file_system_factory.dart';
import 'legacy_json_import.dart';

Future<AppDependencies> createLocalJsonDependencies({
  JsonFileSystem? fileSystem,
  DeviceFileService? device,
  bool migrateLegacy = true,
  bool externalUsers = false,
  Future<AuthRepository> Function(LocalJsonStore, JsonFileSystem)? authFactory,
  Future<void> Function()? closeAuth,
  Future<void> Function(String, String)? migrateLocalAccount,
}) async {
  final fs = fileSystem ?? await openJsonFileSystem();
  final data = JsonDataService(fs);
  final files = JsonAttachmentStorage(fs);
  final store = LocalJsonStore(externalUsers: externalUsers);
  var stage = 'Başlangıç JSON dosyası';
  try {
    final initial = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/data/initial_data.json'))
          as Map,
    );
    stage = 'Yerel JSON kaydı';
    var saved = await data.load();
    if (saved == null) {
      stage = 'Eski kayıtların aktarılması';
      saved = migrateLegacy ? await importLegacyJson(fs, files) : null;
      if (saved == null) {
        stage = 'Başlangıç ek dosyaları';
        saved = initial;
        for (final note in initial['notes'] as List) {
          final bytes = await rootBundle.load(
            'assets/data/files/ornek.${note['fileType']}',
          );
          await files.put(
            note['storagePath'] as String,
            SelectedFile(
              note['fileName'] as String,
              bytes.buffer.asUint8List(
                bytes.offsetInBytes,
                bytes.lengthInBytes,
              ),
            ),
          );
        }
      }
      saved['categories'] ??= initial['categories'];
      stage = 'JSON verilerinin doğrulanması';
      store.restore(saved);
      stage = 'JSON kaydının yazılması';
      if (!externalUsers) await data.save(store.toJson());
    } else {
      store.restore(saved);
    }
    if (externalUsers) {
      if (saved['schemaVersion'] == 1) {
        // Önceki hesaplar açık kullanıcı eylemiyle Firebase'e aktarılabilir.
        // Aktarım tamamlanmadan eski parolaların özetleri yok edilmez.
        if (await fs.read('legacy-accounts.json') == null) {
          await fs.write(
            'legacy-accounts.json',
            utf8.encode(jsonEncode(saved)),
          );
        }
      }
      store.currentUid = null;
      store.users.clear();
      store.credentials.clear();
      await data.save(store.toJson());
    }
    store.persist = data.save;
    final auth = authFactory == null
        ? LocalAuthRepository(store)
        : await authFactory(store, fs);
    return AppDependencies(
      auth: auth,
      notes: LocalNoteRepository(store, files),
      favorites: LocalFavoriteRepository(store),
      categories: LocalCategoryRepository(store),
      files: files,
      device: device ?? PlatformDeviceFileService(),
      isPersistent: true,
      isLocalJson: true,
      isFirebase: externalUsers,
      isHybrid: externalUsers,
      migrateLocalAccount: migrateLocalAccount,
      dataLocation: fs.location,
      exportJson: () async {
        await store.settled;
        // Parola özetleri yedeğe eklenmez; dosya kişisel hesap bilgilerini içerir.
        final json = store.toJson()..remove('credentials');
        return SelectedFile(
          'notpaylas-veriler.json',
          Uint8List.fromList(
            utf8.encode(const JsonEncoder.withIndent('  ').convert(json)),
          ),
        );
      },
      initialTheme: store.theme,
      saveTheme: (theme) => store.write(() => store.theme = theme),
      onClose: () async {
        await closeAuth?.call();
        await store.settled;
        store.close();
      },
    );
  } catch (error, stackTrace) {
    store.close();
    if (kDebugMode) {
      debugPrint('Yerel JSON başlangıcı ($stage): $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    if (error is AppException) rethrow;
    throw AppException(
      '$stage tamamlanamadı. Mevcut kayıtlar korunuyor. '
      'Uygulamayı tamamen kapatıp yeniden çalıştırın.',
    );
  }
}
