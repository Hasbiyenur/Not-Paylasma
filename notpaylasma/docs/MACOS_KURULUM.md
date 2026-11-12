# macOS üzerinde NotPaylaş

12 Kasım 2026 istemci ayarı güncellemesi: anahtarlar Git dışında `.local/firebase-keys.json` içindedir. Yeni klonda önce [SECURITY.md](../SECURITY.md) kurulumunu tamamlayın. `bash scripts/macos.sh run` yerel dosyayı otomatik kullanır. Doğrudan Flutter/Xcode çalıştırmalarında da ilgili Dart define ayarının hazırlanması gerekir; manuel Flutter komutu `flutter run -d macos --dart-define-from-file=.local/firebase-keys.json` olur. Eski anahtarsız çalıştırma komutları güncel düzeni yansıtmaz.

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

## Çalışmayan Mac kurulumunu teşhis etme

Windows üzerinde Xcode çalıştırılamadığı için gerçek Mac hatası görülmeden native derleme başarılı kabul edilmez. Proje kökünde güncel betikle:

```bash
bash scripts/macos.sh diagnose
```

Bu komut macOS/mimari, Flutter/Dart, Xcode/CocoaPods bilgilerini, Flutter doctor, bağımlılık çözümü ve ayrıntılı debug derleme çıktısını `build/diagnostics/macos.log` dosyasına kaydeder. Hata olduğunda sıfırdan farklı çıkış kodu korunur. Sisteme araç kurmaz, imzalama/Firebase ayarlarını değiştirmez ve kullanıcı verilerini silmez. Sorun incelemesi için çıktının ilk hata satırı ve son 50 satırı kullanılabilir:

```bash
tail -n 50 build/diagnostics/macos.log
```

## Doğrulanan imzalama hatası: Runner entitlements

12 Kasım 2026 Mac ekran görüntüsündeki asıl hata: `Runner has entitlements that require signing with a development certificate`. Run Script uyarısı ve CocoaPods temizleme önerisi bu hatanın nedeni değildir.

Runner'ın AppInfo.xcconfig dosyasında imzalama kimliği Apple Development olarak ayarlandı. Proje düzeyindeki Flutter şablonu ad-hoc (-) kimliği native bağımlılıklar için korunur; Runner hedefi bunu geliştirme kimliğiyle geçersiz kılar. Otomatik imzalama zaten Runner Debug/Profile/Release yapılandırmalarında açıktır. Firebase Auth için gereken Keychain yetkisi korunur.

Güncel kaynakları Mac'e aldıktan sonra, pubspec.yaml bulunan proje kökünde:

```bash
open macos/Runner.xcworkspace
```

1. Xcode > Settings > Accounts bölümünde kendi Apple hesabını ekle. Sertifika ve özel anahtar Mac'te kalır.
2. Solda Runner projesini, ardından TARGETS > Runner hedefini seç. Signing & Capabilities altında Automatically manage signing açık olsun; Team alanında kendi takımını/Personal Team'i seç. Debug, Profile ve Release için geçerli olduğundan emin ol. Mevcut Firebase kaydıyla eşleşen com.example.notpaylas bundle ID'sini koru.
3. Signing Certificate alanında Apple Development görünmeli. Sertifika yoksa Xcode > Settings > Accounts > Manage Certificates > + > Apple Development ile yerel geliştirme sertifikası oluştur. Bu işlem uygulama sahibinin Mac'inde yapılır; sohbet üzerinden sertifika/parola alınmaz.
4. Xcode'da My Mac hedefiyle bir kez Run çalıştır. Ardından terminalde `flutter run -d macos` kullanılabilir.

[Apple'ın takım seçimi rehberi](https://help.apple.com/xcode/mac/current/en.lproj/dev23aab79b4.html), Apple Developer Program üyesi olmayan hesaplar için Personal Team oluşturulmasını açıklar. Ücretli üyelik veya yayın satın alınmaz. Hesap/takım bir yeteneği desteklemiyorsa görünen Xcode hata metniyle ayrıca değerlendirilir; gereksiz ücretli üyelik önerilmez.

Bu Windows ortamından Mac'in Xcode hesabı, takımı ve sertifikası seçilemez. İmzalama yapılandırması düzeltildi; gerçek Mac derleme kabulü takım/sertifika seçiminin ardından doğrulanmalıdır.

## Mac üzerinde kabul

- Açılış ve giriş yükleme ekranı, gerçek Firebase hesabıyla kayıt/giriş/çıkış ve profil adı değişikliği.
- Uygulamayı kapatıp açınca oturumun ve yerel not/favori/fotoğrafın korunması.
- PDF/PNG seçme ve not kaydetme; PNG'nin uygulama içinde, PDF/DOCX'in uygun uygulamada açılması.
- İndir diyaloğunda kaydetme ve iptal; PNG profil fotoğrafı seçme/kaydetme/gösterme.
- Erişim hatası/ağ kesintisinde anlaşılır hata, başka kullanıcının profiline erişimin reddedilmesi.

Windows üzerinde native macOS derlemesi yapılamadı. Yapılandırma hazırlığı ve ortak Dart testleri Mac üzerindeki bu kabulün yerine geçmez.

Resmî kaynaklar: [Flutter macOS ortamı](https://docs.flutter.dev/platform-integration/macos/setup), [macOS izinleri ve derleme](https://docs.flutter.dev/platform-integration/macos/building), [Firebase Flutter ve Keychain Sharing](https://firebase.google.com/docs/flutter/setup).
