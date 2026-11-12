// Yerel kabul uygulaması; gerçek Firebase projesine bağlanmaz.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notpaylas/core/services/hybrid_dependencies.dart';
import 'package:notpaylas/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const options = FirebaseOptions(
    apiKey: 'demo-key',
    appId: '1:123:web:demo',
    messagingSenderId: '123',
    projectId: 'demo-notpaylas',
  );
  await Firebase.initializeApp(options: options);
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  await FirebaseAuth.instance.signOut();
  runApp(
    NotPaylasBootstrap(
      loadDependencies: () => createHybridDependencies(options),
    ),
  );
}
