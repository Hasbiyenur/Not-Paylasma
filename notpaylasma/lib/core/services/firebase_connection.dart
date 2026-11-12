import 'package:firebase_core/firebase_core.dart';

import '../utils/app_exception.dart';

/// Yalnızca gerçek yapılandırmayla açıkça çağrılır; mock başlangıcı çağırmaz.
class FirebaseConnection {
  static Future<FirebaseApp> initialize(FirebaseOptions options) async {
    if (options.apiKey.trim().isEmpty ||
        options.appId.trim().isEmpty ||
        options.projectId.trim().isEmpty ||
        options.messagingSenderId.trim().isEmpty) {
      throw const AppException(
        'Firebase yapılandırması eksik. Kurulum rehberini tamamlayın.',
      );
    }
    try {
      if (Firebase.apps.isNotEmpty) {
        final app = Firebase.app();
        if (app.options.projectId != options.projectId ||
            app.options.appId != options.appId) {
          throw const AppException(
            'Açık Firebase projesi yapılandırmayla uyuşmuyor.',
          );
        }
        return app;
      }
      return await Firebase.initializeApp(options: options);
    } on FirebaseException {
      throw const AppException(
        'Firebase başlatılamadı. Proje ve platform ayarlarını kontrol edin.',
      );
    }
  }
}
