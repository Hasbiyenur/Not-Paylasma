import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_exception.dart';

String requireUid(FirebaseAuth auth) =>
    auth.currentUser?.uid ?? (throw const AppException('Önce giriş yapın.'));

Map<String, dynamic> decodeDocument(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = Map<String, dynamic>.from(doc.data()!);
  for (final key in ['createdAt', 'updatedAt']) {
    if (data[key] is Timestamp) {
      data[key] = (data[key] as Timestamp).toDate().toUtc().toIso8601String();
    }
  }
  return data;
}

/// Oturum değişince eski dinleyiciyi kapatır; sorgu hataları okuma sırasında iletilir.
class FirebaseChangeFeed {
  FirebaseChangeFeed(
    FirebaseAuth auth,
    Query<Map<String, dynamic>> Function(String) query,
  ) {
    _auth = auth.authStateChanges().listen((user) async {
      final generation = ++_generation;
      await _data?.cancel();
      if (_closed || generation != _generation) return;
      _events.add(null);
      if (user != null) {
        _data = query(user.uid).snapshots().listen(
          (_) {
            if (!_closed) _events.add(null);
          },
          onError: (Object _) {
            if (!_closed) _events.add(null);
          },
        );
      }
    });
  }
  final _events = StreamController<void>.broadcast();
  late final StreamSubscription<User?> _auth;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _data;
  int _generation = 0;
  bool _closed = false;
  Stream<void> get changes => _events.stream;
  Future<void> close() async {
    _closed = true;
    _generation++;
    await _auth.cancel();
    await _data?.cancel();
    await _events.close();
  }
}
