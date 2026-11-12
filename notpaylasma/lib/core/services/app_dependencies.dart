import 'package:flutter/services.dart';

import '../../models/note_model.dart';
import '../../models/user_model.dart';
import '../../models/selected_file.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/note_repository.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/favorite_repository.dart';
import '../../repositories/mock/mock_store.dart';
import '../../repositories/mock/mock_auth_repository.dart';
import '../../repositories/mock/mock_note_repository.dart';
import '../../repositories/mock/mock_category_repository.dart';
import '../../repositories/mock/mock_favorite_repository.dart';
import 'device_file_service.dart';
import 'file_storage_service.dart';
import 'local_database_factory.dart';
import 'local_mock_database.dart';
import 'persistent_file_storage_service.dart';

class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.notes,
    required this.favorites,
    required this.categories,
    required this.files,
    required this.device,
    this.onDispose,
    this.onClose,
    this.isPersistent = false,
    this.isFirebase = false,
    this.isLocalJson = false,
    this.isHybrid = false,
    this.migrateLocalAccount,
    this.dataLocation,
    this.exportJson,
    this.initialTheme = 'system',
    this.saveTheme,
  });
  final AuthRepository auth;
  final NoteRepository notes;
  final FavoriteRepository favorites;
  final CategoryRepository categories;
  final FileStorageService files;
  final DeviceFileService device;
  final void Function()? onDispose;
  final Future<void> Function()? onClose;
  final bool isPersistent;
  final bool isFirebase;
  final bool isLocalJson;
  final bool isHybrid;
  final Future<void> Function(String email, String password)?
  migrateLocalAccount;
  final String? dataLocation;
  final Future<SelectedFile> Function()? exportJson;
  final String initialTheme;
  final Future<void> Function(String)? saveTheme;

  Future<void> close() async {
    if (onClose != null) {
      await onClose!();
    } else {
      onDispose?.call();
    }
  }

  static Future<AppDependencies> mock({
    DeviceFileService? device,
    bool persistent = false,
    LocalMockDatabase? persistence,
    FileStorageService? fileStorage,
  }) async {
    final local =
        persistence ??
        (persistent ? LocalMockDatabase(await openLocalDatabase()) : null);
    final store = MockStore();
    final auth = MockAuthRepository(store);
    final files =
        fileStorage ??
        (local == null
            ? MemoryFileStorageService()
            : PersistentFileStorageService(local.database));
    try {
      final saved = await local?.load();
      if (saved != null) {
        store.restore(saved);
      } else {
        final now = DateTime.now().toUtc();
        for (final entry in [
          ('demo-ayse', 'Ayşe', 'Yılmaz', 'ayse@example.com'),
          ('demo-mehmet', 'Mehmet', 'Demir', 'mehmet@example.com'),
        ]) {
          store.users[entry.$1] = UserModel(
            uid: entry.$1,
            firstName: entry.$2,
            lastName: entry.$3,
            email: entry.$4,
            createdAt: now,
            updatedAt: now,
          );
          auth.setPassword(entry.$1, MockAuthRepository.demoPassword);
        }
        final samples = <String, SelectedFile>{};
        for (final ext in ['pdf', 'docx', 'png']) {
          final data = await rootBundle.load('assets/mock/files/ornek.$ext');
          samples[ext] = SelectedFile(
            'ornek.$ext',
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        }
        const subjects = [
          ('Dart ve koleksiyonlar', 'Mobil Programlama', 'yazilim', 'dart'),
          ('Türev çalışma notları', 'Matematik I', 'matematik', 'türev'),
          ('Hareket ve kuvvet', 'Fizik I', 'fizik', 'mekanik'),
          ('İngilizce zamanlar', 'İngilizce', 'dil', 'gramer'),
        ];
        for (var i = 0; i < 26; i++) {
          final subject = subjects[i % subjects.length];
          final ext = i == 1
              ? 'docx'
              : i == 2
              ? 'png'
              : 'pdf';
          final file = samples[ext]!;
          final id = 'demo-note-${i.toString().padLeft(3, '0')}';
          final user = store.users[i.isEven ? 'demo-ayse' : 'demo-mehmet']!;
          final path = 'notes/${user.uid}/$id/ornek.$ext';
          await files.put(path, file);
          store.notes[id] = NoteModel(
            id: id,
            title: '${subject.$1} • ${i + 1}',
            description: 'Arama ve paylaşım akışlarını denemek için örnek kayıt. Ek dosya, NotPaylaş demo çalışma sayfasıdır; dersin tam içeriği değildir.',
            courseName: subject.$2,
            categoryId: subject.$3,
            university: 'Örnek Eğitim Kurumu',
            tags: [subject.$4, 'örnek'],
            userId: user.uid,
            userName: user.fullName,
            fileName: file.name,
            storagePath: path,
            fileType: ext,
            fileSize: file.size,
            downloadCount: 0,
            createdAt: now.subtract(Duration(hours: i)),
            updatedAt: now,
          );
        }
        if (local != null) await local.save(store.toJson());
      }
      store.persist = local?.save;
      if (files is PersistentFileStorageService) {
        // Temizlik hatası okunabilir kullanıcı verisinin açılmasını engellemez.
        try {
          await files.collectOrphans(store.referencedFiles);
        } catch (_) {}
      }
      return AppDependencies(
        auth: auth,
        notes: MockNoteRepository(store, files),
        favorites: MockFavoriteRepository(store),
        categories: MockCategoryRepository(store),
        files: files,
        device: device ?? PlatformDeviceFileService(),
        onDispose: store.close,
        onClose: () async {
          await store.settled;
          store.close();
          await local?.database.close();
        },
        isPersistent: local != null,
        initialTheme: store.theme,
        saveTheme: (value) async {
          await store.write(() => store.theme = value);
        },
      );
    } catch (_) {
      store.close();
      await local?.database.close();
      rethrow;
    }
  }
}
