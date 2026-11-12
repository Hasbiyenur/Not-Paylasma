# Referans proje teknik incelemesi

İnceleme tarihi: 11 Kasım 2026.

[İstenen GitHub klasörü](https://github.com/Hasbiyenur/SoftITo_Mobil_Uyg_Egitim/tree/main/_6kasim%2Faltikasimiki) web okuma aracında açılmadı; içerik GitHub REST API ağaç/blob uçlarından başarıyla okundu. İnceleme başka bir eğitim klasörüne genişletilmedi.

- Ana ağaç SHA: `e70b9a56fe529adad37c484d9653364a2963fc40`
- İncelenen klasör ağacı: `0bb58502245246b2f1e9db7609ee57c9c59fd1db`
- [Sabit sürüm bağlantısı](https://github.com/Hasbiyenur/SoftITo_Mobil_Uyg_Egitim/tree/e70b9a56fe529adad37c484d9653364a2963fc40/_6kasim/altikasimiki)

## Doğrudan okunan dosyalar

- `lib/main.dart`
- `lib/services/analytics_servisi.dart`
- `lib/services/crashlytics_servisi.dart`
- `lib/services/remote_config_servisi.dart`
- `pubspec.yaml`
- `test/widget_test.dart`
- `android/app/build.gradle.kts`
- `android/settings.gradle.kts`

Klasör ağacındaki bütün `lib/` kaynak dosyaları bunlardır. Platform klasörleri Android, iOS, Linux, macOS, Windows ve web içerir; platform dosyalarının tamamı incelenmedi. Referans çalıştırılmadı veya derlenmedi.

## Bulgular

| Konu | Kaynakta görülen durum |
| --- | --- |
| Giriş noktası | `main()` doğrudan `runApp(const MyApp())` çağırıyor |
| StatelessWidget | `MyApp`, MaterialApp ve seed tabanlı ThemeData oluşturuyor |
| StatefulWidget | `MyHomePage`, yerel `_counter` durumunu `setState` ile artırıyor |
| Widget organizasyonu | Sayaç ekranı main.dart içinde; Firebase yardımcıları services altında |
| Navigator | İncelenen Dart dosyalarında kullanılmıyor |
| Form/TextFormField | İncelenen Dart dosyalarında bulunmuyor |
| Modeller/repository | Ayrı veri modelleri ve repository katmanı bulunmuyor |
| Durum yönetimi | Yerel setState; Provider veya başka durum yönetimi paketi tanımlı değil |
| Firebase | Analytics ekran/olay/kullanıcı özelliği, Crashlytics kullanıcı/log/hata, Remote Config varsayılan/fetch yardımcıları |
| Başlatma | main.dart içinde Firebase.initializeApp yok; servislerin çalışan entegrasyonu gösterilmiyor |
| Auth/Firestore/Storage | İlgili paketler veya uygulama akışları bu klasörde yok |
| Test | Varsayılan sayaç artışı widget testi |

Remote Config servisi fetch hatasını boş catch ile yutuyor ve minimum fetch aralığını sıfır kullanıyor. Bu eğitim örneğini NotPaylaş'ta hata yönetimi yaklaşımı olarak kopyalamayacağız. Crashlytics'teki kasıtlı çökertme metodu ürün özelliği olarak taşınmayacak.

## Referansta tanımlı sürümler

`environment.sdk: ^3.13.5`; `cupertino_icons: ^1.0.8`; `firebase_core: ^5.1.0`; `firebase_analytics: ^13.0.1`; `firebase_remote_config: ^7.0.1`; `firebase_crashlytics: ^6.0.1`; `flutter_lints: ^6.0.0`.

Bunlar pubspec kısıtlarıdır, bu incelemede çözülmüş sürüm veya başarılı derleme olarak doğrulanmadı. Android ayarlarında AGP 9.1.0, Kotlin plugin 2.4.0 ve JVM hedefi 17 görülüyor; release yapılandırması debug anahtarını kullanıyor. NotPaylaş'ın Android dosyaları kurulu Flutter şablonundan üretilecek; referans Gradle sürümleri körlemesine kopyalanmayacak.

## NotPaylaş'a uyarlama

StatelessWidget/StatefulWidget, sade dosya düzeni, küçük servisler ve MaterialApp yaklaşımı korunacak. Referansta navigasyon/form örneği bulunmadığı için bu konularda var olmayan bir eğitim tercihine atıf yapılmayacak. Kullanıcı talebi doğrultusunda Provider eklenecek; paylaşılan not, oturum ve favori durumunu ekranlardan ayıracak. Firebase yardımcı paketleri mock aşamasına taşınmayacak.
