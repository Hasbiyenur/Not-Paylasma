// Yalnızca demo emülatörlerine bağlanır; canlı kullanıcı oluşturmaz.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notpaylas/core/services/hybrid_dependencies.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      home: Scaffold(
        body: FutureBuilder<String>(
          future: probe(),
          builder: (context, snapshot) => SingleChildScrollView(
            child: SelectableText(
              snapshot.hasError
                  ? 'FAIL: ${snapshot.error}'
                  : snapshot.data ?? 'RUNNING',
            ),
          ),
        ),
      ),
    ),
  );
}

Future<String> probe() async {
  const options = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:123:web:demo',
    messagingSenderId: '123',
    projectId: 'demo-notpaylas',
  );
  await Firebase.initializeApp(options: options);
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  final deps = await createHybridDependencies(options);
  final email =
      'registration-${DateTime.now().microsecondsSinceEpoch}@example.com';
  try {
    await deps.auth.register('Çağla', 'Şahin', email, 'Emulator123!');
    final user = deps.auth.currentUser;
    if (user == null || user.firstName != 'Çağla') {
      throw StateError('Profil yok');
    }
    final uid = user.uid;
    await deps.auth.signOut();
    await deps.auth.signIn(email, 'Emulator123!');
    if (deps.auth.currentUser?.uid != uid) {
      throw StateError('Tekrar giriş başarısız');
    }
    return 'PASS: kayıt, profil, çıkış ve tekrar giriş';
  } catch (error, stack) {
    debugPrint('PROBE ${error.runtimeType}: $error\n$stack');
    rethrow;
  } finally {
    await deps.close();
  }
}
