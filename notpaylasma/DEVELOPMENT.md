# Geliştirme ortamı ve doğrulama

12 Kasım 2026 — Commit edilmiş Google API Key uyarısı için kaynak düzeltmesi: üç gerçek Firebase istemci anahtarı .local/firebase-keys.json içine yerelde korunarak taşındı; izlenen lib/firebase_options.dart artık String.fromEnvironment kullanır. Android google-services.json diskte korunarak yalnızca Git indeksinden çıkarıldı; anahtarsız google-services.example.json eklendi. .local ve gerçek native yapılandırmalar gitignore'a alındı. Yerel hazırlama, Windows çalıştırma, Mac ve doğrulama betikleri dart-define-from-file düzenine bağlandı. Yeni klon/IDE kurulumu ve eski GitHub uyarılarının ayrıca kapatılması SECURITY.md içinde belgelendi. Git geçmişi yeniden yazılmadı; kullanıcı adına commit/push, anahtar iptali/yenilemesi veya bulut API kısıtı değişikliği yapılmadı. GitHub uyarıları kapatılmadı; yetkili oturum bulunmuyor.

Doğrulama: 61 uygulama testi geçti, analiz temiz, yerel anahtar dosyasıyla web derlemesi başarılı. Derlenen web paketinin yerel web anahtarını aldığı ve kaynakta gerçek anahtar sabiti kalmadığı değerleri gizlenerek doğrulandı. Güncel kaynak taraması geçti. Sentetik, geçici kurulumda Android ayarı üretimi, mevcut dosyanın korunması, eksik ayarın reddi ve değerlerin çıktıya sızmaması kontrol edildi. Mac betiğinin Bash sözdizimi geçti; native Mac/Android derlemesi bu düzen için çalıştırılmadı. İstemci anahtarları derlenmiş uygulamada görünür olmaya devam eder; bu düzen Git kaynak hijyeni sağlar, Firebase Rules yerine geçmez.

12 Kasım 2026 — Mac ekran görüntüsüyle gerçek native derleme engeli belirlendi: Runner entitlements geliştirme sertifikası istiyor. Runner hedefinin ortak AppInfo.xcconfig dosyasında CODE_SIGN_IDENTITY = Apple Development tanımlandı; böylece Flutter şablonunun proje düzeyindeki ad-hoc (-) kimliği bu hedef için geçersiz kılınır. Runner'ın otomatik imzalama ve Keychain Sharing ayarları korundu. Team ID veya sertifika uydurulmadı; Xcode takım/sertifika seçimi Mac'teki uygulama sahibine aittir. Kurulum rehberine Xcode Accounts/Team/Apple Development adımları ve tanılama betiğine imzalama ayarı kaydı eklendi. Bash sözdizimi geçti; Windows'ta Xcode derlemesi çalıştırılamadığından macOS kabulü henüz tamamlanmış sayılmaz. Ücretli üyelik/plan açılmadı.

12 Kasım 2026 — Yeni marka: vektör açık kitap/paylaşım oku, lacivert-lila palet ve yerel Manrope değişken fontu. Başlık, yükleme ve Hakkında ekranları aynı marka widget'ını kullanır. Android launcher, web/PWA/favicon ve macOS AppIcon çıktıları aynı vektörden üretildi; font OFL lisansı eklendi. Kayıt ekranı işlem boyunca yükleme gösterir.

Kayıt hata incelemesi: kullanıcı hesabın oluştuğunu ve daha sonra giriş yapabildiğini doğruladı. İzole Chrome emülatöründe başlangıçtaki normal kayıt başarılıydı; üretimdeki özgün hata stack'i elde edilmedi. Yerel persist yazması engellendiğinde, Firebase hesabı oluşmasına rağmen HybridAuthRepository kayıt sonucunun hata verdiği regresyon testiyle yeniden üretildi. Oturum/profil yalnızca bellekte eşitlenir; JSON yalnızca not yazar adı gerçekten değiştiğinde yazılır. Böylece yeni hesap açılışı gereksiz yerel yazmaya bağlı kalmaz. Firebase hesabı açılıp sonraki profil adımı başarısız olursa genel uyarı yerine hesabın oluştuğu ve aynı bilgilerle giriş yapılabileceği açıkça bildirilir. Kaldırılmış aktarım butonuna yönlendiren eski hata metni düzeltildi.

Doğrulama: önce başarısız olan disk-yazma regresyonu dahil 61 uygulama testi geçti; analiz temiz; web derlemesi başarılı. Güncel Chrome emülatör sürümünde gerçek kayıt formu, markalı yükleme ve yeni kullanıcının ana sayfası doğrulandı. Backend emülatör probunda kayıt/profil/çıkış/tekrar giriş geçti. Canlı test kullanıcısı oluşturulmadı, Firebase planı veya kuralları değiştirilmedi. Platform ikonları üretildi; Android/macOS native derlemesi bu değişiklik için çalıştırılmadı. web_test/emulator_app.dart ve firebase_registration_probe.dart yalnızca demo-notpaylas emülatörlerine bağlanır.

12 Kasım 2026 — Güncel proje notpaylasma klasöründe README platform/teknoloji tablosu ve güncel Firebase hesap + yerel veri düzeniyle yenilendi. macOS için standart Flutter Podfile, isteğe bağlı Pods xcconfig bağlantıları, Runner Keychain capability ve scripts/macos.sh (run/check/build) eklendi. macOS 12.0 hedefi, mevcut Firebase bundle ID'si, sandbox/ağ/dosya/Keychain entitlement'ları korundu. Bash sözdizimi ve Mac dışı ortam kontrolü, plist/scheme XML ayrıştırması geçti; güncel proje yolunda flutter analyze temiz. Dart çalışma kodu değişmediği için önceki 60 test tekrar çalıştırılmadı. Windows üzerinde Xcode/native macOS derlemesi ve gerçek Mac dosya/Auth kabulü yapılamadı; Mac'te bash scripts/macos.sh check ve ardından kullanım kabulü gereklidir.

12 Kasım 2026 — Android Gradle, Windows'taki `notpaylaşma` klasör adını non-ASCII yol denetiminde reddetti. Yerel klasörü taşımadan bu ilk engeli kaldırmak için `android/gradle.properties` içine `android.overridePathCheck=true` eklendi. Bu seçenek tüm Android/native araçlarının Unicode yol desteğini garanti etmez; araçlardan ayrıca yol hatası alınırsa Türkçe karakter içermeyen bir proje yolu kullanılmalıdır.

Android debug derlemesinde yol kontrolü geçildi; `:app:mergeDebugNativeLibs` aşamasında Flutter JNI arşivlerini açarken “Diskte yeterli yer yok” hatası alındı. Son kontrolde C: boş alanı yaklaşık 0,52 GB. APK üretimi doğrulanamadı; diskte yeterli alan açıldıktan sonra yeniden derlenmelidir.

12 Kasım 2026 — PDF/PNG: debug web Uint8List.sublist bitiş sınırı hatası giderildi. ImageDescriptor.encoded.width web'de desteklenmediğinden PNG/JPEG doğrulaması codec/frame boyutlarıyla değiştirildi; başlık üzerinden 24 MP koruması ve geçersiz içerik reddi korundu. Dosya önizleme ve avatar motor girişleri bağımsız byte kopyası kullanır. Debug tarayıcısında PDF ve PNG notu kaydedildi, PNG önizlendi, PNG avatar seçilip kaydedildi ve profil ekranında görüldü.

Kullanıcı kararıyla Firebase yalnızca kullanıcı hesabı/profili için bağlandı. Aktif JSON şema 2'de profil/credentials/oturum tutulmaz; avatarlar yereldir. Eski hesap aktarımı not sahipliği/favori/fotoğrafı korur. Analiz temiz, 60 uygulama testi ve 7 daraltılmış Firebase güvenlik testi geçti. Mevcut not-paylasma-proje içinde ücretsiz (default) Standart Firestore europe-west1 konumunda oluşturuldu, yalnızca profil kuralları başarıyla uygulandı ve e-posta/şifre sağlayıcısı etkinleştirildi. Kurulum sonrası billingEnabled=false ve PITR kapalı doğrulandı; ödeme hesabı bağlanmadı. Gerçek hesapla uçtan uca giriş/kayıt kabulü henüz yapılmadı. [Güncel düzen](docs/FIREBASE_HESAP_YEREL_DOSYALAR.md).

11 Kasım 2026 — debug açılış düzeltmesi: DDC, SelectedFile içindeki salt okunur Uint8List görünümünü JS NativeUint8List olarak dönüştüremediği için ilk ek kopyalamasında uygulama açılamıyordu. Hata debug web sürümünde yeniden üretildi. `toWebFileBytes` ile dosya sistemi yazımı, indirme Blob'u, web açıcı ve PDF iframe Blob'u için gerçek typed-array kopyası kullanıldı. JSON başlangıcında hata aşaması ve debug stack kaydı eklendi; kullanıcıya ham SDK hatası gösterilmez. Aynı debug sürümünde ilk açılış, tam sayfa yenileme, giriş, not listesi ve PDF'nin Downloads klasörüne indirilmesi doğrulandı. Mevcut kayıtlar silinmedi; başarısız ilk açılıştan kalan ekler yeniden yazılarak kurulum tamamlandı. Salt okunur baytların JS Blob'a dönüştürülmesi için browser regresyon testi eklendi.

11 Kasım 2026 — kullanıcı isteğiyle varsayılan iki başlangıç yerel JSON'a geçirildi. Eski yerel veriler ve ekler ilk açılışta korunarak aktarılır; yeni veriler JSON ve dosya sistemine yazılır. 52 uygulama testi geçti; analiz temiz. Ayrıntılar ve tarayıcı kontrolü: docs/YEREL_JSON_KAYIT.md.

JSON son doğrulama: analiz temiz, 52/52 uygulama testi ve web derlemesi başarılı; lib/test/assets kaynakları test edilen kopyayla hash olarak aynı. Chromium tabanlı uygulama içi tarayıcıda gerçek DOCX seçme/yükleme, yerel kayıt, çıkış/giriş, yenileme ve yeni derlemeyle kaydın korunması doğrulandı. PDF ve DOCX Downloads klasörüne indirildi; SHA-256 kaynaklarıyla eşleşti. JSON dışa aktarımı 27 not içerdi, credentials içermedi. PDF iframe ekranı ve doğru blob kaynağı doğrulandı; uygulama içi tarayıcı PDF motorunu göstermediği için sayfa içeriğinin render kabulü normal Chrome'da ayrıca açık. Headless Chrome OPFS otomatik testi derlenip tarayıcıya bağlandıktan sonra suite başlangıcında bekledi ve durduruldu; geçmiş sayısal test sonucuna dahil edilmedi. Windows/macOS native dosya açma henüz cihazda doğrulanmadı.

11 Kasım 2026 — macOS platform klasörü resmi Flutter şablonuyla eklendi; geliştirme bundle ID'si `com.example.notpaylas`. Debug/release ağ, kullanıcı dosyası ve Keychain izinleri hazırlandı. Xcode imzası, native derleme ve Mac üzerinde kabul bekliyor. Kullanıcının yürüttüğü gerçek FlutterFire yapılandırması bu yerel platform eklemesinden ayrıdır. Ayrıntılar: docs/MACOS_KURULUM.md.

## Aşama 4 — devam ediyor

Yerel kalıcılık için sembast 3.10.1 ve sembast_web 2.4.7 eklendi (dolaylı idb_shim 2.11.3, synchronized 3.6.1+1). Cihazda uygulama destek dizini, webde IndexedDB kullanılır. Metadata yazım hatasında rollback, sekmeler arası revision kontrolü, dosya bütünlüğü ve sahipsiz dosya temizliği uygulanıyor. Oturum ve tema kalıcılığa bağlandı. Mevcut 29 test ile yeni hata/yeniden başlatma testlerinin sonuçları henüz bu değişiklik için onaylanmadı.

Ortam tekrar kontrol edildi: Flutter 3.47.9, Dart 3.13.7; Android command-line tools eksik ve Android cihaz/emülatör bağlı değil. Bu koşullarda Android kabulü tamamlandı olarak işaretlenmeyecek.

## Eğitim çalışma materyali — 11 Kasım 2026

Kullanıcının klasik soru ve cevap talebi için docs/EGITIM_SORULARI_VE_CEVAPLARI.md oluşturuldu. Mevcut mimari, repository/provider kaynakları, doğrulamalar ve test dosyaları incelendi. Eğitim referansının kayıtlı SHA sürümündeki main.dart ile Analytics/Crashlytics/Remote Config servisleri doğrudan tekrar okundu. Kapsam tüm eğitim deposuna genişletilmedi.

15 teorik ve 15 teknik soruya açıklamalı cevaplar eklendi; sayaç ve form için iki küçük kod çözümü verildi. Firebase konuları uygulanmış özellik gibi sunulmadı. README belge bağlantısı, ARCHITECTURE dosya envanteri ve TASKS eğitim görevi güncellendi. Uygulama kodu ve bağımlılıklar değiştirilmedi; bu dokümantasyon işi için uygulama testleri tekrar çalıştırılmadı.

## Aşama 1 ortam bulguları — 11 Kasım 2026

Bu bulgular ilk hazırlık aşamasında elde edildi ve Aşama 2 başlangıcında tekrar kontrol edildi.

| Bileşen | Sonuç |
| --- | --- |
| Windows | Windows 11 25H2 |
| Flutter | 3.47.9 stable, revision c197ca5199 |
| Dart | 3.13.7 stable |
| Flutter SDK | C:\Users\PC\development\flutter |
| VS Code | 1.144.1; Dart uzantısı bulundu, incelenen dizinde Flutter uzantısı yoktu |
| Android SDK | C:\Users\PC\AppData\Local\Android\sdk |
| Command-line tools | Eksik; flutter doctor Android toolchain hatası |
| Android Studio | Standart kurulum yolunda bulunamadı; başka konumda olmadığı kesinleştirilmedi |
| PATH Java | 1.8.0_491; modern Gradle için uygun JDK gerekli |
| adb/sdkmanager | PATH'te bulunamadı; platform-tools dizini var |
| Bağlı hedefler | Windows, Chrome, Edge; Android cihaz/emülatör yok |
| Visual Studio | Kurulu değil; Windows masaüstü derlemesini ilgilendirir |
| Ağ | flutter doctor beklenen kaynaklara erişebildi |

İlk komutlar: flutter --version, dart --version, flutter doctor -v, flutter devices, java -version, code --version. Doctor iki sorun kategorisi bildirdi: Android toolchain ve Windows Visual Studio. [Resmî Android kurulum rehberi](https://docs.flutter.dev/platform-integration/android/setup).

## Altı aşamalı plan

1. Analiz/hazırlık tamamlandı; docs/REFERENCE_REVIEW.md korunuyor.
2. Arayüz/temel yapı uygulandı; Android ortamı ve cihaz kontrolü açık.
3. Uygulama özellikleri mock repository'lerle uygulandı; aşağıdaki doğrulama kaydı geçerli.
4. Kalıcı mock sistem, hata enjeksiyonu ve Android uçtan uca testleri.
5. Firebase Auth/Firestore/Storage, rules/index ve gerçek veri testleri.
6. Gerçek Firebase ile final testleri, performans/UX, debug/release APK.

## Aşama 2 geçmişi

Flutter 3.47.9 şablonu geçici dizinde android,web hedefleriyle üretildi; mevcut belgeler ezilmeden platform/yapılandırma dosyaları kopyalandı. Material 3 lacivert/mor tema, beş sekme, temel navigasyon, Türkçe yerelleştirme ve ortak durum bileşenleri oluşturuldu.

İlk 320 piksel / %200 metin testinde appbar başlığı 67 piksel taşıyordu. Flexible ve ellipsis ile düzeltildi. Cupertino ikon fontu uyarısı uygun ikon paketi eklenerek giderildi. Aşama 2 kapanış kontrolü: temiz analiz, 7/7 widget testi, başarılı web derlemesi; docs/screenshots/stage2-home.jpg bu eski sürüme aittir.

Türkçe kaynak yolunda analiz sunucusu LSP FormatException ile kapandı. Aynı kaynakların ASCII dizindeki analizi geçti. Kök SDK nedeni kesinleştirilmedi; scripts/verify.ps1 kaynakları taşımadan geçici kopyada doğrulama yapar.

## Aşama 3 uygulaması

- Dört repository arayüzü ve MockAuth/MockNote/MockFavorite/MockCategoryRepository eklendi.
- User/Note/Category/SelectedFile modelleri ve JSON dönüşümleri; filtre, sıralama, ID cursor ve hata sözleşmeleri.
- İki demo kullanıcı, dört kategori, 26 not; gerçek PDF, DOCX ve PNG ekleri.
- Kayıt/giriş/çıkış, oturum kapısı, tek kullanımlık demo şifre sıfırlama kodu; kod 5 dakika / 5 deneme sınırında.
- Not formu, gerçek dosya seçimi/byte ilerlemesi, sahiplik kontrolü, düzenleme/silme ve artık dosya/favori temizliği.
- Ana sayfa/keşfet arama ve filtreleri, liste sayfalaması, detay, favoriler, profil ve fotoğraf değişimi.
- Görsel uygulama içinde, PDF cihaz/tarayıcıda, DOCX uyumlu mobil uygulamada açılır; web DOCX indirme yönlendirmesi verir.
- SessionGate iç Navigator'ı kullanıcı ID'siyle yeniler; NavigatorPopHandler geri işlemini aktarır.
- Veriler oturumluk bellektedir. Yeniden başlatmada seed yüklenir. Kalıcılık Aşama 4'e bırakıldı ve UI'da açıkça belirtilir.

## Paketler ve teknik kararlar

Kilitlenen sürümler: provider 6.1.5+1, cupertino_icons 1.0.9, file_picker 13.3.3, open_filex 5.0.0, path_provider 2.1.6, uuid 4.6.0, crypto 3.0.8, archive 4.6.0, web 1.1.2. flutter_localizations/flutter_test SDK'dan; flutter_lints 6.0.0; intl 0.20.3 dolaylı yerelleştirme bağımlılığı. pubspec.lock gerçek çözümü kaydeder.

file_picker 13'ün statik pickFile/saveFile ve PlatformFile.length/readAsBytes API'leri kurulu paket kaynağından doğrulandı. Native PDF görüntüleyici ek C araç zinciri getirdiği için bu aşamada kullanılmadı; cihaz/tarayıcı PDF açma servisi tercih edildi. Firebase paketleri eklenmedi.

Kaynaklar: [file_picker](https://pub.dev/packages/file_picker), [open_filex](https://pub.dev/packages/open_filex), [provider](https://pub.dev/packages/provider).

## Aşama 3 doğrulama ve hata günlüğü

Analiz temiz, 29 otomatik test geçti; web derlemesi başarılı. Test kapsamı:
- Repository/model: kimlik, hatalı parola, kayıt çakışması, sıfırlama/tek kullanım/deneme sınırı, girişsiz erişim, dosya kopyalama, sahiplik, sayaç koruma, silme temizliği, sayfalama ve Türkçe arama.
- Provider: kullanıcı değişiminde favori izolasyonu, başarısız kayıt sonrası meşgul durumun temizlenmesi, fotoğraf değişiminde eski dosyanın silinmesi, kategori hata/tekrar deneme.
- Widget: giriş doğrulama, navigasyon/geri/tema/çıkış, 320 ve 1024 pikselde %200 metin, arama, form + dosya iptali/kaydetme, detay/favori/indirme sonucu, hata/yüklenme.

Tarayıcıda gerçek file chooser ile assets/mock/files/ornek.pdf seçildi, bir not oluşturuldu, aramayla bulundu ve favorilendi. İndirilen dosyanın SHA-256 özeti kaynakla aynı bulundu: 59195CF0FF5B64F1FC83EB7B08709AC846F7E532BDA6C9C38B243A07ABF4E2D3.

Bu deneme web indirme sayacında bir hata ortaya çıkardı: file_picker_web varsayılan download modunda başarılı istekten sonra da null döndürüyor; ortak kod bunu mobil iptali sayıyordu. DeviceFileService webde işlemi “tarayıcıya iletildi”, mobilde URI null ise “iptal” olarak ayıracak şekilde düzeltildi. Son analiz/test/derleme ve sayaç yeniden kontrolünün sonucu TASKS.md'dedir. İstemci webde fiziksel disk yazma tamamlanmasını ölçmez.

Not kaydetmede yeni metadata bağlanmadan eski dosyanın silinmesi engellendi; favori yenilemesinde aynı kullanıcıya ait liste gereksiz yere boşaltılmıyor. Widget testlerindeki cihaz servisi sahtedir; gerçek tarayıcı seçici denemesi ayrı kanıttır. Android dosya seçimi/açma/kaydetme henüz cihazda sınanmadı.

## Çalıştırma

```powershell
flutter pub get
flutter run -d chrome
flutter test
./scripts/verify.ps1 -BuildWeb
```

Doğrulama betiği lib/test/assets/web ve paket ayarlarını ASCII geçici dizine kopyalar. Analiz/test/isteğe bağlı web derlemesi başarısızsa durur; kopyayı inceleme için bırakır. Aşama 3 kontrol dizini C:\Users\PC\AppData\Local\Temp\notpaylas_stage3_582f4ca4fb3b4f989744488980de2959. Yerel önizleme bu dizinin build/web çıktısını 127.0.0.1:8766 üzerinden sunar; sunucu kapanınca bağlantı çalışmaz.

## Açık işler

Android SDK Command-line Tools, şablona uygun JDK, lisans kontrolü ve bağlı cihaz/emülatör gerekir. Android ortamı tamamlanınca gerçek seçme/önizleme/kaydetme akışı test edilecek. iOS için gelecekte macOS/Xcode gerekir.

Aşama 4: disk/IndexedDB kalıcılığı, kalıcı oturum, bozuk veri ve yarım işlem kurtarma, kaynak/bellek sınırları, gecikmeli sorgu ve cihaz entegrasyon testleri. Aşama 5: gerçek Firebase ve güvenlik kuralları. Aşama 6: tam özellik/performance/UX kontrolü ve gerçek Firebase hedefinden flutter build apk --debug / --release. Release dağıtım anahtarı kullanıcıya ait olacak; keystore/parolalar repoya eklenmez.

Yeni özellik README ve ilgili teknik belgeye, dosya/klasör ARCHITECTURE'a, görev TASKS'e, ilerleme/hata bu günlüğe, veri değişikliği DATABASE'e, Firebase değişikliği FIREBASE_SETUP'a, aşama değişikliği PROJECT_PLAN'a yazılır. Belgeler güncellenmeden görev tamamlanmaz.


## Güncel durum — Aşama 5 hazırlığı

11 Kasım 2026: Firebase Auth/Firestore repository'leri, Firebase Storage servisi ve AppDependencies bağlantısı eklendi. Ayrı Firebase açılışı lib/main_firebase.dart; varsayılan lib/main.dart kalıcı mock olarak korunur. firebase.json, firestore.rules, storage.rules ve firestore.indexes.json eklendi. Yerel demo-notpaylas emulator'larında 16/16 güvenlik testi geçti; gerçek hesaba giriş, proje oluşturma veya deploy yapılmadı.

Bekleyenler: uygulama sahibinin bilgisayarında flutterfire configure ile gerçek options üretimi, test projesine kurallar/indekslerin uygulanması, kategorilerin yetkili olarak eklenmesi, gerçek repository ve Android/ağ kesintisi kabulü. Aşama 5 canlı bağlantı kabulü ve 6. aşama APK teslimi tamamlanmış değildir. Kurulum komutları ve bilinen sınırlar FIREBASE_SETUP.md içindedir.

Yeni rehber: [Başka bilgisayarda kurulum](docs/BASKA_BILGISAYARDA_KURULUM.md).

Son kontrol: analiz temiz; 48/48 Flutter testi ve 16/16 yerel Firestore/Storage güvenlik testi geçti. Testlerin yakaladığı dosya üzerine yazma ve açılışta tekrar deneme hataları düzeltildi. Mock ve Firebase başlangıçlarının web derlemeleri geçti. Projedeki lib/test kaynakları ASCII doğrulama kopyasıyla hash olarak eşleşti. Gerçek Firebase erişimi ve Android kabulü denenmedi.
