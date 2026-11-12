# macOS üzerinde NotPaylaş

## Güncel yapılandırma

Uygulama macOS 12.0 ve üzerini hedefler. `macos/` içinde Swift Runner, Xcode proje/workspace, Swift Package Manager bağlantısı ve CocoaPods Podfile bulunur. Flutter gerektiğinde CocoaPods eklentilerini kurar; Pods ve ephemeral dosyaları Mac üzerinde üretilir.

`lib/firebase_options.dart` içindeki macOS seçenekleri mevcut `not-paylasma-proje` uygulamasına aittir. Xcode bundle ID `com.example.notpaylas` ile eşleşir. Normal çalıştırma için Firebase CLI oturumu açmak, yeni proje oluşturmak veya `flutterfire configure` komutunu tekrar çalıştırmak gerekmez.

Yalnızca kullanıcı hesabı/profili Firebase Auth/Firestore'dadır. Not, favori, ek ve profil fotoğrafı uygulamanın yerel destek dizininde tutulur. Firebase Storage kullanılmaz. Mevcut proje ücretsiz Spark planındadır; ödeme hesabı veya ücretli plan açılmaz.

## Mac hazırlığı

1. Projenin tamamını Mac'e alın; `macos`, `lib`, `assets`, `scripts`, `pubspec.yaml` ve `pubspec.lock` birlikte bulunmalıdır. Windows'tan `build`, `.dart_tool`, Pods veya ephemeral klasörlerini taşımayın.
2. Flutter 3.47.9 / Dart 3.13.7 ile uyumlu SDK kurun. Tam Xcode'u kurup bir kez açın; gerekli ilk kurulum ve lisans adımlarını kendiniz tamamlayın.
3. Xcode komut satırı araçlarının tam Xcode'u göstermesini sağlayın. Gerekirse `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` çalıştırın. `xcodebuild -version` Xcode sürümünü göstermelidir.
4. [CocoaPods kurulum rehberi](https://guides.cocoapods.org/using/getting-started.html) ile CocoaPods'u kurun; `pod --version` çalışmalıdır. Betik sistem araçlarını kendiliğinden kurmaz veya sudo çalıştırmaz.
5. `flutter doctor -v` çıktısındaki Xcode/macOS sorunlarını giderin; `flutter devices` listesinde macOS görünmelidir.

## Çalıştırma ve derleme

Terminalde `pubspec.yaml` dosyasının bulunduğu klasöre geçin:

```bash
bash scripts/macos.sh run
```

Betik araçları kontrol eder, bağımlılıkları çözer ve `flutter run -d macos` başlatır. Betiği `bash` ile çalıştırdığınız için yürütme biti gerekmez.

```bash
# Analiz + mevcut uygulama testleri + debug .app:
bash scripts/macos.sh check
# Release .app:
bash scripts/macos.sh build
```

Release çıktısı `build/macos/Build/Products/Release/notpaylas.app` olur. Bu komut dağıtım imzası/notarizasyon veya App Store yayını yapmaz. İlk native bağımlılık çözümü internet ve yeterli disk alanı ister.

## Xcode, izinler ve oturum

Gerekirse `open macos/Runner.xcworkspace` ile workspace'i açın. Runner > Signing & Capabilities altında bundle ID'yi ve yerel geliştirme için uygun imzalamayı kontrol edin. Kişisel Team ID/parolası kaynaklara yazılmaz; ücretli Apple Developer üyeliği veya yayın bu rehber tarafından istenmez. Keychain imza hatası alınırsa mevcut entitlement'ları silmek yerine Xcode'da yerel imzalama ayarlarını kontrol edin.

Debug/Profile ve Release entitlement dosyalarında sandbox, dışarı ağ bağlantısı, kullanıcı seçimiyle dosya okuma/yazma ve Keychain grubu vardır. Runner hedefinde Keychain Sharing işaretlidir. Debug/JIT ve geliştirme sunucusu izinleri yalnızca Debug/Profile dosyasında korunur.

Firebase Auth hesap/oturum saklamasını, Keychain üzerinden native SDK yönetir. Yerel profil fotoğrafı bu kimlik servisine yüklenmez. Dosya seçme/kaydetme native seçiciyi, PDF/DOCX açma macOS'un varsayılan uygulamasını kullanır. Firebase SDK Dart seçenekleriyle başlatıldığı için ayrıca sahte bir GoogleService-Info.plist üretilmez.

## Mac üzerinde kabul

- Açılış ve giriş yükleme ekranı, gerçek Firebase hesabıyla kayıt/giriş/çıkış ve profil adı değişikliği.
- Uygulamayı kapatıp açınca oturumun ve yerel not/favori/fotoğrafın korunması.
- PDF/PNG seçme ve not kaydetme; PNG'nin uygulama içinde, PDF/DOCX'in uygun uygulamada açılması.
- İndir diyaloğunda kaydetme ve iptal; PNG profil fotoğrafı seçme/kaydetme/gösterme.
- Erişim hatası/ağ kesintisinde anlaşılır hata, başka kullanıcının profiline erişimin reddedilmesi.

Windows üzerinde native macOS derlemesi yapılamadı. Yapılandırma hazırlığı ve ortak Dart testleri Mac üzerindeki bu kabulün yerine geçmez.

Resmî kaynaklar: [Flutter macOS ortamı](https://docs.flutter.dev/platform-integration/macos/setup), [macOS izinleri ve derleme](https://docs.flutter.dev/platform-integration/macos/building), [Firebase Flutter ve Keychain Sharing](https://firebase.google.com/docs/flutter/setup).
