# Yerel JSON kayıt ve dosya işlemleri

12 Kasım 2026 güncellemesi: kullanıcı hesabı/profili Firebase Auth ve Firestore'da, profil fotoğrafı ve not/dosyalar yereldedir. Yalnızca ücretsiz plan kullanılır. Aşağıdaki eski başlangıç tariflerinden önce [güncel düzeni](FIREBASE_HESAP_YEREL_DOSYALAR.md) okuyun.


11 Kasım 2026 kullanıcı kararı: `lib/main.dart` ve eski `lib/main_firebase.dart` komutu artık aynı yerel JSON başlangıcını açar. Bu başlangıç Firebase başlatmaz ve mock repository oluşturmaz. Eski kodlar önceki çalışmalar ve testler için korunur.

## Kayıtların yeri

- `assets/data/initial_data.json`: önceki başlangıçtaki 2 hesap, 4 kategori ve 26 notun statik JSON karşılığı. Yalnızca kayıt olmayan kurulumda kullanılır; mevcut kayıtları ezmez.
- Chrome: aynı adres/port için Origin Private File System içinde `notpaylas_json/data.json`. Yeni kayıtlar IndexedDB/Firestore'a yazılmaz; tarayıcıdaki gerçek JSON dosyasına yazılır. Tarayıcı proje klasörüne kendiliğinden yazamaz.
- Android/macOS: uygulama destek dizininde `notpaylas_json/data.json`.
- Ek ve avatar baytları `files/notes/...` ve `files/avatars/...` altında ayrı dosyalardır. Yanlarındaki `.meta.json` ad, boyut ve SHA-256 içerir; dosyalar JSON içine base64 olarak gömülmez.
- Her metadata yazımında önceki JSON `data.backup.json` olarak korunur. Bozuk kayıt sessizce silinmez veya başlangıç verisiyle değiştirilmez.

Hesaplar, parola özetleri, notlar, kategoriler, favoriler, sayaçlar, oturum ve tema JSON'dadır. Çıkış yalnızca aktif oturumu kapatır; kayıtlar ve dosyalar kalır. Şifreler açık metin tutulmaz. Yerel hesap sistemi cihaz/site dosyalarına erişebilen kişiye karşı uzak sunucu yetkilendirmesi sağlamaz.

## Eski kayıtların aktarılması

JSON henüz yoksa eski yerel depo bir kere okunur; hesap/not/favori/profil/tema/oturum ve referanslı bütün dosyalar taşınır. Kaynak depo silinmez ve `legacy-import.json` yedeği saklanır. Bir ek eksik veya bozuksa geçiş iptal olur; mevcut bilgiler korunur. Sonraki açılışlar JSON'dan okur; eski depoya yazılmaz.

Aktarım **aynı Chrome profili, adres ve portta ilk açılışta** gerçekleşir. `localhost:8767`, `127.0.0.1:8767` ve başka portlar ayrı alanlardır. Gizli pencere veya site verilerini silmek kalıcılığı etkiler. Bu çalışma gerçek Firebase hesabına erişmedi; buluttaki kayıtlar otomatik aktarılmış sayılmaz.

## Dosya seçme, indirme ve açma

PDF/DOCX/JPEG/PNG seçme ve içerik kontrolleri korunur. Ek ayrı yerel dosyaya, yol ve bilgiler JSON'a yazılır. Chrome'da **İndir** Blob/download bağlantısıyla bilgisayarın indirme klasörüne veya tarayıcının belirlediği konuma dosya gönderir; veritabanına yazma değildir. Sayfa indirme başlangıcını bildirir, diske yazımın tamamlandığını ölçemez.

PDF uygulama içindeki iframe önizleme ekranına alınır; popup gerekmez. Görseller uygulamada gösterilir. Chrome masaüstü Word'ü doğrudan açamaz; DOCX için **İndir ve uygulamayla aç** indirmeyi başlatır. Dosya Chrome indirmelerinden uygun uygulamayla açılır. Native masaüstünde geçici dosya sistemin dosya açma komutuna verilir.

Profilde **Bilgileri JSON olarak indir**, hesap ve not bilgilerini okunabilir JSON'a aktarır. Parola özetleri ve ek dosyası baytları bu dışa aktarımda bulunmaz; tam geri yükleme arşivi değildir. Asıl `data.json` tüm yerel durumun kaydıdır. Dışa aktarım cihazdaki diğer yerel kullanıcıların bilgilerini de içerir.

## Çalıştırma

Eski Flutter çalıştırmasını durdurup yeni asset kayıtlarını almak için:

```powershell
flutter pub get
flutter run -d chrome --web-port 8767
```

Eski kayıtların bulunduğu aynı adres ve portu kullanın. Firebase configure bu mod için gerekmez. Firebase options dosyası bulunsa bile her iki başlangıç JSON kullanır.

## Doğrulama

Debug açılış hatası da düzeltildi: SelectedFile'ın salt okunur baytları, JS dosya API'sine geçerken `toWebFileBytes` ile typed-array kopyasına çevrilir. Debug'da yeniden üretilen açılış hatası sonrasında aynı sürümde açılış, tam yenileme, giriş, liste ve gerçek PDF indirmesi geçti. Bu düzeltme mevcut JSON veya eski depoyu temizlemeyi gerektirmez. Eski çalışan Flutter süreci tamamen durdurulup yeniden başlatılmalıdır.

Son sonuç: analiz temiz, 52 uygulama testi ve web derlemesi başarılı. Gerçek tarayıcı etkileşiminde DOCX seçme/yükleme, çıkış/giriş ve yenileme sonrası kayıt, PDF/DOCX yerele indirme ve JSON indirme geçti; indirilen eklerin SHA-256 değerleri kaynakla eşleşti. Headless Chrome testi suite başlangıcında beklediği için başarılı sayılmadı. PDF iframe'in doğru blob'a bağlandığı doğrulandı; kullanılan uygulama içi tarayıcı PDF motorunu göstermedi, normal Chrome'da PDF render kontrolü açık. Yeni JSON modu kullanıcı profilindeki ilk açılışa kadar gerçek eski tarayıcı verilerini kendiliğinden buradaki test profiline taşımaz.

Gerçek dosyalarla JSON kalıcılığı, çıkış/giriş ve kapat/aç, profil/tema/favori, dosya değiştirme/silme, eski depo aktarımı, başka pencerenin kaydını ezmeme ve bozuk JSON'u koruma testleri eklendi. Chrome OPFS testi `test/browser/json_browser_test.dart` içinde; `scripts/verify.ps1 -BrowserTests` ile çalıştırılır. Test eklenmiş olması gerçek tarayıcı kabulünün geçtiği anlamına gelmez; son sonuç geliştirme günlüğünde kaydedilir.

Tarayıcı dosya alanının kapsamı ve silinme davranışı: [OPFS belgesi](https://developer.mozilla.org/en-US/docs/Web/API/File_System_API/Origin_private_file_system).
