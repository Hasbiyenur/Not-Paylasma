import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/services/app_dependencies.dart';
import 'package:notpaylas/core/services/local_mock_database.dart';
import 'package:notpaylas/core/services/persistent_file_storage_service.dart';
import 'package:notpaylas/core/utils/app_exception.dart';
import 'package:notpaylas/models/note_model.dart';
import 'package:notpaylas/models/selected_file.dart';
import 'package:notpaylas/providers/auth_provider.dart';
import 'package:notpaylas/providers/theme_provider.dart';
import 'package:notpaylas/repositories/mock/mock_note_repository.dart';
import 'package:sembast/sembast_io.dart';

class FailingMetadata extends LocalMockDatabase {
  FailingMetadata(super.database);
  bool fail = false;
  @override
  Future<void> save(Map<String, dynamic> state) async {
    if (fail) throw const AppException('Test yazma hatası');
    await super.save(state);
  }
}

class FailingDeleteFiles extends PersistentFileStorageService {
  FailingDeleteFiles(super.database);
  bool failDelete = false;
  @override
  Future<void> delete(String key) async {
    if (failDelete) throw const AppException('Test silme hatası');
    await super.delete(key);
  }
}

const draft = NoteDraft(
  title: 'Kalıcı ders notu',
  description: 'Yeniden açılış için hazırlanmış çalışma.',
  courseName: 'Mobil Programlama',
  categoryId: 'yazilim',
  tags: ['kalıcı'],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late String path;
  late SelectedFile pdf;
  late AppDependencies deps;
  late FailingMetadata local;

  Future<void> open() async {
    final database = await databaseFactoryIo.openDatabase(path);
    local = FailingMetadata(database);
    deps = await AppDependencies.mock(persistence: local);
  }

  Future<void> reopen() async {
    await deps.close();
    await open();
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('notpaylas_persistence_');
    path = '${directory.path}/mock.db';
    final bytes = await rootBundle.load('assets/mock/files/ornek.pdf');
    pdf = SelectedFile('kalici.pdf', bytes.buffer.asUint8List());
    await open();
    await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
  });
  tearDown(() async {
    await deps.close();
    await directory.delete(recursive: true);
  });

  test('Gerçek disk: hesap, oturum, not, dosya, favori, profil ve tema tekrar açılır', () async {
    await deps.auth.register(
      'Kalıcı',
      'Öğrenci',
      'kalici@example.com',
      'Demo12345!',
    );
    final uid = deps.auth.currentUser!.uid;
    final note = await deps.notes.save(draft, file: pdf);
    await deps.favorites.setFavorite(note.id, true);
    await deps.notes.recordDownload(note.id);
    final image = await rootBundle.load('assets/mock/files/ornek.png');
    final provider = AuthProvider(deps.auth, deps.files);
    await provider.updateProfile(
      'Yeni',
      'Öğrenci',
      SelectedFile('avatar.png', image.buffer.asUint8List()),
    );
    provider.dispose();
    final photoPath = deps.auth.currentUser!.photoUrl!;
    await deps.saveTheme!('dark');
    await reopen();
    expect(deps.auth.currentUser!.uid, uid);
    expect(deps.auth.currentUser!.firstName, 'Yeni');
    expect(deps.initialTheme, 'dark');
    expect(await deps.favorites.getForCurrentUser(), contains(note.id));
    expect((await deps.notes.getById(note.id))!.downloadCount, 1);
    expect((await deps.notes.getById(note.id))!.userName, 'Yeni Öğrenci');
    expect((await deps.files.read(note.storagePath)).bytes, pdf.bytes);
    expect(
      (await deps.files.read(photoPath)).bytes,
      image.buffer.asUint8List(),
    );
    await deps.auth.signOut();
    await reopen();
    expect(deps.auth.currentUser, isNull);
    await deps.auth.signIn('kalici@example.com', 'Demo12345!');
    expect(deps.auth.currentUser!.uid, uid);
  });

  test('Düzenleme, yeni dosya ve silme yeniden açılışta korunur', () async {
    final note = await deps.notes.save(draft, file: pdf);
    await deps.favorites.setFavorite(note.id, true);
    final updated = await deps.notes.save(
      draft,
      id: note.id,
      file: SelectedFile('yeni.pdf', pdf.bytes),
    );
    await reopen();
    expect((await deps.notes.getById(note.id))!.fileName, 'yeni.pdf');
    await expectLater(
      deps.files.read(note.storagePath),
      throwsA(isA<AppException>()),
    );
    await deps.notes.delete(note.id);
    await reopen();
    expect(await deps.notes.getById(note.id), isNull);
    expect(await deps.favorites.getForCurrentUser(), isNot(contains(note.id)));
    await expectLater(
      deps.files.read(updated.storagePath),
      throwsA(isA<AppException>()),
    );
  });

  test(
    'Şifre değişimi kalıcı, sıfırlama kodu yeniden açılışta geçersiz',
    () async {
      final request = await deps.auth.requestPasswordReset('ayse@example.com');
      await deps.auth.confirmPasswordReset(
        request.id,
        request.demoCode!,
        'Yeni12345!',
      );
      final unused = await deps.auth.requestPasswordReset('ayse@example.com');
      await reopen();
      expect(deps.auth.currentUser, isNull);
      await expectLater(
        deps.auth.signIn('ayse@example.com', 'NotPaylas123!'),
        throwsA(isA<AppException>()),
      );
      await deps.auth.signIn('ayse@example.com', 'Yeni12345!');
      await expectLater(
        deps.auth.confirmPasswordReset(
          unused.id,
          unused.demoCode!,
          'Demo12345!',
        ),
        throwsA(isA<AppException>()),
      );
    },
  );

  test('Metadata yazma hatası notu/favoriyi/oturumu değiştirmez ve yeni eki temizler', () async {
    final count = await PersistentFileStorageService.records.count(
      local.database,
    );
    local.fail = true;
    await expectLater(
      deps.notes.save(draft, file: pdf),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      deps.favorites.setFavorite('demo-note-000', true),
      throwsA(isA<AppException>()),
    );
    await expectLater(deps.auth.signOut(), throwsA(isA<AppException>()));
    expect(deps.auth.currentUser!.uid, 'demo-ayse');
    expect(await deps.favorites.getForCurrentUser(), isEmpty);
    expect(
      (await deps.notes.query(const NoteQuery(limit: 100))).items.length,
      26,
    );
    expect(
      await PersistentFileStorageService.records.count(local.database),
      count,
    );
    local.fail = false;
    await reopen();
    expect(deps.auth.currentUser!.uid, 'demo-ayse');
    expect(await deps.favorites.getForCurrentUser(), isEmpty);
  });

  test('Başarısız silme veya düzenleme eski dosyayı ve notu korur', () async {
    final note = (await deps.notes.getById('demo-note-000'))!;
    local.fail = true;
    await expectLater(deps.notes.delete(note.id), throwsA(isA<AppException>()));
    await expectLater(
      deps.notes.save(draft, id: note.id, file: pdf),
      throwsA(isA<AppException>()),
    );
    expect((await deps.notes.getById(note.id))!.storagePath, note.storagePath);
    expect((await deps.files.read(note.storagePath)).size, note.fileSize);
    local.fail = false;
  });

  test(
    'Bozuk şema sessizce sıfırlanmaz ve mevcut kayıt değiştirilmez',
    () async {
      final metadata = LocalMockDatabase.metadata;
      final original = (await metadata.record('state').get(local.database))!;
      final damaged = {
        ...original,
        'state': {'schemaVersion': 999},
      };
      await metadata.record('state').put(local.database, damaged);
      await deps.close();
      final database = await databaseFactoryIo.openDatabase(path);
      await expectLater(
        AppDependencies.mock(persistence: LocalMockDatabase(database)),
        throwsA(isA<AppException>()),
      );
      final reopened = await databaseFactoryIo.openDatabase(path);
      expect(await metadata.record('state').get(reopened), damaged);
      await metadata.record('state').put(reopened, original);
      await reopened.close();
      await open();
    },
  );

  test('Eksik ana kayıt dosyaları örnek verilerle ezmez', () async {
    final metadata = LocalMockDatabase.metadata;
    final original = (await metadata.record('state').get(local.database))!;
    await metadata.record('state').delete(local.database);
    await expectLater(local.load(), throwsA(isA<AppException>()));
    await metadata.record('state').put(local.database, original);
  });

  test('Eksik ve değiştirilmiş dosya okunurken açık hata verir', () async {
    final note = (await deps.notes.getById('demo-note-000'))!;
    final record = PersistentFileStorageService.records.record(
      note.storagePath,
    );
    await record.update(local.database, {'sha256': 'yanlis'});
    await expectLater(
      deps.files.read(note.storagePath),
      throwsA(isA<AppException>()),
    );
    await record.delete(local.database);
    await expectLater(
      deps.files.read(note.storagePath),
      throwsA(isA<AppException>()),
    );
    expect(await deps.notes.getById(note.id), isNotNull);
  });

  test('Silme temizliği başarısızsa not silinir ve eski sahipsiz ek tekrar toplanır', () async {
    final files = FailingDeleteFiles(local.database);
    final store = (deps.notes as MockNoteRepository).store;
    final repo = MockNoteRepository(store, files);
    final note = (await repo.getById('demo-note-000'))!;
    files.failDelete = true;
    await repo.delete(note.id);
    expect(await repo.getById(note.id), isNull);
    expect((await files.read(note.storagePath)).size, note.fileSize);
    await files.collectOrphans(
      store.referencedFiles,
      now: DateTime.now().toUtc().add(const Duration(days: 2)),
    );
    await expectLater(
      files.read(note.storagePath),
      throwsA(isA<AppException>()),
    );
    expect(
      (await files.read('notes/demo-mehmet/demo-note-001/ornek.docx')).size,
      greaterThan(0),
    );
  });

  test('Yeni yarım yükleme hemen silinmez; eskisi temizlenir', () async {
    final files = deps.files as PersistentFileStorageService;
    final store = (deps.notes as MockNoteRepository).store;
    await files.put('yarim-upload', pdf);
    await files.collectOrphans(store.referencedFiles);
    expect((await files.read('yarim-upload')).size, pdf.size);
    await files.collectOrphans(
      store.referencedFiles,
      now: DateTime.now().toUtc().add(const Duration(days: 2)),
    );
    await expectLater(files.read('yarim-upload'), throwsA(isA<AppException>()));
  });

  test('Toplam kota aşılırsa ek yazılmaz; var olan dosyalar korunur', () async {
    final files = PersistentFileStorageService(
      local.database,
      maxTotalBytes: 1,
    );
    final count = await PersistentFileStorageService.records.count(
      local.database,
    );
    await expectLater(files.put('quota', pdf), throwsA(isA<AppException>()));
    expect(
      await PersistentFileStorageService.records.count(local.database),
      count,
    );
  });

  test('Eşzamanlı favori ve sayaç işlemlerinde artış kaybolmaz', () async {
    await Future.wait(
      List.generate(20, (_) => deps.notes.recordDownload('demo-note-000')),
    );
    await Future.wait(
      List.generate(
        10,
        (_) => deps.favorites.setFavorite('demo-note-000', true),
      ),
    );
    await reopen();
    final note = (await deps.notes.getById('demo-note-000'))!;
    expect(note.downloadCount, 20);
    expect(note.favoriteCount, 1);
  });

  test(
    'Başka pencerenin metadata revision değişimi eski kaydı engeller',
    () async {
      final other = LocalMockDatabase(local.database);
      final stale = (await other.load())!;
      await deps.saveTheme!('dark');
      await expectLater(other.save(stale), throwsA(isA<AppException>()));
      await reopen();
      expect(deps.initialTheme, 'dark');
    },
  );

  test(
    'Tema yazma hatasında eski seçim korunur ve meşgul durum temizlenir',
    () async {
      final theme = ThemeProvider(
        save: (_) async => throw const AppException('Yazma hatası'),
      );
      await expectLater(
        theme.setMode(ThemeMode.dark),
        throwsA(isA<AppException>()),
      );
      expect(theme.mode, ThemeMode.system);
      expect(theme.busy, isFalse);
      theme.dispose();
    },
  );

  test('Aynı sıfırlama kodu eşzamanlı iki kez kullanılamaz', () async {
    final request = await deps.auth.requestPasswordReset('ayse@example.com');
    final first = deps.auth.confirmPasswordReset(
      request.id,
      request.demoCode!,
      'Yeni12345!',
    );
    await expectLater(
      deps.auth.confirmPasswordReset(
        request.id,
        request.demoCode!,
        'Baska12345!',
      ),
      throwsA(isA<AppException>()),
    );
    await first;
    await reopen();
    await deps.auth.signIn('ayse@example.com', 'Yeni12345!');
  });

  test('Hatalı veri ilişkisi açılışta reddedilir ve diskte korunur', () async {
    final metadata = LocalMockDatabase.metadata;
    final original = (await metadata.record('state').get(local.database))!;
    final state = Map<String, dynamic>.from(original['state'] as Map);
    state['currentUid'] = 'olmayan-kullanici';
    await metadata.record('state').put(local.database, {
      ...original,
      'state': state,
    });
    await deps.close();
    final db = await databaseFactoryIo.openDatabase(path);
    await expectLater(
      AppDependencies.mock(persistence: LocalMockDatabase(db)),
      throwsA(isA<AppException>()),
    );
    final recovered = await databaseFactoryIo.openDatabase(path);
    final persisted = (await metadata.record('state').get(recovered))!;
    expect((persisted['state'] as Map)['currentUid'], 'olmayan-kullanici');
    await metadata.record('state').put(recovered, original);
    await recovered.close();
    await open();
  });

  test('3000 notun sayfaları tekrarsız ve eksiksiz döner', () async {
    // Performans ölçümü değildir; büyük veri davranışı ve cursor doğruluğudur.
    final memory = await AppDependencies.mock();
    await memory.auth.signIn('ayse@example.com', 'NotPaylas123!');
    final store = (memory.notes as MockNoteRepository).store;
    final original = store.notes.values.first;
    store.notes.clear();
    for (var i = 0; i < 3000; i++) {
      final id = 'large-${i.toString().padLeft(5, '0')}';
      store.notes[id] = original.changed({'id': id});
    }
    final ids = <String>{};
    String? cursor;
    do {
      final page = await memory.notes.query(
        NoteQuery(limit: 100, cursor: cursor),
      );
      for (final note in page.items) {
        expect(ids.add(note.id), isTrue);
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    expect(ids.length, 3000);
    await memory.close();
  });
}
