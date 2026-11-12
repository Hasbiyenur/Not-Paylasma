# Firebase kullanıcı hesabı, yerel notlar ve fotoğraflar

12 Kasım 2026 kullanıcı kararı: yalnızca kullanıcı hesabı ve profil bilgileri Firebase'de tutulur. Notlar, favoriler, dosyalar, tema ve profil fotoğrafı yereldedir. Hedef mevcut Firebase projesi `not-paylasma-proje`; yeni proje oluşturulmaz.

## Güncel başlangıç

Hem `lib/main.dart` hem `lib/main_firebase.dart`, `createHybridDependencies` kullanır. Firebase Auth e-posta/şifre hesabını; Firestore `users/{uid}` profilini saklar. Varsayılan uygulama Firebase Storage veya Firestore not repository'lerini oluşturmaz. Firebase modu başarısız olduğunda sessizce mock/yerel hesaba geçilmez.

Firebase profil alanları: uid, firstName, lastName, email, createdAt, updatedAt. Parola Firestore'a yazılmaz. Profil fotoğrafının baytları ve yolu da Firebase'e verilmez; eski Firestore photoUrl alanı giriş/profil güncellemesinde kaldırılır.

## Yerel veri

`data.json` şema 2'de notes, favorites, categories, theme ve localAvatars vardır. Kullanıcı profilleri, parola özetleri ve oturum alanı bu aktif JSON dosyasına yazılmaz. Notların yazar adı/uid bilgisi not metadata'sı olarak korunur. Firebase'den okunan aktif profil yalnızca uygulama belleğine alınır; Firestore kalıcı istemci önbelleği kapatılır. Firebase Auth kendi standart oturum saklamasını yönetir.

Ek ve fotoğraf baytları yerel `files/...` altındadır. Chrome'da adres/profil/port başına OPFS alanı, native'de uygulama destek dizini kullanılır. Kullanıcı başka cihazda hesabına girebilir; yerel not ve fotoğraflar kendiliğinden başka cihaza taşınmaz. JSON dışa aktarımı yalnızca yerel verileri içerir.

## Eski yerel hesabı aktarma

12 Kasım 2026 arayüz güncellemesi: kullanıcı isteğiyle giriş ekranındaki eski hesap aktarım butonu ve profildeki JSON indirme butonu kaldırıldı. Aşağıdaki aktarım açıklaması önceki akışın teknik kaydıdır; mevcut arayüzde bu işlem sunulmaz. Eski yerel kayıtlar bu değişiklikle silinmez. Açılış ve giriş sırasında yükleme ekranı gösterilir.

İlk şema geçişinde eski hesap kayıtları, mevcut notları kaybetmeden aktarabilmek için geçici `legacy-accounts.json` belgesinde korunur. Bu dosya yeni kullanıcılar için bir profil deposu değildir. Daha eski JSON/Sembast ve yedek dosyaları veri güvenliği için topluca silinmez.

Giriş ekranında eski yerel e-posta ve şifre girilip **Eski yerel hesabımı Firebase’e aktar** seçilir. Yerel parola doğrulanmadan Firebase hesabı oluşturulmaz. Firebase hesabı zaten varsa aynı bilgilerle giriş yapılır. Firebase profili doğrulanınca yerel not sahipliği, favoriler ve yerel fotoğraf eşlemesi yeni Firebase uid'sine taşınır. O hesabın geçici geçiş bilgileri kaldırılır; aktarılamayan diğer eski hesaplar korunur.

Eski parola özetleri Firebase'e parola olarak gönderilemez; bu nedenle her hesap sahibi bu açık aktarım adımını kendi parolasıyla tamamlar. Hesap parolası sohbete yazılmaz.

## Güvenlik kuralları

`firestore.rules` yalnızca oturum açan kullanıcının kendi users belgesine erişmesine izin verir; tür, alan, e-posta ve oluşturma zamanı korunur. Fotoğraf/parola/ek alanlar, not/kategori/favori/temizlik koleksiyonları reddedilir. `storage.rules` tüm istemci bulut dosyası işlemlerini reddeder; bu modda Storage kurulumu gerekmez.

Kurallar yerel emulator'da doğrulandı. Kullanıcı ücretsiz `(default)` Standart Firestore veritabanının `europe-west1` (Belçika) konumunda oluşturulmasını açıkça onayladı. Authentication Email/Password sağlayıcısı etkinleştirildi.

### Yalnızca ücretsiz plan

12 Kasım 2026'da mevcut projenin Cloud Billing kontrolü `billingEnabled: false`, Authentication türü `FIREBASE_AUTH` döndürdü. Ücretli Blaze planına geçilmez; faturalandırma hesabı bağlanmaz. PITR, ücretli yedekleme, Cloud Functions ve bulut dosya depolaması kurulmaz. Ücretsiz kota yetmediğinde ödeme açmak yerine işlem durdurulur.

Oluşturma öncesi projede hiç Firestore veritabanı olmadığı doğrulandı. Yalnızca ilk ücretsiz `(default)` veritabanı hedeflenir. Gerçek kullanıcı kaydı ve giriş kabulü uygulama sahibinin hesabıyla ayrıca yapılır; otomatik olarak canlı test kullanıcısı oluşturulmaz.

Kurulum tamamlandı: `not-paylasma-proje/(default)`, Standart/Native, `europe-west1`; PITR kapalı. `firebase deploy --only firestore:rules` başarılı oldu. Kurulum sonrası tekrar `billingEnabled: false` doğrulandı. 60 uygulama testi, 7 emulator güvenlik testi, analiz ve web derlemesi geçti; lib/test/assets dosyaları test edilen kopyayla birebir eşleşti. Gerçek hesapla uçtan uca giriş/kayıt henüz doğrulanmadı.

## Çalıştırma ve doğrulama

```powershell
flutter pub get
flutter run -d chrome --web-port 8767
./scripts/verify.ps1 -BuildWeb
npm --prefix scripts/firebase-tests ci
./scripts/test-firebase.ps1
```

Yeni hesap kaydı/giriş, profil adını değiştirme, e-posta ile parola yenileme ve çıkış Firebase hesabıyla çalışır. Fotoğraf seçme/kaydetme/gösterme, PDF/PNG not oluşturma ve indirme yerel dosyaları kullanır. Canlı kullanıcı parolaları otomatik teste verilmez; emulator veya test çiftleriyle kontrol edilir.

## Dosya düzeltmeleri

PDF doğrulamasındaki Uint8List.sublist çağrısına bitiş sınırı açıkça verildi; Dart debug web uygulamasındaki null kontrol hatası giderildi. PNG/JPEG boyut kontrolünde web'de desteklenmeyen ImageDescriptor.width yerine gerçek codec/frame çözümlemesi kullanılır. Başlıktaki boyutlar çözümlemeden önce 24 MP sınırıyla denetlenir. Görseller Flutter motoruna salt okunur sarmalayıcı yerine bağımsız typed-array kopyasıyla verilir. Boyut ve içerik denetimleri korunur.

PDF seçme/kaydetme, PNG seçme/kaydetme/uygulama içi görüntüleme ve PNG profil fotoğrafı seçme/kaydetme/gösterme debug tarayıcısında gerçek dosyalarla doğrulandı.
