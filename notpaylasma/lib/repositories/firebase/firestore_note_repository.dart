import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/file_storage_service.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/file_validator.dart';
import '../../core/utils/validators.dart';
import '../../models/note_model.dart';
import '../../models/selected_file.dart';
import '../note_repository.dart';
import 'firebase_support.dart';

class FirestoreNoteRepository implements NoteRepository {
  FirestoreNoteRepository(this.auth, this.db, this.files)
    : feed = FirebaseChangeFeed(auth, (_) => db.collection('notes'));
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FileStorageService files;
  final FirebaseChangeFeed feed;
  final _locks = <String>{};
  @override
  Stream<void> get changes => feed.changes;
  NoteModel _decode(DocumentSnapshot<Map<String, dynamic>> doc) =>
      NoteModel.fromJson({...decodeDocument(doc), 'id': doc.id});

  @override
  Future<NoteModel?> getById(String id) async {
    requireUid(auth);
    final doc = await db.collection('notes').doc(id).get();
    return doc.exists ? _decode(doc) : null;
  }

  @override
  Future<NotePage> query(NoteQuery query) async {
    requireUid(auth);
    Query<Map<String, dynamic>> ref = db.collection('notes');
    if (query.categoryId != null) {
      ref = ref.where('categoryId', isEqualTo: query.categoryId);
    }
    if (query.userId != null) {
      ref = ref.where('userId', isEqualTo: query.userId);
    }
    final tag = Validators.normalize(query.tag);
    if (tag.isNotEmpty) ref = ref.where('tags', arrayContains: tag);
    final field = switch (query.sort) {
      NoteSort.newest => 'createdAt',
      NoteSort.downloads => 'downloadCount',
      NoteSort.popular => 'favoriteCount',
    };
    ref = ref
        .orderBy(field, descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (query.cursor != null) {
      final cursor = await db.collection('notes').doc(query.cursor).get();
      if (!cursor.exists) {
        throw const AppException('Liste değişti. Listeyi yenileyin.');
      }
      ref = ref.startAfterDocument(cursor);
    }
    final limit = query.limit.clamp(1, 100);
    final search = Validators.normalize(query.search);
    final items = <NoteModel>[];
    // Firestore tam metin araması sunmaz. Filtrelenmiş sayfalar taranır;
    // geniş veri kümelerinde ayrı bir arama indeksi gerekir.
    while (items.length <= limit) {
      final page = await ref.limit(100).get();
      for (final doc in page.docs) {
        final note = _decode(doc);
        final words = Validators.normalize('${note.title} ${note.courseName}')
            .split(RegExp(r'\s+'));
        if (search.isEmpty ||
            search
                .split(RegExp(r'\s+'))
                .every((term) => words.any((word) => word.startsWith(term)))) {
          items.add(note);
          if (items.length > limit) break;
        }
      }
      if (items.length > limit || page.docs.length < 100) break;
      ref = ref.startAfterDocument(page.docs.last);
    }
    final hasMore = items.length > limit;
    if (hasMore) items.removeLast();
    return NotePage(items, hasMore ? items.last.id : null);
  }

  @override
  Future<NoteModel> save(
    NoteDraft draft, {
    String? id,
    SelectedFile? file,
    void Function(double)? onProgress,
  }) async {
    final uid = requireUid(auth);
    Validators.require(Validators.text(draft.title, 'Başlık', 3, 120));
    Validators.require(
      Validators.text(draft.description, 'Açıklama', 10, 3000),
    );
    Validators.require(Validators.text(draft.courseName, 'Ders', 2, 100));
    Validators.require(Validators.text(draft.university, 'Kurum', 0, 160));
    final tags = Validators.tags(draft.tags.join(','));
    if (file != null) FileValidator.validate(file);
    final noteId = id ?? const Uuid().v4();
    if (!_locks.add(noteId)) {
      throw const AppException('Bu not için işlem devam ediyor.');
    }
    try {
      final ref = db.collection('notes').doc(noteId);
      final before = await ref.get();
      final old = before.exists ? _decode(before) : null;
      if (id != null && old == null) {
        throw const AppException('Not bulunamadı.');
      }
      if (old != null && old.userId != uid) {
        throw const AppException(
          'Yalnızca kendi notunuzu düzenleyebilirsiniz.',
        );
      }
      if (old == null && file == null) {
        throw const AppException('Bir dosya seçin.');
      }
      if (!(await db.collection('categories').doc(draft.categoryId).get())
          .exists) {
        throw const AppException('Geçerli bir kategori seçin.');
      }
      final profile = await db.collection('users').doc(uid).get();
      if (!profile.exists) {
        throw const AppException('Profil bulunamadı. Yeniden giriş yapın.');
      }
      final path = file == null
          ? old!.storagePath
          : 'notes/$uid/$noteId/${const Uuid().v4()}';
      if (file != null) await files.put(path, file, onProgress: onProgress);
      await db.runTransaction((tx) async {
        final latest = await tx.get(ref);
        if (auth.currentUser?.uid != uid) {
          throw const AppException('Oturum değişti.');
        }
        if (id != null && !latest.exists) {
          throw const AppException('Not silinmiş. Listeyi yenileyin.');
        }
        if (latest.exists &&
            latest.data()!['storagePath'] != old?.storagePath) {
          throw const AppException('Not değişti. Listeyi yenileyin.');
        }
        final data = profile.data()!;
        tx.set(ref, {
          'id': noteId,
          'title': draft.title.trim(),
          'description': draft.description.trim(),
          'courseName': draft.courseName.trim(),
          'categoryId': draft.categoryId,
          'university': draft.university.trim(),
          'tags': tags,
          'userId': uid,
          'userName': '${data['firstName']} ${data['lastName']}',
          'fileName': file?.name ?? old!.fileName,
          'storagePath': path,
          'fileType': file?.extension ?? old!.fileType,
          'fileSize': file?.size ?? old!.fileSize,
          'createdAt':
              latest.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'downloadCount': latest.data()?['downloadCount'] ?? 0,
          'favoriteCount': latest.data()?['favoriteCount'] ?? 0,
        });
        if (old != null && file != null) {
          _scheduleCleanup(tx, uid, old.storagePath);
        }
      });
      await retryFileCleanup(uid);
      return _decode(await ref.get(const GetOptions(source: Source.server)));
    } finally {
      // Ağ hatasında commit sonucu belirsiz olabilir; yeni dosya burada silinmez.
      _locks.remove(noteId);
    }
  }

  void _scheduleCleanup(Transaction tx, String uid, String path) {
    tx.set(db.collection('users/$uid/fileCleanup').doc(), {'path': path});
  }

  /// Metadata ile aynı transaction'da kaydedilen temizliği tekrar dener.
  Future<void> retryFileCleanup(String uid) async {
    try {
      final jobs = await db
          .collection('users/$uid/fileCleanup')
          .limit(50)
          .get();
      for (final job in jobs.docs) {
        await files.delete(job.data()['path'] as String);
        await job.reference.delete();
      }
    } catch (_) {
      // İş kalıcı kuyrukta kalır; sonraki kaydetme/silmede yeniden denenir.
    }
  }

  @override
  Future<void> delete(String id) async {
    final uid = requireUid(auth);
    if (!_locks.add(id)) {
      throw const AppException('Bu not için işlem devam ediyor.');
    }
    try {
      final ref = db.collection('notes').doc(id);
      await db.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (!doc.exists) return;
        if (doc.data()!['userId'] != uid) {
          throw const AppException('Yalnızca kendi notunuzu silebilirsiniz.');
        }
        _scheduleCleanup(tx, uid, doc.data()!['storagePath'] as String);
        tx.delete(ref);
      });
      await retryFileCleanup(uid);
    } finally {
      _locks.remove(id);
    }
  }

  @override
  Future<void> recordDownload(String id) async {
    requireUid(auth);
    await db.doc('notes/$id').update({
      'downloadCount': FieldValue.increment(1),
    });
  }

  Future<void> close() => feed.close();
}
