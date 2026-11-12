import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../core/services/file_storage_service.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/file_validator.dart';
import '../../core/utils/validators.dart';
import '../../models/note_model.dart';
import '../../models/selected_file.dart';
import '../note_repository.dart';
import 'mock_store.dart';

class MockNoteRepository implements NoteRepository {
  MockNoteRepository(this.store, this.files);
  final MockStore store;
  final FileStorageService files;
  final _locks = <String>{};
  @override
  Stream<void> get changes => store.noteEvents.stream;
  @override
  Future<NotePage> query(NoteQuery query) async {
    await store.settled;
    store.requireUser;
    final search = Validators.normalize(query.search);
    final tag = Validators.normalize(query.tag);
    final items = store.notes.values.where((n) {
      final words = Validators.normalize('${n.title} ${n.courseName}')
          .split(RegExp(r'\s+'));
      return (search.isEmpty ||
              search
                  .split(RegExp(r'\s+'))
                  .every(
                    (term) => words.any((word) => word.startsWith(term)),
                  )) &&
          (query.categoryId == null || n.categoryId == query.categoryId) &&
          (query.userId == null || n.userId == query.userId) &&
          (tag.isEmpty || n.tags.contains(tag));
    }).toList();
    items.sort((a, b) {
      final order = switch (query.sort) {
        NoteSort.newest => b.createdAt.compareTo(a.createdAt),
        NoteSort.downloads => b.downloadCount.compareTo(a.downloadCount),
        NoteSort.popular => b.favoriteCount.compareTo(a.favoriteCount),
      };
      return order != 0 ? order : b.id.compareTo(a.id);
    });
    final start = query.cursor == null
        ? 0
        : items.indexWhere((n) => n.id == query.cursor) + 1;
    if (query.cursor != null && start == 0) {
      throw const AppException('Liste değişti. Listeyi yenileyin.');
    }
    final end = min(start + query.limit.clamp(1, 100), items.length);
    final page = items.sublist(start, end);
    return NotePage(
      List.unmodifiable(page),
      end < items.length ? page.last.id : null,
    );
  }

  @override
  Future<NoteModel?> getById(String id) async {
    await store.settled;
    store.requireUser;
    return store.notes[id];
  }

  void _validate(NoteDraft draft) {
    Validators.require(Validators.text(draft.title, 'Başlık', 3, 120));
    Validators.require(
      Validators.text(draft.description, 'Açıklama', 10, 3000),
    );
    Validators.require(Validators.text(draft.courseName, 'Ders', 2, 100));
    Validators.require(Validators.text(draft.university, 'Kurum', 0, 160));
    Validators.tags(draft.tags.join(','));
    if (!store.categories.any((c) => c.id == draft.categoryId)) {
      throw const AppException('Geçerli bir kategori seçin.');
    }
  }

  @override
  Future<NoteModel> save(
    NoteDraft draft, {
    String? id,
    SelectedFile? file,
    void Function(double)? onProgress,
  }) async {
    final user = store.requireUser;
    final revision = store.sessionRevision;
    _validate(draft);
    final old = id == null ? null : store.notes[id];
    if (id != null && old == null) throw const AppException('Not bulunamadı.');
    if (old != null && old.userId != user.uid) {
      throw const AppException('Yalnızca kendi notunuzu düzenleyebilirsiniz.');
    }
    if (old == null && file == null) {
      throw const AppException('Bir dosya seçin.');
    }
    if (file != null) FileValidator.validate(file);
    final noteId = id ?? const Uuid().v4();
    if (!_locks.add(noteId)) {
      throw const AppException('Bu not için bir işlem devam ediyor.');
    }
    String? newPath;
    var committed = false;
    try {
      if (file != null) {
        newPath = 'notes/${user.uid}/$noteId/${const Uuid().v4()}';
        await files.put(newPath, file, onProgress: onProgress);
      }
      final note = await store.write(() {
        if (store.sessionRevision != revision) {
          throw const AppException('Oturum değişti. İşlem iptal edildi.');
        }
        final now = DateTime.now().toUtc();
        final latest = store.notes[noteId];
        final note = NoteModel(
          id: noteId,
          title: draft.title.trim(),
          description: draft.description.trim(),
          courseName: draft.courseName.trim(),
          categoryId: draft.categoryId,
          university: draft.university.trim(),
          tags: Validators.tags(draft.tags.join(',')),
          userId: user.uid,
          userName: store.requireUser.fullName,
          fileName: file?.name ?? old!.fileName,
          storagePath: newPath ?? old!.storagePath,
          fileType: file?.extension ?? old!.fileType,
          fileSize: file?.size ?? old!.fileSize,
          createdAt: old?.createdAt ?? now,
          updatedAt: now,
          downloadCount: latest?.downloadCount ?? 0,
          favoriteCount: latest?.favoriteCount ?? 0,
        );
        store.notes[noteId] = note;
        return note;
      });
      committed = true;
      store.dataChanged();
      // Yeni metadata bağlanmadan eski dosyayı silmeyiz.
      if (newPath != null && old != null) await _cleanup(old.storagePath);
      return note;
    } catch (_) {
      if (!committed && newPath != null) await _cleanup(newPath);
      rethrow;
    } finally {
      _locks.remove(noteId);
    }
  }

  @override
  Future<void> delete(String id) async {
    final user = store.requireUser;
    final note = store.notes[id];
    if (note == null) throw const AppException('Not bulunamadı.');
    if (note.userId != user.uid) {
      throw const AppException('Yalnızca kendi notunuzu silebilirsiniz.');
    }
    if (!_locks.add(id)) {
      throw const AppException('Bu not için bir işlem devam ediyor.');
    }
    try {
      await store.write(() {
        if (user.uid != store.requireUser.uid) {
          throw const AppException('Oturum değişti.');
        }
        store.notes.remove(id);
        for (final favorites in store.favorites.values) {
          favorites.remove(id);
        }
      });
      store.dataChanged();
      await _cleanup(note.storagePath);
    } finally {
      _locks.remove(id);
    }
  }

  @override
  Future<void> recordDownload(String id) async {
    final uid = store.requireUser.uid;
    await store.write(() {
      if (uid != store.requireUser.uid) {
        throw const AppException('Oturum değişti.');
      }
      final note = store.notes[id];
      if (note == null) throw const AppException('Not bulunamadı.');
      store.notes[id] = note.changed({'downloadCount': note.downloadCount + 1});
    });
    store.noteEvents.add(null);
  }

  Future<void> _cleanup(String path) async {
    try {
      await files.delete(path);
    } catch (_) {
      // Metadata zaten güvenli. Açılışta 24 saatten eski sahipsiz ekler toplanır.
    }
  }
}
