import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/services/app_dependencies.dart';
import 'package:notpaylas/core/services/json_data_service.dart';
import 'package:notpaylas/core/services/json_file_system_io.dart';
import 'package:notpaylas/core/services/legacy_json_import.dart';
import 'package:notpaylas/core/services/local_json_dependencies.dart';
import 'package:notpaylas/core/services/local_mock_database.dart';
import 'package:notpaylas/core/services/persistent_file_storage_service.dart';
import 'package:notpaylas/core/utils/app_exception.dart';
import 'package:notpaylas/models/note_model.dart';
import 'package:notpaylas/models/selected_file.dart';
import 'package:sembast/sembast_io.dart';

const draft = NoteDraft(
  title: 'JSON kalıcı not',
  description: 'JSON dosyasında saklanan ders notu.',
  courseName: 'Dart',
  categoryId: 'yazilim',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DiskJsonFileSystem fs;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('json-storage-');
    fs = DiskJsonFileSystem(directory);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'JSON kayıt ve gerçek ek dosyası çıkış/giriş ve yeniden açılışta korunur',
    () async {
      var deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      expect(deps.isLocalJson, isTrue);
      final count =
          (await deps.auth
                  .signIn('ayse@example.com', 'NotPaylas123!')
                  .then((_) => deps.notes.query(const NoteQuery(limit: 100))))
              .items
              .length;
      final bytes = await rootBundle.load('assets/data/files/ornek.pdf');
      final file = SelectedFile(
        'kalici.pdf',
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final created = await deps.notes.save(draft, file: file);
      await deps.favorites.setFavorite(created.id, true);
      await deps.auth.updateProfile('Yeni', 'Soyad');
      await deps.saveTheme!('dark');
      await deps.auth.signOut();
      final raw = jsonDecode(
        await File('${directory.path}/data.json').readAsString(),
      ) as Map;
      expect((raw['data'] as Map)['currentUid'], isNull);
      expect((raw['data'] as Map)['notes'], hasLength(count + 1));
      expect(
        await File('${directory.path}/files/${created.storagePath}')
            .readAsBytes(),
        file.bytes,
      );
      expect(await File('${directory.path}/data.backup.json').exists(), isTrue);
      await deps.close();
      deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
      expect(deps.auth.currentUser!.firstName, 'Yeni');
      expect(deps.initialTheme, 'dark');
      expect(await deps.notes.getById(created.id), isNotNull);
      expect((await deps.files.read(created.storagePath)).bytes, file.bytes);
      expect(await deps.favorites.getForCurrentUser(), contains(created.id));
      final exported =
          jsonDecode(utf8.decode((await deps.exportJson!()).bytes)) as Map;
      expect(exported.containsKey('credentials'), isFalse);
      await deps.close();
    },
  );
  test(
    'Yeni kullanıcı, dosya değiştirme ve silme tekrar açıldığında korunur',
    () async {
      var deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      await deps.auth.register(
        'Yerel',
        'Kullanıcı',
        'yerel@example.com',
        'GucluSifre123!',
      );
      final bytes = await rootBundle.load('assets/data/files/ornek.pdf');
      final file = SelectedFile(
        'ders.pdf',
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final note = await deps.notes.save(draft, file: file);
      final updated = await deps.notes.save(
        draft,
        id: note.id,
        file: SelectedFile('yeni.pdf', file.bytes),
      );
      expect(await fs.read('files/${note.storagePath}'), isNull);
      await deps.close();
      deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      expect(deps.auth.currentUser!.email, 'yerel@example.com');
      expect((await deps.files.read(updated.storagePath)).name, 'yeni.pdf');
      await deps.notes.delete(note.id);
      expect(await fs.read('files/${updated.storagePath}'), isNull);
      await deps.close();
      deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      expect(await deps.notes.getById(note.id), isNull);
      await deps.close();
    },
  );
  test(
    'Eski kayıtlar ve ekleri JSON’a kayıpsız aktarılır; kaynak silinmez',
    () async {
      final legacyPath = '${directory.path}/legacy.db';
      var database = await databaseFactoryIo.openDatabase(legacyPath);
      final old = await AppDependencies.mock(
        persistence: LocalMockDatabase(database),
        fileStorage: PersistentFileStorageService(database),
      );
      await old.auth.register(
        'Önceki',
        'Hesap',
        'onceki@example.com',
        'OncekiSifre123!',
      );
      final currentUid = old.auth.currentUser!.uid;
      await old.close();
      database = await databaseFactoryIo.openDatabase(legacyPath);
      final files = JsonAttachmentStorage(fs);
      final imported = (await importLegacyJson(
        fs,
        files,
        sourceDatabase: database,
      ))!;
      final initial = jsonDecode(
        await rootBundle.loadString('assets/data/initial_data.json'),
      ) as Map;
      imported['categories'] = initial['categories'];
      await JsonDataService(fs).save(imported);
      final deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      expect(deps.auth.currentUser!.uid, currentUid);
      expect(
        (await deps.notes.query(const NoteQuery(limit: 100))).items,
        hasLength(26),
      );
      expect(await File(legacyPath).exists(), isTrue);
      expect(await fs.read('legacy-import.json'), isNotNull);
      await deps.close();
    },
  );
  test('Başka pencerenin kaydı ve bozuk JSON sessizce ezilmez', () async {
    final first = JsonDataService(fs);
    final second = JsonDataService(fs);
    await first.save({'value': 1});
    await second.load();
    await first.save({'value': 2});
    await expectLater(second.save({'value': 3}), throwsA(isA<AppException>()));
    expect((await JsonDataService(fs).load())!['value'], 2);
    await fs.write('data.json', Uint8List.fromList(utf8.encode('{bozuk')));
    await expectLater(
      createLocalJsonDependencies(fileSystem: fs, migrateLegacy: false),
      throwsA(isA<AppException>()),
    );
    expect(utf8.decode((await fs.read('data.json'))!), '{bozuk');
  });
}
