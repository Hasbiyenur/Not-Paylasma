import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/utils/app_exception.dart';
import '../favorite_repository.dart';
import 'firebase_support.dart';

class FirestoreFavoriteRepository implements FavoriteRepository {
  FirestoreFavoriteRepository(this.auth, this.db)
    : feed = FirebaseChangeFeed(
        auth,
        (uid) => db.collection('users/$uid/favorites'),
      );
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  final FirebaseChangeFeed feed;
  @override
  Stream<void> get changes => feed.changes;
  @override
  Future<Set<String>> getForCurrentUser() async {
    final uid = requireUid(auth);
    final result = await db.collection('users/$uid/favorites').get();
    return result.docs.map((doc) => doc.id).toSet();
  }

  @override
  Future<void> setFavorite(String noteId, bool value) async {
    final uid = requireUid(auth);
    final ref = db.doc('users/$uid/favorites/$noteId');
    final note = db.doc('notes/$noteId');
    await db.runTransaction((tx) async {
      final favorite = await tx.get(ref);
      final snapshot = await tx.get(note);
      if (!snapshot.exists) {
        if (!value && favorite.exists) {
          tx.delete(ref);
          return;
        }
        throw const AppException('Not artık mevcut değil.');
      }
      if (favorite.exists == value) return;
      if (value) {
        tx.set(ref, {
          'noteId': noteId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.delete(ref);
      }
      tx.update(note, {
        'favoriteCount':
            (snapshot.data()!['favoriteCount'] as int) + (value ? 1 : -1),
      });
    });
  }

  Future<void> close() => feed.close();
}
