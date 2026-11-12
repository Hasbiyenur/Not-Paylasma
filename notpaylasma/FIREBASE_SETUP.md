# Firebase kurulumu — Aşama 5

12 Kasım 2026 güncellemesi: kullanıcı hesabı/profili Firebase Auth ve Firestore'da, profil fotoğrafı ve not/dosyalar yereldedir. Yalnızca ücretsiz plan kullanılır. Aşağıdaki eski başlangıç tariflerinden önce [güncel düzeni](docs/FIREBASE_HESAP_YEREL_DOSYALAR.md) okuyun.


Güncel karar: Firebase yalnızca kullanıcı hesabı/profili içindir. Dosya/fotoğraf/notlar yereldir; her iki main başlangıcı hybrid modu kullanır. Yeni Firestore/Storage kuralları bu ayrımı zorunlu tutar. Önceki tam bulut veya tamamen yerel tarifler tarihçedir. [Güncel düzen](docs/FIREBASE_HESAP_YEREL_DOSYALAR.md).

Güncel kullanıcı kararı: varsayılan uygulama artık yerel JSON'dur. `main_firebase.dart` da eski çalıştırma komutlarını bozmamak için yerel JSON'a yönlendirir. Aşağıdaki Firebase kurulumu geçmiş/isteğe bağlı altyapı belgesidir; bu komutlarla varsayılan başlangıç bulut moduna geçmez. Güncel kullanım: docs/YEREL_JSON_KAYIT.md.

11 Kasım 2026: Firebase dosyaları eklendi. Bu bilgisayarda gerçek hesaba giriş, proje oluşturma veya deploy yapılmadı. Gerçek bağlantı ve Android kabulü uygulama sahibinin bilgisayarında yapılacak.

## Eklenen dosyalar

- `lib/repositories/firebase/`: Auth, not, favori, kategori repository'leri ve oturuma göre dinleyici yönetimi.
- `lib/core/services/firebase_dependencies.dart`: Firebase Core/Auth/Firestore/Storage ile AppDependencies bağlantısı.
- `lib/main_firebase.dart`: ayrı Firebase açılışı. `lib/main.dart` kalıcı mock olarak korunur.
- `lib/firebase_options.dart`: yalnızca açıklayıcı hata veren yer tutucu; sahte anahtar içermez. FlutterFire tarafından hedef bilgisayarda değiştirilir.
- `firebase.json`, `firestore.rules`, `storage.rules`, `firestore.indexes.json`: emulator, güvenlik ve sorgu indeksleri.
- `scripts/firebase-tests/` ve `scripts/test-firebase.ps1`: gerçek hesap gerektirmeyen yerel güvenlik testleri.

Firebase modunda demo hesap kısayolu gösterilmez. Şifre yenileme Firebase'in e-posta bağlantısıyla yapılır; mock sıfırlama kodu akışı korunur. Firebase başlangıcı başarısızsa sessizce mock'a dönülmez.

## Hedef bilgisayarda gerçek bağlantı

1. Kalıcı Android applicationId belirlenir; `com.example.notpaylas` dağıtım kimliği değildir.
2. Sahibi kendi hesabıyla test projesini seçer/oluşturur. Firebase CLI ve FlutterFire CLI kurulur.
3. Proje kökünde aşağıdaki komutlar çalıştırılır. `flutterfire configure`, yer tutucu `lib/firebase_options.dart` dosyasını gerçek yapılandırmayla değiştirmelidir.

```powershell
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Authentication Email/Password sağlayıcısı, parola politikası ve yenileme e-postası ayarlanır.
5. Firestore ve Storage konumları, faturalandırma ve bütçe uyarıları sahibi tarafından seçilir. Herkese açık test kuralları kullanılmaz.
6. Yerel testler geçtikten sonra aşağıdaki komutta GERCEK_TEST_PROJE_ID yerine seçilen test projesi yazılır. Bu komut burada çalıştırılmadı.

```powershell
firebase deploy --only firestore:rules,firestore:indexes,storage --project GERCEK_TEST_PROJE_ID
```

Storage kuralları Firestore metadata'sını okur; dağıtımda Console/CLI tarafından istenen servis izinleri aynı test projesinde tamamlanır. İndekslerin hazır olması beklenir.

7. Console veya yetkili Admin SDK ile `categories/{id}` belgeleri eklenir. Her belge `name` ve `description` metin alanlarını içerir. Örnek kimlikler: `yazilim`, `matematik`, `fizik`, `dil`. Normal istemciler kategori yazamaz; kategoriler olmadan not oluşturulamaz.
8. Firebase açılışı açıkça seçilir:

```powershell
flutter pub get
flutter run -t lib/main_firebase.dart -d chrome --web-port 8767
# Normal mock açılışı:
flutter run -t lib/main.dart -d chrome --web-port 8767
```

Yalnızca configure çalıştırmak varsayılan mock başlangıcını değiştirmez. Android'de gerçek kullanıcı, kayıt/giriş/çıkış, parola e-postası, profil/avatar, not CRUD, indirme, favori, yetkisiz erişim ve ağ kesintisi ayrıca kabul edilir. APK ve release imzası 6. aşamada; anahtar sahibinde saklanır.

## Yerel doğrulama

Node.js, Firebase CLI ve emulator için uygun Java gerekir. Betik varsa Android Studio'nun JBR dizinini kullanır; alternatif: `./scripts/test-firebase.ps1 -JavaHome 'C:/Java/jdk-21'`.

```powershell
npm --prefix scripts/firebase-tests ci
./scripts/test-firebase.ps1
./scripts/verify.ps1 -BuildWeb -BuildFirebaseWeb
```

Testler yalnızca `demo-notpaylas` ve localhost Firestore/Storage emulator'larına gider. Gerçek oturum açılmaz veya deploy yapılmaz. Emulator önbelleği `.firebase/`, npm bağımlılıkları `node_modules/` içinde kalır ve aktarıma eklenmez. Node 20.14 ile root hook sırası sorunu yaşanmaması için kurallar testleri bir test suite içinde çalışır.

## Veri ve güvenlik davranışı

- Firestore tarihleri server timestamp'tir; model katmanına UTC olarak çevrilir. Şifre yalnızca Firebase Auth'a gider.
- Profiller ve favoriler kullanıcıya özeldir. Notlar ve kategoriler oturum açmış kullanıcılara açıktır.
- Sahiplik/oluşturma zamanı değiştirilemez; alanlar, türler, boyutlar ve kategori doğrulanır.
- İndirme sayacı yalnızca +1 değişebilir. Favori sayacı favori belgesiyle aynı transaction'da doğrulanır.
- Silinmiş notun favori belgesi sahibince kaldırılabilir; diğer kullanıcıların alt koleksiyonları istemciden topluca silinmez.
- Storage notları en fazla 20 MiB; avatarlar en fazla 5 MiB. Avatar yalnızca JPEG/PNG; not PDF/DOCX/JPEG/PNG olabilir.
- Her yükleme yeni bir UUID kullanır. Üzerine yazma ve listeleme kapalıdır. Yayınlanmamış veya eski ekleri yalnızca sahibi okuyabilir; yayınlanan ek metadata yoluyla eşleşmelidir.
- Kalıcı download token URL'leri erişim denetimi olarak kullanılmaz; dosya SDK ile okunur.
- Not değişiminde eski dosya ve not silmede ek dosya temizliği, metadata ile aynı Firestore transaction'ında `users/{uid}/fileCleanup` kuyruğuna yazılır. Hatalar sonraki kaydetme/silmede yeniden denenir.

## Kabul sınırları

11 Kasım 2026 yerel doğrulama: analiz temiz; 48/48 Flutter testi ve 16/16 Firestore/Storage güvenlik testi geçti. Firebase ayarı eksikken hata ekranı ve tekrar deneme doğrulandı; mock moda geçilmedi. Test edilen lib/test kaynakları proje kaynaklarıyla hash olarak eşleşti. Mock ve Firebase başlangıçlarının web derlemeleri geçti. Canlı Firebase veya Android sonucu olarak sunulmaz.

Yerel güvenlik testleri gerçek cihaz veya canlı Firebase repository kabulünün yerine geçmez. Başlık/ders kelime öneki araması sunucudaki filtrelenmiş sayfaları istemcide tarar; büyük veri kümesinde ayrı arama servisi gerekir. Not değişim dinleyicisi koleksiyonu izler; üretim ölçeğinde okuma maliyeti için daraltılmalıdır. Sıralama sayaçları sayfalar arasında değişirse liste yenilenmelidir.

Firestore ve Storage ortak transaction sunmaz. Yükleme başarılı olup metadata commit'i başarısız/belirsiz kalırsa yeni dosya otomatik silinmez; referanslı dosya kaybı önlenir, sahipsiz yükleme için yetkili temizlik işi gerekir. Avatarların başarısız temizliği için de üretim temizlik işi gerekir. Firebase modunda tema seçimi henüz kalıcı değildir. İndirme sayacı istatistiktir; istemci kötüye kullanımına karşı kota/tekilleştirme sağlamaz. Storage kuralları MIME ve boyutu denetler; zararlı dosya taraması sunucu tarafında ayrıca ele alınır.

Hesap şifresi, service account JSON'u veya imza parolası sohbete/repoya konmaz. İstemci options dosyası yönetici yetkisi sağlamaz.

Resmî kaynaklar: [Flutter kurulumu](https://firebase.google.com/docs/flutter/setup), [Firestore kuralları](https://firebase.google.com/docs/firestore/security/rules-conditions), [Storage kuralları](https://firebase.google.com/docs/storage/security/rules-conditions).
