# macOS kurulumu

12 Kasım 2026 güncellemesi: kullanıcı hesabı/profili Firebase Auth ve Firestore'da, profil fotoğrafı ve not/dosyalar yereldedir. Yalnızca ücretsiz plan kullanılır. Aşağıdaki eski başlangıç tariflerinden önce [güncel düzeni](FIREBASE_HESAP_YEREL_DOSYALAR.md) okuyun.


Güncel veri modu yerel JSON'dur. Hem `lib/main.dart` hem eski `lib/main_firebase.dart` komutu yerel JSON açar. Aşağıdaki Firebase ayarları eski/opsiyonel altyapı adımlarıdır. Güncel kayıt davranışı: [Yerel JSON](YEREL_JSON_KAYIT.md).

11 Kasım 2026: Flutter'ın kurulu SDK şablonuyla macos platform klasörü eklendi. Geliştirme bundle ID'si `com.example.notpaylas`; Firebase CLI bu değeri sorarsa aynısı girilir. Dağıtım öncesi uygulama sahibinin kalıcı kimliği seçilmeli; Xcode ve Firebase aynı kimlikle yapılandırılmalıdır.

## Firebase yapılandırması

Kullanıcının başlattığı `flutterfire configure` işleminde macOS bundle ID alanına `com.example.notpaylas` girilir. Proje listeden seçilir; görünen ad ile proje kimliği karıştırılmamalıdır. Tekrar yapılandırmak gerekirse:

```powershell
flutterfire configure --platforms=android,web,macos --macos-bundle-id=com.example.notpaylas
```

CLI gerçek `lib/firebase_options.dart` ve gerekirse `macos/Runner/GoogleService-Info.plist` dosyalarını üretir. Mevcut options dosyasını değiştirme sorusuna evet denir. Sonuç tablosunda macos satırı bulunmalı. Bu adım Console'da Email/Password, Firestore, Storage ve güvenlik kurallarının kurulmasının yerine geçmez.

## Mac üzerinde çalıştırma

macos klasörü de kaynaklarla birlikte Mac'e aktarılır. Flutter ve Xcode kurulur; Xcode ilk kurulum/lisans işlemleri tamamlanır. Xcode'da `macos/Runner.xcworkspace` açılıp Runner hedefinde Signing & Capabilities ve geliştirici takımı kontrol edilir. Firebase için Keychain Sharing yetkisi takım ve uygulama kimliğiyle birlikte doğrulanır. Bağımlılık çözümlemesi CocoaPods isterse Mac üzerinde CocoaPods kurulur.

```bash
flutter doctor -v
flutter pub get
flutter run -d macos -t lib/main_firebase.dart
# Firebase olmadan mock:
flutter run -d macos -t lib/main.dart
```

Şablon minimum macOS 12.0 hedefler. DebugProfile ve Release entitlement dosyalarına internet istemcisi, kullanıcının seçtiği dosyaları okuma/yazma ve Keychain grubu eklendi; şablonun debug/JIT izinleri korundu. Dosya seçme, kaydetme/açma, Auth oturum kalıcılığı ve Firebase işlemleri Mac üzerinde ayrıca denenmelidir.

Windows üzerinde macOS derlemesi veya cihaz kabulü yapılmadı. `flutter build macos -t lib/main_firebase.dart` Mac üzerinde çalıştırılır. İmzalama ve dağıtım kabulü bekliyor; uygulama ikonları Flutter şablonudur.

Resmî kaynaklar: [Flutter macOS uygulamaları](https://docs.flutter.dev/platform-integration/macos/building), [Firebase Flutter kurulumu ve Keychain Sharing](https://firebase.google.com/docs/flutter/setup).
