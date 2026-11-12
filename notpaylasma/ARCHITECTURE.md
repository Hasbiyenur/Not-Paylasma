# Mimari — Aşama 4

Güncel başlangıç `hybrid_dependencies.dart`: FirebaseAuthRepository + HybridAuthRepository, kullanıcı profilini Firebase'den yalnızca belleğe alır. LocalJsonStore(externalUsers:true) şema 2'ye profil/parola/oturum yazmaz. LocalNote/Favorite/Category ve JsonAttachmentStorage kullanılır; fotoğraf yolu localAvatars içindedir. Eski kullanıcı eşlemesi migrateLegacyAccount ile Firebase uid'sine taşınır. Ayrıntı: docs/FIREBASE_HESAP_YEREL_DOSYALAR.md.

Güncel varsayılan başlangıç `createLocalJsonDependencies`: `repositories/local` repository'leri, `LocalJsonStore`, `JsonDataService`, `JsonAttachmentStorage` ve platforma göre `BrowserJsonFileSystem` (OPFS) / `DiskJsonFileSystem`. Eski depodan aktarım yalnızca `legacy_json_import.dart` ile bir defa yapılır. Yeni yazmalar JSON'a gider. Önceki mock/Firebase tasarımları çalışma geçmişidir. Ayrıntı: docs/YEREL_JSON_KAYIT.md.

## Veri akışı ve başlangıç

Widget → Provider → repository arayüzü → mock implementasyonu → MockStore / FileStorageService.

StatefulWidget/StatelessWidget, Provider ve Navigator yaklaşımı korunur. UI Firebase SDK türlerini bilmez. Modeller Dart türleri, DateTime ve SelectedFile kullanır. AppException kullanıcıya Türkçe hata sunar.

main.dart içindeki NotPaylasBootstrap, AppDependencies.mock(persistent: true) çağırır. Mevcut yerel kayıt yüklenir; yalnızca ilk kurulumda iki kullanıcı, dört kategori, 26 örnek not ve PDF/DOCX/PNG ekleri oluşturulur. Açılış hatasında yeniden deneme sunulur; bozuk kayıt sessizce temizlenmez. AppScope repository ve Provider'ları bağlar. Kaynaklar AppDependencies.close ile bırakılır.

AppDependencies.mock() varsayılan olarak bağımsız bellek test modudur. LocalMockDatabase ve dosya servisi dışarıdan verilebilir; disk/arıza testleri bu bağlantıyı kullanır. Çalışan ürün başlangıcı açıkça persistent: true seçer.

## Repository sözleşmeleri

| Arayüz | Mock implementasyonu | İşler |
| --- | --- | --- |
| AuthRepository | MockAuthRepository | Oturum, kayıt/giriş/çıkış, demo reset, profil |
| NoteRepository | MockNoteRepository | NoteQuery/NotePage, CRUD, indirme sayacı, değişim akışı |
| FavoriteRepository | MockFavoriteRepository | Aktif kullanıcı favorileri, idempotent set |
| CategoryRepository | MockCategoryRepository | Sabit kategori kataloğu |

Kimlik aktif oturumdan alınır; not sahipliği repository içinde denetlenir. Yükleme sırasında sessionRevision değişirse metadata bağlanmaz. Aynı not için eşzamanlı düzenleme/silme kilidi vardır. Reset kodu için eşzamanlı kullanımı önleyen kilit bulunur.

MockStore metadata değişikliklerini kısa senkron action + beklenen disk kaydı şeklinde sıraya alır. Hata halinde önceki metadata geri yüklenir. UI değişim olayları başarılı kayıttan sonra gönderilir. Okuma sorguları bekleyen metadata işini bekler. Bellek adapter'ı disk kuyruğuna girmez. Bu yapı sunucu güvenlik sınırı değildir.

## Kalıcı depo

local_database_factory.dart koşullu export kullanır: _io dosyası path_provider uygulama destek dizininde notpaylas_mock.db açar; _web dosyası Sembast Web ile IndexedDB notpaylas_mock açar.

LocalMockDatabase metadata/state kaydında revision + state saklar. State şema sürümü 1'dir. Initialized işareti bulunan depoda ana kayıt eksikse ilk kurulum yapılmaz. Kaydetme transaction içinde mevcut revision'ı karşılaştırır; eski pencerenin yazımı reddedilir. Başka penceredeki değişiklikler otomatik UI eşitlemesi sağlamaz; yenileme gerekir.

PersistentFileStorageService files store'unda dosyaları ayrı kayıtlar halinde tutar: isim, boyut, base64 veri, SHA-256 ve oluşturma zamanı. Kayıt transaction ile atomiktir. Her metadata değişiminde ekler yeniden kodlanmaz. Sembast yerel veritabanını belleğe yüklediği için 64 MiB toplam ham ek sınırı vardır; bu toplam bellek tüketimi sınırı değildir. Dosya okuma hash/boyut doğrular.

Not kaydetme: doğrula → yeni dosyayı yaz → oturumu tekrar kontrol et → metadata'yı kalıcı bağla → eski dosyayı temizle. Metadata öncesi hatada yeni dosya temizlenir. Not silme önce metadata ve bütün kullanıcıların favorilerini atomik kaldırır, sonra eki temizler. Dosya temizliği hata verirse başarılı metadata geri alınmaz; sahipsiz ek sonraki açılış taramasına bırakılır. Tarama, başka sekmede yeni başlayan yüklemeyi korumak için yalnızca 24 saatten eski sahipsiz ekleri siler. Metadata ve ek yazımı ortak transaction değildir; kesinti telafisi bu yöntemle yapılır.

Profil fotoğrafında da yeni ek → profil → eski ek temizliği uygulanır. Kayıt bozuksa veri korunur ve hata gösterilir; otomatik yedek/onarım veya veri sıfırlama UI'ı yoktur. Şema değişikliğinde açık migration gereklidir.

## Dosya cihaz servisleri

- DeviceFileService: gerçek seçim, dışa aktarma ve açma; file_picker statik API.
- FileValidator: uzantı/içerik imzası, 20 MiB ek/5 MiB avatar; DOCX Office ZIP yapısı. Cihaz seçiminde görsel codec ve 24 megapiksel kontrolü.
- MemoryFileStorageService: izole testlerde gerçek bayt kopyalar; parça bazında ilerleme.
- PersistentFileStorageService: kalıcı kayıt başlangıcı/sonu 0→1 ilerlemesi; ağ transferi değil.
- file_opener_io: UUID adlı geçici dosya ve open_filex.
- file_opener_web: PDF Blob sekmesi; pencere engelinde hata. URL iki dakika sonra bırakılır. DOCX indirmeye yönlendirilir.
- ImagePreviewScreen: InteractiveViewer ile görsel.
- ExportResult: iptal/kaydedildi/tarayıcıya iletildi; iptalde sayaç artmaz, web disk tamamlanması iddia edilmez.

## Provider ve navigasyon

AuthProvider oturum/profil meşgul durumunu; NoteProvider değişim sürümü/kayıt ilerlemesini; CategoryProvider yükleme/hata/tekrar denemeyi yönetir. FavoriteProvider kullanıcı değişiminde eski kimlikleri temizler, sorgu nesliyle geç cevapları eler. Açık reload, kendisini geçersiz kılan daha yeni yüklemenin de tamamlanmasını bekler. ThemeProvider başlangıç tercihini depodan alır; ancak kayıt başarılı olunca yeni temayı uygular.

SessionGate uid anahtarlı iç Navigator'ı oturum değişiminde yeniler. NavigatorPopHandler geri olayını iç Navigator'a aktarır. AppShell IndexedStack ile beş sekmenin durumunu korur. NoteFeed arama/filtre/sıralama değişiminde ilk sayfaya döner; eski asenkron sonucu nesil kontrolüyle eler. Normal listeler sayfalıdır; favori listesi mevcut favorilerin tümünü çözer. Çok büyük favori listesi optimizasyonu sonraki performans kontrolüdür.

## Dosya envanteri

- lib/main.dart, app.dart: başlangıç ve MaterialApp.
- lib/core/theme: Material 3 açık/koyu tema.
- lib/core/utils: AppException, Validators, FileValidator.
- lib/core/services: AppDependencies, AppScope, DeviceFileService, FileStorageService, platform dosya açıcılar.
- Aşama 4 yeni servisler: local_database_factory.dart, local_database_factory_io.dart, local_database_factory_web.dart, local_mock_database.dart, persistent_file_storage_service.dart.
- lib/models: user_model, category_model, note_model (Draft/Query/Page dahil), selected_file.
- lib/repositories: dört arayüz; mock/ içinde dört implementasyon ve MockStore.
- lib/providers: auth, note, favorite, category, theme.
- lib/features/auth/screens: login, register, reset_password.
- lib/features/shell/screens: session_gate, app_shell.
- lib/features/home, explore, favorites: ekranları.
- lib/features/notes/screens: share_note, note_detail, image_preview.
- lib/features/profile/screens: profile, edit_profile.
- lib/shared/widgets: page_layout, app_status_view, note_card, note_feed, feedback.
- assets/mock/files: ornek.pdf, ornek.docx, ornek.png.
- test/repositories/mock_repositories_test.dart: 15 temel repository/model testi.
- test/providers/providers_test.dart: 5 provider testi, gecikmiş kullanıcı cevabı dahil.
- test/widgets/app_test.dart: 10 arayüz/akış testi.
- test/persistence/local_persistence_test.dart: 17 gerçek geçici disk/kurtarma/kota/eşzamanlılık/büyük veri testi.
- scripts/verify.ps1: aynı kaynakları ASCII kopyada analiz/test/isteğe bağlı web derlemesiyle doğrular.
- android ve web: platform projeleri; pubspec.yaml/lock, analysis_options.yaml ve .metadata köktedir.
- docs/REFERENCE_REVIEW.md: Aşama 1 incelemesi; korunur.
- docs/EGITIM_SORULARI_VE_CEVAPLARI.md: 30 klasik soru/cevap, kalıcılık cevapları güncel davranışla uyumludur.
- docs/screenshots: tarayıcı görsel doğrulama kayıtları.
- integration_test: ileride Android cihaz kabulü için ayrılmış klasör; mevcut disk testleri cihaz testi değildir.

## Sonraki işler

Aşama 4'ün Android cihaz kabulü ortam nedeniyle açık. Aşama 5 Firebase implementasyonları ve gerçek güvenlik kurallarıdır. Firebase.initializeApp yalnızca Firebase başlangıcında çalışır; mock başlangıcı options'a bağımlı olmaz. Firebase açıkça seçilip başarısız olursa sessizce mock'a geçilmez. Aşama 6 gerçek backend final testi ve debug/release APK'dır.


## Güncel durum — Aşama 5 hazırlığı

11 Kasım 2026: Firebase Auth/Firestore repository'leri, Firebase Storage servisi ve AppDependencies bağlantısı eklendi. Ayrı Firebase açılışı lib/main_firebase.dart; varsayılan lib/main.dart kalıcı mock olarak korunur. firebase.json, firestore.rules, storage.rules ve firestore.indexes.json eklendi. Yerel demo-notpaylas emulator'larında 16/16 güvenlik testi geçti; gerçek hesaba giriş, proje oluşturma veya deploy yapılmadı.

Bekleyenler: uygulama sahibinin bilgisayarında flutterfire configure ile gerçek options üretimi, test projesine kurallar/indekslerin uygulanması, kategorilerin yetkili olarak eklenmesi, gerçek repository ve Android/ağ kesintisi kabulü. Aşama 5 canlı bağlantı kabulü ve 6. aşama APK teslimi tamamlanmış değildir. Kurulum komutları ve bilinen sınırlar FIREBASE_SETUP.md içindedir.

Yeni rehber: [Başka bilgisayarda kurulum](docs/BASKA_BILGISAYARDA_KURULUM.md).
