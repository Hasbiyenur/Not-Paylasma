import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';

import '../../core/services/json_file_system.dart';
import '../../core/utils/app_exception.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';
import '../local/local_auth_repository.dart';
import '../local/local_json_store.dart';

/// Firebase kullanıcı profilini yalnızca bellekte tutar. Avatar ve notlar yereldir.
class HybridAuthRepository implements AuthRepository {
  HybridAuthRepository(this.remote, this.store, this.fs, {this.closeRemote}) {
    _subscription = remote.changes.listen((_) {
      _queueSync().ignore();
    });
    ready = _queueSync();
  }
  final AuthRepository remote;
  final LocalJsonStore store;
  final JsonFileSystem fs;
  final Future<void> Function()? closeRemote;
  late final Future<void> ready;
  late final StreamSubscription<UserModel?> _subscription;
  final _events = StreamController<UserModel?>.broadcast();
  Future<void> _tail = Future<void>.value();
  bool _closed = false;
  @override
  bool get usesEmailPasswordReset => true;
  @override
  UserModel? get currentUser => store.currentUid == remote.currentUser?.uid
      ? store.users[store.currentUid]
      : null;
  @override
  Stream<UserModel?> get changes => _events.stream;

  Future<void> _queueSync() {
    final next = _tail.then((_) async {
      if (_closed) return;
      final user = remote.currentUser;
      if (user == null) {
        store.users.clear();
        store.currentUid = null;
        store.sessionRevision++;
      } else {
        final renamedNotes = store.notes.values
            .where(
              (note) =>
                  note.userId == user.uid && note.userName != user.fullName,
            )
            .toList();
        // Profil/oturum JSON'a ait değildir. Özellikle yeni hesap açılışı
        // yerel disk yazmasının başarısına bağlı olmamalıdır.
        if (renamedNotes.isNotEmpty) {
          await store.write(() {
            if (remote.currentUser?.uid != user.uid) return;
            for (final note in renamedNotes) {
              final current = store.notes[note.id];
              if (current?.userId == user.uid) {
                store.notes[note.id] = current!.changed({
                  'userName': user.fullName,
                });
              }
            }
          });
        }
        if (remote.currentUser?.uid != user.uid) return;
        if (store.currentUid != user.uid) store.sessionRevision++;
        store.users.clear();
        store.currentUid = user.uid;
        store.users[user.uid] = UserModel(
          uid: user.uid,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
          photoUrl: store.localAvatars[user.uid],
        );
      }
      if (!_closed) {
        _events.add(currentUser);
        store.dataChanged();
      }
    });
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (error) {
      throw AppException(switch (error.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'E-posta veya şifre hatalı.',
        'email-already-in-use' =>
          'Bu e-posta Firebase’de kayıtlı. Giriş yapın.',
        'operation-not-allowed' => 'Firebase Console’da Authentication e-posta/şifre sağlayıcısını etkinleştirin.',
        'permission-denied' => 'Kullanıcı profiline erişilemiyor. Firestore veritabanını ve kullanıcı kurallarını kontrol edin.',
        'network-request-failed' || 'unavailable' =>
          'Firebase bağlantısı kurulamadı. İnternet bağlantısını kontrol edin.',
        'too-many-requests' =>
          'Çok fazla deneme yapıldı. Biraz sonra tekrar deneyin.',
        'weak-password' => 'Daha güçlü bir şifre seçin.',
        _ => 'Firebase kullanıcı işlemi tamamlanamadı (${error.code}).',
      });
    }
  }

  @override
  Future<void> signIn(String email, String password) => _run(() async {
    await remote.signIn(email, password);
    await _queueSync();
  });
  @override
  Future<void> register(
    String first,
    String last,
    String email,
    String password,
  ) => _run(() async {
    await remote.register(first, last, email, password);
    await _queueSync();
  });
  @override
  Future<void> signOut() => _run(() async {
    await remote.signOut();
    await _queueSync();
  });
  @override
  Future<PasswordResetRequest> requestPasswordReset(String email) =>
      _run(() => remote.requestPasswordReset(email));
  @override
  Future<void> confirmPasswordReset(String id, String code, String password) =>
      _run(() => remote.confirmPasswordReset(id, code, password));
  @override
  Future<void> updateProfile(String first, String last, {String? photoUrl}) =>
      _run(() async {
        final uid = currentUser?.uid;
        if (uid == null) throw const AppException('Önce giriş yapın.');
        // Fotoğraf yolu dahil hiçbir fotoğraf verisi Firebase'e verilmez.
        await remote.updateProfile(first, last);
        if (remote.currentUser?.uid != uid) {
          throw const AppException('Oturum değişti.');
        }
        if (photoUrl != null) {
          await store.write(() => store.localAvatars[uid] = photoUrl);
        }
        await _queueSync();
      });

  Future<void> migrateLegacyAccount(String email, String password) =>
      _run(() async {
        final bytes = await fs.read('legacy-accounts.json');
        if (bytes == null) {
          throw const AppException(
            'Aktarılacak yerel hesap bulunamadı. Firebase hesabınızla giriş yapın veya hesap oluşturun.',
          );
        }
        final state = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(bytes)) as Map,
        );
        final legacy = LocalJsonStore()..restore(state);
        try {
          final localAuth = LocalAuthRepository(legacy);
          await localAuth.signIn(email, password);
          final oldUser = localAuth.currentUser!;
          try {
            await remote.register(
              oldUser.firstName,
              oldUser.lastName,
              email,
              password,
            );
          } on FirebaseException catch (error) {
            if (error.code != 'email-already-in-use') rethrow;
            await remote.signIn(email, password);
          }
          final newUser = remote.currentUser;
          if (newUser == null) {
            throw const AppException(
              'Firebase profili hazır değil. Aktarmayı yeniden deneyin.',
            );
          }
          await store.write(() {
            if (remote.currentUser?.uid != newUser.uid) {
              throw const AppException('Oturum değişti.');
            }
            for (final note in store.notes.values.toList()) {
              if (note.userId == oldUser.uid) {
                store.notes[note.id] = note.changed({
                  'userId': newUser.uid,
                  'userName': newUser.fullName,
                });
              }
            }
            if (oldUser.uid != newUser.uid) {
              final ids = store.favorites.remove(oldUser.uid) ?? {};
              store.favorites.putIfAbsent(newUser.uid, () => {}).addAll(ids);
              final avatar =
                  store.localAvatars.remove(oldUser.uid) ?? oldUser.photoUrl;
              if (avatar != null) {
                store.localAvatars.putIfAbsent(newUser.uid, () => avatar);
              }
            }
            for (final note in store.notes.values.toList()) {
              store.notes[note.id] = note.changed({
                'favoriteCount': store.favorites.values
                    .where((ids) => ids.contains(note.id))
                    .length,
              });
            }
          });
          await _queueSync();
          // Profil doğrulanıp yerel sahiplik taşındıktan sonra bu hesabın geçiş bilgilerini kaldır.
          (state['users'] as List).removeWhere(
            (user) => user['uid'] == oldUser.uid,
          );
          (state['credentials'] as Map).remove(oldUser.uid);
          state['currentUid'] = null;
          // Geçiş belgesi yalnızca kalan hesapları doğrulamak içindir, not deposu değildir.
          state['notes'] = [];
          state['favorites'] = {};
          state['localAvatars'] = {};
          if ((state['users'] as List).isEmpty) {
            await fs.delete('legacy-accounts.json');
          } else {
            await fs.write(
              'legacy-accounts.json',
              utf8.encode(jsonEncode(state)),
            );
          }
        } finally {
          legacy.close();
        }
      });
  Future<void> close() async {
    _closed = true;
    await _subscription.cancel();
    await _tail;
    await closeRemote?.call();
    await _events.close();
  }
}
