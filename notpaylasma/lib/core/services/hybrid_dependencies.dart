import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../repositories/firebase/firebase_auth_repository.dart';
import '../../repositories/firebase/hybrid_auth_repository.dart';
import 'app_dependencies.dart';
import 'firebase_connection.dart';
import 'local_json_dependencies.dart';

final _configuredApps = <String>{};

/// Yalnızca Auth + users profili Firebase'dedir. Storage/Firestore not servisi oluşturulmaz.
Future<AppDependencies> createHybridDependencies(
  FirebaseOptions options,
) async {
  final app = await FirebaseConnection.initialize(options);
  final firebaseAuth = FirebaseAuth.instanceFor(app: app);
  final db = FirebaseFirestore.instanceFor(app: app);
  if (!_configuredApps.contains(app.name)) {
    db.settings = const Settings(persistenceEnabled: false);
    _configuredApps.add(app.name);
  }
  HybridAuthRepository? hybrid;
  return createLocalJsonDependencies(
    externalUsers: true,
    authFactory: (store, fs) async {
      final remote = FirebaseAuthRepository(firebaseAuth, db);
      hybrid = HybridAuthRepository(
        remote,
        store,
        fs,
        closeRemote: remote.close,
      );
      await hybrid!.ready;
      return hybrid!;
    },
    closeAuth: () => hybrid?.close() ?? Future<void>.value(),
    migrateLocalAccount: (email, password) =>
        hybrid!.migrateLegacyAccount(email, password),
  );
}
