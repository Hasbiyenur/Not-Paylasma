# Başka bilgisayarda kurulum ve Firebase bağlantısı

12 Kasım 2026 güncellemesi: kullanıcı hesabı/profili Firebase Auth ve Firestore'da, profil fotoğrafı ve not/dosyalar yereldedir. Yalnızca ücretsiz plan kullanılır. Aşağıdaki eski başlangıç tariflerinden önce [güncel düzeni](FIREBASE_HESAP_YEREL_DOSYALAR.md) okuyun.


Güncel değişiklik: varsayılan uygulama yerel JSON'a geçirildi. Eski Firebase/mock hazırlığı aşağıda tarihçe olarak korunur. Aktarım ve kalıcılık için önce [Yerel JSON kayıtlarını](YEREL_JSON_KAYIT.md) okuyun; Chrome site dosyaları kaynak proje kopyalanınca başka bilgisayara taşınmaz.

11 Kasım 2026 kullanıcı kararı: gerçek Firebase hesabı ve proje bağlantısı uygulama sahibinin bilgisayarında yapılacak. Bu bilgisayarda Firebase hesabına giriş yapılmaz veya gerçek proje oluşturulmaz.

## Teslim durumu

Bu rehber hazırlık rehberidir; henüz final teslim paketi değildir. Kalıcı mock mod korunur. Firebase paketleri, Auth/Firestore repository bağlantıları, Storage servisi, rules/index ve ayrı lib/main_firebase.dart başlangıcı eklendi; yerel emulator güvenlik testleri 16/16 geçti. Gerçek options üretimi ve canlı Firebase/Android kabulü hedef bilgisayarda yapılacak. Yalnızca flutterfire configure çalıştırmak varsayılan mock başlangıcını değiştirmez; Firebase için flutter run -t lib/main_firebase.dart kullanılır.

## Dosyaları aktarma

Proje kaynakları, android, web, assets, test, scripts, pubspec.yaml, pubspec.lock, firebase.json, firestore.rules, storage.rules, firestore.indexes.json ve Markdown belgeleri birlikte aktarılır. build, .dart_tool, .firebase, node_modules, android/local.properties, yerel demo veritabanları ve kişisel anahtarlar taşınmaz. Hedef klasör için C:/Projects/notpaylas gibi Türkçe karakter içermeyen bir yol tercih edilir. Demo veriler yeni bilgisayarda ilk açılışta yeniden oluşturulur; mevcut tarayıcı kayıtları kaynak dosyalarıyla taşınmaz.

## İlk kontrol

Flutter/Dart ve Android Studio/SDK kurulur. Android SDK command-line tools, uygun JDK ve lisanslar tamamlanır. Bağlı cihaz veya emülatör hazırlanır.

```powershell
flutter doctor -v
flutter pub get
flutter test
flutter run -d chrome --web-port 8767
```

Önce mock giriş, dosya seçme, not oluşturma ve sayfayı yenileyince kaydın korunması doğrulanır.

## Gerçek Firebase hazırlığı — uygulama sahibinin bilgisayarında

1. Kendi Google hesabıyla Firebase Console'a giriş yapar; test projesini seçer/oluşturur.
2. Kalıcı Android applicationId belirlenir; geçici com.example.notpaylas dağıtım kimliği olarak kabul edilmez.
3. Firebase CLI ve FlutterFire CLI kurulur; kendi hesabıyla oturum açar.
4. Proje klasöründe flutterfire configure çalıştırır. Gerçek firebase_options.dart burada üretilir; elle sahte değer yazılmaz.
5. Authentication e-posta/şifre sağlayıcısı açılır. Firestore/Storage bölgesi ve gereken faturalandırma kendi hesabında seçilir.
6. Mevcut rules/index dosyaları yerel emulator testleri yeniden geçtikten sonra seçili test projesine uygulanır. Herkese açık kurallar kullanılmaz. categories koleksiyonu yetkili olarak doldurulur; ayrıntılar [Firebase kurulumunda](../FIREBASE_SETUP.md).
7. Firebase başlangıcı gerçek options ile flutter run -t lib/main_firebase.dart üzerinden açılır. Mock için lib/main.dart kullanılır.
8. Gerçek kullanıcı, not yükleme/indirme, favori, profil, yetkisiz erişim ve ağ kesintisi test edilir.
9. Ancak bu kabulden sonra 6. aşamada debug ve release APK üretilir. Release anahtarı uygulama sahibinde saklanır.

```powershell
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Bu komutlar burada çalıştırılmadı. Hesap şifresi, service account JSON'u veya imzalama parolası sohbetle paylaşılmaz. Firebase istemci options dosyası yönetici yetkisi sağlamaz; güvenlik rules ile uygulanır.

Resmî rehber: [Flutter için Firebase kurulumu](https://firebase.google.com/docs/flutter/setup). Bağlantı ve gerçek cihaz sonuçları hedef bilgisayarda kaydedilecek; burada başarılı oldukları iddia edilmez.

