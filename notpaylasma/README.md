# NotPaylaş

## Güncel düzen — Firebase hesabı, yerel dosyalar

12 Kasım 2026: yalnızca kullanıcı hesabı/profili Firebase Auth/Firestore'dadır. Profil fotoğrafı, notlar, favoriler ve ekler yerel JSON/dosya alanında kalır. Hem main.dart hem main_firebase.dart bu başlangıcı açar. Eski yerel hesaplar girişte açık aktarım adımıyla Firebase'e taşınır. [Güncel kurulum ve veri düzeni](docs/FIREBASE_HESAP_YEREL_DOSYALAR.md). Aşağıdaki önceki modlar tarihçedir.

## Güncel çalışma modu — Yerel JSON

11 Kasım 2026: hesap/not/favori/profil/tema ve sonraki değişiklikler yerel JSON dosyasına, ekler ayrı yerel dosyalara kaydedilir. Varsayılan başlangıç mock/Firebase kullanmaz. Eski yerel kayıtlar aynı adres/portta ilk açılışta dosyalarıyla aktarılır; kaynak silinmez. Chrome indirmesi bilgisayara dosya indirir. [Yerel JSON kayıtları ve çalıştırma](docs/YEREL_JSON_KAYIT.md). Aşağıdaki mock/Firebase bölümleri önceki geliştirme durumlarını anlatır; güncel varsayılan mod bu bölümdür.

macOS platform dosyaları da eklendi. Geliştirme bundle ID: `com.example.notpaylas`. Mac üzerinde çalıştırma ve Firebase adımları: [macOS kurulumu](docs/MACOS_KURULUM.md). macOS derleme/cihaz kabulü henüz yapılmadı.

Türkçe arayüzlü Flutter/Dart mobil not paylaşım uygulaması. Android öncelikli; web geliştirme önizlemesi bulunur. Sürüm: **0.3.0+3**.

## Güncel durum — Aşama 4

Firebase olmadan çalışan uygulama özellikleri ve kalıcı mock depo uygulandı. **Hesaplar, notlar, dosyalar, favoriler, aktif demo oturumu ve tema yeniden açılışta korunur.** Normal başlangıç kalıcı moddur; bağımsız testler için bellek modu da korunur.

Cihazda uygulama destek dizinindeki `notpaylas_mock.db`, webde aynı adres/origin için IndexedDB `notpaylas_mock` kullanılır. Tarayıcı/uygulama verilerini silmek kayıtları kaldırır; başka tarayıcı, profil, alan adı veya port ayrı depodur. Tarayıcı kota/temizleme politikaları nedeniyle bu kayıt bulut yedeği değildir.

## Çalışan özellikler

- Kayıt/giriş/çıkış, demo şifre sıfırlama, profil ve fotoğraf düzenleme.
- İki demo hesap, dört kategori ve ilk açılışta 26 not; gerçek PDF/DOCX/PNG örnek ekleri.
- Beş sekme, oturum değişiminde eski ekranları kaldırma, detay/düzenleme/geri akışları.
- Not oluşturma/düzenleme/silme; yalnızca sahibinin değiştirebilmesi.
- Başlık/ders kelime öneki araması, kategori/etiket, sıralama ve 10'lu sayfalama.
- Kullanıcıya özel favoriler, son/popüler/en çok indirilen notlar.
- PDF/DOCX/JPG/JPEG/PNG dosya seçimi; ek başına 20 MiB, avatar için 5 MiB.
- Dosya türü/imza kontrolü; DOCX yapı denetimi; görsel okunabilirlik/piksel sınırı.
- Görseli uygulama içinde, PDF'yi cihaz/tarayıcı görüntüleyicisinde açma. Webde DOCX indirilir.
- Gerçek dışa aktarma: iptalde sayaç artmaz. Web sayacı tarayıcıya iletilen isteği sayar; diske yazılmanın tamamlandığını ölçmez.
- Material 3, Türkçe yerelleştirme, açık/koyu/sistem teması ve durum görünümleri.

## Kalıcı mock davranışı

Metadata yazımı beklenir; hata olursa bellek geri alınır ve başarı bildirimi verilmez. Yeni ek kaydedilmeden eski dosya kaldırılmaz. Dosya kayıtlarında SHA-256 bütünlük denetimi vardır. Başarısız temizlik veya yarım yüklemeden kalan sahipsiz ekler, 24 saat geçtikten sonraki açılışta temizlenir. Bozuk/eksik/bilinmeyen sürümlü kayıtlar otomatik silinmez; açılış hatası gösterilir.

Demo dosya alanı toplam **64 MiB ham bayt** ile sınırlıdır; depodaki base64 ve metadata alanı bunun üzerindedir. Büyük ekler yüklenirken bellek kullanımı artabilir. Kalıcı adapter ilerlemeyi işlem başlangıcı/başarılı dosya kaydı olarak 0→1 bildirir; ağ yükleme hızı göstermez.

Başka pencere metadata'yı değiştirmişse eski pencerenin yazması reddedilir ve yenileme istenir. Canlı çoklu pencere eşitlemesi yoktur. Sıfırlama kodları yeniden açılışta geçersizleşir; demo şifre sıfırlama e-posta göndermez. Yerel depo şifrelenmiş değildir; yalnızca sentetik eğitim verileri ve demo şifreleri kullanın.

## Demo hesaplar

| E-posta | İlk kurulum şifresi |
| --- | --- |
| ayse@example.com | NotPaylas123! |
| mehmet@example.com | NotPaylas123! |

Yeni kayıtlar ve değiştirilen şifreler artık kalıcıdır. “Ayşe ile demo girişi” başlangıç şifresini kullanır; değiştirdiyseniz kendi yeni demo şifrenizle giriş yapın.

## Aşama sırası

1. Analiz/hazırlık — tamamlandı.
2. Arayüz/temel yapı — uygulandı; Android cihaz açılışı açık.
3. Uygulama özellikleri — mock kodu ve otomatik testleri tamamlandı.
4. Mock kalıcılık ve testler — kalıcılık uygulandı; güncel kabul durumu [TASKS.md](TASKS.md) içinde, Android kabulü açık.
5. Firebase Auth/Firestore/Storage kodu ve güvenlik dosyaları eklendi; gerçek proje/Android kabulü bekliyor.
6. Gerçek Firebase ile final testleri, düzeltmeler ve debug/release APK — bekliyor.

Dört mock repository korunur. Firebase geçişi repository/dosya servisi implementasyonları ve AppDependencies bağlantısından yapılır. Firebase paketi, hesabı veya yapılandırması mevcut açılış için gerekmez.

## Çalıştırma ve doğrulama

```powershell
flutter pub get
flutter run -d chrome --web-port 8767
flutter test
./scripts/verify.ps1 -BuildWeb
```

Betik, Türkçe proje yolunda görülen analiz aracı hatası için aynı kaynakları ASCII geçici dizinde doğrular. Mevcut analiz temiz ve 47 otomatik test geçti. Disk testleri gerçek geçici dosyada kapat/aç yapar; Android cihaz testi olarak sunulmaz. Web derlemesi ve tarayıcı kabulünün son sonucu TASKS.md'dedir.

## Bağımlılıklar

Flutter 3.47.9 / Dart 3.13.7; provider 6.1.5+1, cupertino_icons 1.0.9, file_picker 13.3.3, open_filex 5.0.0, path_provider 2.1.6, uuid 4.6.0, crypto 3.0.8, archive 4.6.0, web 1.1.2. Aşama 4: **sembast 3.10.1, sembast_web 2.4.7**; dolaylı idb_shim 2.11.3, synchronized 3.6.1+1. flutter_localizations/flutter_test SDK'dan, flutter_lints 6.0.0; kesin çözüm pubspec.lock içindedir.

## Açık kontroller

Android command-line tools eksik, uygun JDK/SDK lisansları ve bağlı hedef doğrulaması gerekli. Android dosya seçme/açma/kaydetme henüz cihazda sınanmadı. APK üretimi 6. aşamadadır. Launcher ikonları şablondur. Otomatik yedek/geri yükleme ve yerel şifreleme yoktur. Firebase kurallarının yerel emulator testleri geçti; gerçek backend ve cihazlar arası senkronizasyon kabulü hedef bilgisayarda yapılacak.

## Belgeler

[Plan](PROJECT_PLAN.md) · [Görevler](TASKS.md) · [Mimari](ARCHITECTURE.md) · [Veri modeli](DATABASE.md) · [Geliştirme günlüğü](DEVELOPMENT.md) · [Firebase](FIREBASE_SETUP.md) · [Referans incelemesi](docs/REFERENCE_REVIEW.md) · [30 klasik soru ve cevap](docs/EGITIM_SORULARI_VE_CEVAPLARI.md)

Her önemli değişiklik ilgili Markdown belgelerine kaydedilir.


## Güncel durum — Aşama 5 hazırlığı

11 Kasım 2026: Firebase Auth/Firestore repository'leri, Firebase Storage servisi ve AppDependencies bağlantısı eklendi. Ayrı Firebase açılışı lib/main_firebase.dart; varsayılan lib/main.dart kalıcı mock olarak korunur. firebase.json, firestore.rules, storage.rules ve firestore.indexes.json eklendi. Yerel demo-notpaylas emulator'larında 16/16 güvenlik testi geçti; gerçek hesaba giriş, proje oluşturma veya deploy yapılmadı.

Bekleyenler: uygulama sahibinin bilgisayarında flutterfire configure ile gerçek options üretimi, test projesine kurallar/indekslerin uygulanması, kategorilerin yetkili olarak eklenmesi, gerçek repository ve Android/ağ kesintisi kabulü. Aşama 5 canlı bağlantı kabulü ve 6. aşama APK teslimi tamamlanmış değildir. Kurulum komutları ve bilinen sınırlar FIREBASE_SETUP.md içindedir.

Yeni rehber: [Başka bilgisayarda kurulum](docs/BASKA_BILGISAYARDA_KURULUM.md).
