import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';
import 'local_json_store.dart';

class LocalAuthRepository implements AuthRepository {
  @override
  bool get usesEmailPasswordReset => false;
  LocalAuthRepository(this.store);
  final LocalJsonStore store;
  final _resetBusy = <String>{};
  final _resets =
      <String, ({String uid, String code, DateTime expires, int attempts})>{};
  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
  void setPassword(String uid, String password) {
    final salt = const Uuid().v4();
    store.credentials[uid] = (salt: salt, hash: _hash(salt, password));
  }

  @override
  UserModel? get currentUser => store.users[store.currentUid];
  @override
  Stream<UserModel?> get changes => store.authEvents.stream;
  void _session(String? uid) {
    store.currentUid = uid;
    store.sessionRevision++;
  }

  @override
  Future<void> signIn(String email, String password) async {
    await store.write(() {
      Validators.require(Validators.email(email));
      final matches = store.users.values.where(
        (u) => u.email == email.trim().toLowerCase(),
      );
      if (matches.isEmpty) {
        throw const AppException('E-posta veya şifre hatalı.');
      }
      final user = matches.first;
      final secret = store.credentials[user.uid]!;
      if (secret.hash != _hash(secret.salt, password)) {
        throw const AppException('E-posta veya şifre hatalı.');
      }
      _session(user.uid);
    });
    store.authEvents.add(currentUser);
  }

  @override
  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    await store.write(() {
      Validators.require(Validators.text(firstName, 'Ad', 1, 60));
      Validators.require(Validators.text(lastName, 'Soyad', 1, 60));
      Validators.require(Validators.email(email));
      Validators.require(Validators.password(password));
      email = email.trim().toLowerCase();
      if (store.users.values.any((u) => u.email == email)) {
        throw const AppException('Bu e-posta zaten kayıtlı.');
      }
      final uid = const Uuid().v4();
      final now = DateTime.now().toUtc();
      store.users[uid] = UserModel(
        uid: uid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email,
        createdAt: now,
        updatedAt: now,
      );
      setPassword(uid, password);
      _session(uid);
    });
    store.authEvents.add(currentUser);
  }

  @override
  Future<void> signOut() async {
    await store.write(() => _session(null));
    store.authEvents.add(currentUser);
  }

  @override
  Future<PasswordResetRequest> requestPasswordReset(String email) async {
    await store.settled;
    Validators.require(Validators.email(email));
    final matches = store.users.values.where(
      (u) => u.email == email.trim().toLowerCase(),
    );
    if (matches.isEmpty) {
      throw const AppException('Kayıtlı yerel hesap bulunamadı.');
    }
    final uid = matches.first.uid;
    _resets.removeWhere((_, r) => r.uid == uid);
    final id = const Uuid().v4();
    final code = (100000 + Random.secure().nextInt(900000)).toString();
    _resets[id] = (
      uid: uid,
      code: code,
      expires: DateTime.now().add(const Duration(minutes: 5)),
      attempts: 0,
    );
    return PasswordResetRequest(id: id, demoCode: code);
  }

  @override
  Future<void> confirmPasswordReset(
    String id,
    String code,
    String password,
  ) async {
    if (!_resetBusy.add(id)) {
      throw const AppException('Bu kod için işlem devam ediyor.');
    }
    try {
      Validators.require(Validators.password(password));
      final reset = _resets[id];
      if (reset == null ||
          reset.expires.isBefore(DateTime.now()) ||
          reset.attempts >= 5) {
        _resets.remove(id);
        throw const AppException(
          'Kodun süresi veya deneme hakkı bitti. Yeni kod isteyin.',
        );
      }
      if (reset.code != code.trim()) {
        _resets[id] = (
          uid: reset.uid,
          code: reset.code,
          expires: reset.expires,
          attempts: reset.attempts + 1,
        );
        throw const AppException('Doğrulama kodu hatalı.');
      }
      await store.write(() {
        setPassword(reset.uid, password);
        if (store.currentUid == reset.uid) _session(null);
      });
      _resets.remove(id);
      store.authEvents.add(currentUser);
    } finally {
      _resetBusy.remove(id);
    }
  }

  @override
  Future<void> updateProfile(
    String firstName,
    String lastName, {
    String? photoUrl,
  }) async {
    final revision = store.sessionRevision;
    await store.write(() {
      if (revision != store.sessionRevision) {
        throw const AppException('Oturum değişti.');
      }
      final current = store.requireUser;
      Validators.require(Validators.text(firstName, 'Ad', 1, 60));
      Validators.require(Validators.text(lastName, 'Soyad', 1, 60));
      final updated = current.copyWith(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        photoUrl: photoUrl,
      );
      store.users[current.uid] = updated;
      for (final note in store.notes.values.toList()) {
        if (note.userId == current.uid) {
          store.notes[note.id] = note.changed({'userName': updated.fullName});
        }
      }
    });
    store.authEvents.add(currentUser);
    store.noteEvents.add(null);
  }
}
