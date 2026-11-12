# NotPaylaş

Türkçe arayüzlü not ve dosya paylaşım uygulaması. Sürüm: **0.3.0+3**.

## Platformlar

| Platform | Projedeki destek ve doğrulama durumu |
| --- | --- |
| Android | Flutter/Gradle uygulama hedefi mevcut. Son debug derlemesi klasör yolu denetimini geçti; disk alanı yetersizliği nedeniyle APK üretimi tamamlanmadı. |
| Web / Chrome | Dosya seçme, yerel kayıt, indirme, PNG önizleme ve profil fotoğrafı tarayıcıda doğrulandı. PDF'nin tarayıcı içinde gösterimi kullanılan PDF görüntüleyicisine bağlıdır. |
| macOS 12 ve üzeri | Swift/Xcode hedefi, Firebase seçenekleri, sandbox izinleri, Keychain Sharing ve CocoaPods yapılandırması mevcut. Native derleme ve cihaz kabulü Mac üzerinde yapılmalıdır. |
| iOS, Windows, Linux | Bu sürümde çalıştırılabilir uygulama hedefi olarak hazırlanmadı; Firebase seçenekleri de tanımlı değil. |

## Kullanılan teknolojiler

| Alan | Teknoloji | Kullanım |
| --- | --- | --- |
| Uygulama | Flutter 3.47.9, Dart 3.13.7 | Android, web ve macOS için ortak uygulama kodu |
| Arayüz | Material 3, flutter_localizations, cupertino_icons | Türkçe arayüz, açık/koyu/sistem teması, uyarlanabilir ekranlar |
| Durum yönetimi | provider | Oturum, notlar, favoriler, kategoriler ve tema |
| Mimari | Repository arayüzleri, AppDependencies, koşullu Dart import'ları | Veri kaynaklarının ve platform dosya işlemlerinin ayrılması |
| Firebase başlangıcı | firebase_core 5.1.0, FlutterFire CLI | Mevcut `not-paylasma-proje` yapılandırması |
| Kimlik doğrulama | firebase_auth 7.0.1 | E-posta/şifre ile kayıt, giriş/çıkış ve parola yenileme |
| Kullanıcı profili | cloud_firestore 7.1.0, Firestore Rules | Kullanıcının yalnızca kendi profil belgesine erişmesi |
| Yerel veri | JSON, dart:io, path_provider | Notlar, kategoriler, favoriler, tema ve yerel avatar eşlemeleri |
| Web dosya alanı | OPFS, Web Locks API, package:web 1.1.2, dart:js_interop | Tarayıcıda gerçek dosya kayıtları ve yazma kilidi |
| Eski kayıtların okunması | sembast 3.10.1, sembast_web 2.4.7 | Önceki yerel depodan veri geçişi; varsayılan aktif depo JSON'dur |
| Dosya seçme/kaydetme | file_picker 13.3.3 | PDF, DOCX, PNG ve JPEG seçimi, cihazda kaydetme diyaloğu |
| Dosya açma | open_filex 5.0.0, masaüstü sistem açıcıları | Mobilde uygun uygulama; macOS'ta `/usr/bin/open` |
| Dosya doğrulama | crypto 3.0.8, archive 4.6.0, Flutter görsel codec'i | SHA-256 bütünlüğü, DOCX yapısı, görsel çözümleme ve boyut sınırları |
| Kimlik üretimi | uuid 4.6.0 | Yerel not/dosya kimlikleri |
| Android araçları | Android SDK, Kotlin, Gradle / Android Gradle Plugin, JDK | Android uygulamasını derleme |
| macOS araçları | Swift, Xcode, Swift Package Manager, CocoaPods | macOS uygulaması ve native eklentiler |
| Kalite kontrolü | flutter_test, flutter_lints, Firebase Local Emulator Suite, Node.js testleri | Uygulama testleri, statik analiz ve güvenlik kuralları testleri |

`firebase_storage` 14.0.1 bağımlılığı ve eski bulut dosya servisi kaynaklarda korunur; **güncel uygulama Firebase Storage kullanmaz**. Kesin bağımlılık çözümü [pubspec.lock](pubspec.lock), doğrudan bağımlılıklar [pubspec.yaml](pubspec.yaml) içindedir.

## Veri nerede tutulur?

- **Firebase Auth:** kullanıcı hesabı ve oturum yönetimi.
- **Firestore `users/{uid}`:** uid, ad, soyad, e-posta ve oluşturma/güncelleme zamanları. Parola ve profil fotoğrafı burada saklanmaz.
- **Yerel JSON ve dosyalar:** notlar, favoriler, kategoriler, tema, ekler ve profil fotoğrafı. Aktif JSON'a kullanıcı profili, parola özeti veya oturum yazılmaz.

Web kayıtları tarayıcı profili ve adres/port başına ayrıdır. Aynı kayıtlara erişmek için aynı adres ve portu kullanın. Proje kaynaklarını başka bilgisayara kopyalamak tarayıcı kayıtlarını taşımaz. macOS kayıtları uygulamanın destek dizinindedir; başka cihazla kendiliğinden eşitlenmez.

Mevcut Firebase projesi **ücretsiz Spark planında**, faturalandırma kapalıdır. Firestore `(default)` veritabanı `europe-west1` konumundadır. Ücretli plan, bulut dosya depolaması, PITR veya ödeme hesabı gerekmez. Kullanım için Firebase CLI ile yeniden giriş/deploy yapmak gerekmez; mevcut istemci seçenekleri projededir.

## Özellikler

- Firebase ile kayıt, giriş, çıkış, parola yenileme ve profil düzenleme.
- Açılışta ve giriş sırasında yükleme ekranı.
- Not oluşturma, düzenleme, silme; kategori/etiket, arama, sıralama ve sayfalama.
- Kullanıcıya özel yerel favoriler ve not listeleri.
- PDF/DOCX/PNG/JPG/JPEG ekleri: dosya başına 20 MiB; profil fotoğrafı 5 MiB; görsellerde 24 MP sınırı.
- Görsel önizleme; PDF/DOCX için cihazdaki uygun uygulamayla açma; webde yerel indirme.
- Dosya bütünlük kontrolü, hata durumunda geri alma ve sekmeler arası eski kaydı ezme koruması.

Eski hesabı Firebase'e aktarma ve profilden JSON indirme butonları kullanıcı isteğiyle kaldırılmıştır. Mock repository'ler ve örnek hesaplar yalnızca eski altyapı/testler için kaynaklarda bulunur; normal giriş Firebase hesabı ister.

## Çalıştırma

Proje kökü `pubspec.yaml` dosyasının bulunduğu `notpaylasma` klasörüdür.

```bash
flutter pub get
flutter run -d chrome --web-port 8767
# Bağlı Android cihaz/emülatör için:
flutter devices
flutter run -d <cihaz-kimligi>
```

### Mac üzerinde

Flutter, tam Xcode ve CocoaPods kurulu olmalıdır. İlk Xcode açılışı/lisansı tamamlandıktan sonra proje kökünde:

```bash
bash scripts/macos.sh run
# Analiz, mevcut testler ve debug macOS derlemesi:
bash scripts/macos.sh check
# Release .app üretmek için:
bash scripts/macos.sh build
```

Manuel karşılığı: `flutter pub get` ardından `flutter run -d macos`. `main.dart` ve `main_firebase.dart` aynı Firebase hesap + yerel dosya düzenini kullanır. Xcode'da `macos/Runner.xcworkspace` açılır. Bundle ID `com.example.notpaylas` mevcut Firebase macOS kaydıyla eşleşir; kimlik değiştirilirse Firebase kaydı da güncellenmelidir. İmzalama/Keychain gereksinimleri için [macOS rehberini](docs/MACOS_KURULUM.md) okuyun.

## Doğrulama ve sınırlar

```bash
flutter analyze
flutter test
```

Windows için `scripts/verify.ps1` analiz/testleri ASCII geçici kopyada çalıştırır. Son ortak Dart doğrulamasında **60 uygulama testi**, ayrıca **7 emulator güvenlik testi** geçti. Bu sonuçlar macOS native derlemesinin veya gerçek hesapla uçtan uca kabulün yerine geçmez. macOS `.app`, Windows üzerinde üretilemez; bu ortamda Xcode derlemesi çalıştırılmadı.

Yerel dosyalar şifrelenmiş bulut yedeği değildir. Firebase hesabı başka cihazda kullanılabilir; not ve fotoğraflar cihazda kalır. Dağıtım imzası/notarizasyon ve mağaza yayını bu çalışmanın kapsamına dahil değildir.

## Belgeler

[macOS kurulumu](docs/MACOS_KURULUM.md) · [Güncel veri düzeni](docs/FIREBASE_HESAP_YEREL_DOSYALAR.md) · [Mimari](ARCHITECTURE.md) · [Veri modeli](DATABASE.md) · [Geliştirme günlüğü](DEVELOPMENT.md) · [Firebase](FIREBASE_SETUP.md) · [Görevler](TASKS.md) · [Eğitim soruları](docs/EGITIM_SORULARI_VE_CEVAPLARI.md)

Eski aşama belgeleri tarihsel kararlar içerir; güncel çalışma düzeni bu README ve güncel veri rehberidir.
