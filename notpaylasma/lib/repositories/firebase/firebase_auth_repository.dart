import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../models/user_model.dart';
import '../auth_repository.dart';
import 'firebase_support.dart';

class FirebaseAuthRepository implements AuthRepository {
  @override
  bool get usesEmailPasswordReset => true;
  FirebaseAuthRepository(this.auth, this.db) {
    _authSubscription = auth.authStateChanges().listen((user) async {
      final generation = ++_generation;
      await _profileSubscription?.cancel();
      if (_closed || generation != _generation) return;
      _current = null;
      _events.add(null);
      if (user != null) {
        _profileSubscription = db
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen(
              (doc) {
                if (_closed || generation != _generation) return;
                if (doc.metadata.hasPendingWrites) return;
                _current = doc.exists
                    ? UserModel.fromJson(decodeDocument(doc))
                    : null;
                _events.add(_current);
              },
              onError: (Object _) {
                if (_closed || generation != _generation) return;
                _current = null;
                _events.add(null);
              },
            );
      }
    });
  }
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final _events = StreamController<UserModel?>.broadcast();
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  UserModel? _current;
  int _generation = 0;
  bool _closed = false;
  @override
  UserModel? get currentUser => _current;
  @override
  Stream<UserModel?> get changes => _events.stream;

  Future<void> _ensureProfile(User user, {String? first, String? last}) async {
    // displayName Auth'ta saklanır; ilk profil yazması kesilirse girişte onarılır.
    final names = (user.displayName ?? 'Kullanıcı').split(' ');
    final ref = db.collection('users').doc(user.uid);
    await db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) {
        tx.set(ref, {
          'uid': user.uid,
          'firstName': first ?? names.first,
          'lastName':
              last ??
              (names.length > 1 ? names.skip(1).join(' ') : 'Kullanıcı'),
          'email': user.email!,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (doc.data()!.containsKey('photoUrl')) {
        tx.update(ref, {
          'photoUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    final doc = await ref.get(const GetOptions(source: Source.server));
    if (auth.currentUser?.uid != user.uid) {
      throw const AppException('Oturum değişti.');
    }
    _current = UserModel.fromJson(decodeDocument(doc));
    if (!_closed) _events.add(_current);
  }

  @override
  Future<void> signIn(String email, String password) async {
    final result = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _ensureProfile(result.user!);
  }

  @override
  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    Validators.require(Validators.text(firstName, 'Ad', 1, 60));
    Validators.require(Validators.text(lastName, 'Soyad', 1, 60));
    Validators.require(Validators.email(email));
    Validators.require(Validators.password(password));
    final result = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user!;
    try {
      await user.updateDisplayName('${firstName.trim()} ${lastName.trim()}');
      await _ensureProfile(
        user,
        first: firstName.trim(),
        last: lastName.trim(),
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint(
          'Yeni hesap profilini tamamlama: ${error.runtimeType}\n$stack',
        );
      }
      // Auth hesabı zaten oluştu; kullanıcıyı tekrar kaydolmaya yönlendirme.
      throw const AppException(
        'Hesabın oluşturuldu ancak profil bilgilerin tamamlanamadı. '
        'Aynı e-posta ve şifreyle giriş yaparak devam edebilirsin.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
    _current = null;
    if (!_closed) _events.add(null);
  }

  @override
  Future<PasswordResetRequest> requestPasswordReset(String email) async {
    Validators.require(Validators.email(email));
    await auth.sendPasswordResetEmail(email: email.trim());
    return const PasswordResetRequest(id: 'firebase-email-link');
  }

  @override
  Future<void> confirmPasswordReset(
    String id,
    String code,
    String password,
  ) async {
    Validators.require(Validators.password(password));
    await auth.confirmPasswordReset(code: code, newPassword: password);
  }

  @override
  Future<void> updateProfile(
    String firstName,
    String lastName, {
    String? photoUrl,
  }) async {
    if (photoUrl != null) {
      throw const AppException(
        'Profil fotoğrafını yerel fotoğraf servisiyle kaydedin.',
      );
    }
    Validators.require(Validators.text(firstName, 'Ad', 1, 60));
    Validators.require(Validators.text(lastName, 'Soyad', 1, 60));
    final uid = requireUid(auth);
    await auth.currentUser!.updateDisplayName(
      '${firstName.trim()} ${lastName.trim()}',
    );
    await db.collection('users').doc(uid).update({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'photoUrl': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _current = _current?.copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
    if (!_closed) _events.add(_current);
  }

  Future<void> close() async {
    _closed = true;
    _generation++;
    await _authSubscription.cancel();
    await _profileSubscription?.cancel();
    await _events.close();
  }
}
