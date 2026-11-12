import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../repositories/firebase/firebase_auth_repository.dart';
import '../../repositories/firebase/firestore_category_repository.dart';
import '../../repositories/firebase/firestore_favorite_repository.dart';
import '../../repositories/firebase/firestore_note_repository.dart';
import 'app_dependencies.dart';
import 'device_file_service.dart';
import 'firebase_connection.dart';
import 'firebase_file_storage_service.dart';

Future<AppDependencies> createFirebaseDependencies(
  FirebaseOptions options,
) async {
  final app = await FirebaseConnection.initialize(options);
  final auth = FirebaseAuth.instanceFor(app: app);
  final db = FirebaseFirestore.instanceFor(app: app);
  final storage = FirebaseStorage.instanceFor(app: app);
  final files = FirebaseFileStorageService(storage);
  final users = FirebaseAuthRepository(auth, db);
  final notes = FirestoreNoteRepository(auth, db, files);
  final favorites = FirestoreFavoriteRepository(auth, db);
  return AppDependencies(
    isFirebase: true,
    auth: users,
    notes: notes,
    favorites: favorites,
    categories: FirestoreCategoryRepository(db),
    files: files,
    device: PlatformDeviceFileService(),
    onClose: () async {
      await users.close();
      await notes.close();
      await favorites.close();
    },
  );
}
