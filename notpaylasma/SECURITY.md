# Firebase yapılandırması ve GitHub uyarıları

## Güncel durum — 12 Kasım 2026 anahtar yenilemesi

- Git geçmişinde yer alan üç aktif anahtar (web, Android, macOS) sağlayıcı tarafında silinerek iptal edildi. Her eski anahtarın aktif listeden çıktığı, silinme bilgisinin bulunduğu ve Firebase Auth tarafından geçersiz olarak reddedildiği doğrulandı.
- Üç yeni anahtar oluşturuldu. API izinleri yalnızca identitytoolkit.googleapis.com, securetoken.googleapis.com, firestore.googleapis.com, firebaseinstallations.googleapis.com ve firebase.googleapis.com ile sınırlı.
- Bu bilgisayardaki `.local/firebase-keys.json` ve Android `google-services.json` güncellendi. Yeni anahtarlar Git dışında kalır. Diğer bilgisayarlara güncel yerel ayar ayrıca taşınmalı; eski derlemeler yeniden derlenmelidir.
- Yeni üç anahtarın Auth API erişimi, gerçek kullanıcı oluşturmadan geçersiz token testiyle doğrulandı. Yeni web anahtarıyla oturumsuz Firestore profil okuması 403/PERMISSION_DENIED döndürdü. Web derlemesinin yeni web anahtarını aldığı doğrulandı.
- Kurulum sonrası Cloud Billing `billingEnabled: false`; ücretli Firebase/GitHub planı veya ödeme hesabı açılmadı.
- GitHub API erişiminde depo özel, yönetici yetkisi mevcut fakat secret scanning kapalı bulundu. Bu nedenle GitHub uyarıları API üzerinden kapatılmadı. Ücretli özel-depo taraması etkinleştirilmedi. Önceki erişim sorununu yalnızca oturum yokluğu olarak yorumlayan notlar bu güncellemeyle geçersizdir.

Yeni anahtar değerleri veya erişim belirteçleri belgeye/log çıktısına yazılmadı. Sağlayıcı silme işlemi eski anahtarların kullanımını durdurur; eski commit ve e-posta bildirimlerini kendiliğinden silmez.

## Bu değişiklik neyi düzeltir?

Gerçek Firebase istemci anahtarları `lib/firebase_options.dart` içinden çıkarıldı. Dosya artık `String.fromEnvironment` kullanır. Proje/app kimlikleri kaynakta kalır; üç anahtar `.local/firebase-keys.json` dosyasında yereldir ve Git tarafından yok sayılır. Android `google-services.json` dosyası diskte korunur fakat Git takibinden çıkarılmıştır; depoda anahtarsız `google-services.example.json` bulunur.

Bu düzenleme kaynak depoya yeni anahtar eklenmesini önler. Derlenmiş istemcide Firebase API anahtarı yine görülebilir; bu yöntem anahtarı sunucu sırrına dönüştürmez. Firebase istemci anahtarları projeyi tanımlar. Veri güvenliği Auth ve Security Rules ile sağlanır: https://firebase.google.com/docs/projects/api-keys

## Bu bilgisayarda çalıştırma

Mevcut anahtarlar `.local/firebase-keys.json` içine korunarak taşındı. Hazırlama betiği değerleri yazdırmaz.

```powershell
./scripts/run-local.ps1
# Alternatif Chrome komutu:
flutter run -d chrome --web-port 8767 --dart-define-from-file=.local/firebase-keys.json
# Android:
dart scripts/prepare_firebase.dart
flutter run -d <cihaz-kimligi> --dart-define-from-file=.local/firebase-keys.json
```

```bash
# Mac (yerel dosyayı otomatik kullanır):
bash scripts/macos.sh run
```

## Başka bilgisayar / yeni klon

Git bu yerel ayarları taşımaz. Uygulama sahibi kendi `.local/firebase-keys.json` dosyasını hedef bilgisayara kendi yöntemiyle aktarabilir. Alternatif olarak `config/firebase-keys.example.json` şablonundan aynı konumda gerçek istemci ayarlarını hazırlayabilir. Değerler sohbetle paylaşılmaz.

Aynı Firebase projesinin seçeneklerini uygulama sahibinin bilgisayarında yeniden üretmek için, mevcut FlutterFire CLI ile:

```bash
flutterfire configure --project=not-paylasma-proje --platforms=android,web,macos --macos-bundle-id=com.example.notpaylas --out=.local/firebase_options.generated.dart
dart scripts/prepare_firebase.dart
```

Komut mevcut projeyi hedefler. `lib/firebase_options.dart` üzerine gerçek anahtar üreten varsayılan FlutterFire çıktısını yazdırmayın. Hazırlama betiği yerel JSON yoksa `.local/firebase_options.generated.dart` içindeki üç platform anahtarını alır; Android dosyası yoksa anahtarsız örnekten üretir. Yerel hazırlama betiği kendi başına login veya bulut değişikliği yapmaz. Üstteki olay müdahalesinde uygulama sahibinin talimatıyla anahtarlar ayrıca yenilendi; ücretli plan açılmadı.

Manuel derlemelere `--dart-define-from-file=.local/firebase-keys.json` eklenmelidir. IDE çalıştırma ayarlarında da aynı Flutter argümanı kullanılmalıdır. Dosya yoksa uygulama gerçek Firebase bağlantısı kuramaz; mock'a sessizce geçmez.

## Commit edilmiş eski uyarılar

Kaynak dosyalarının düzenlenmesi tek başına geçmiş commit'leri değiştirmez. Üstteki olay müdahalesinde eski anahtarlar ayrıca sağlayıcı tarafında iptal edildi. GitHub, dosya kaldırıldığında eski secret scanning uyarısını kendiliğinden kapatmaz: https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-secret-scanning-alerts/resolving-alerts

GitHub uyarı ekranı erişilebilir olduğunda, bu üç eski anahtar için doğru kapanış gerekçesi artık `Revoked` olur: anahtarların sağlayıcıda silindiği ve reddedildiği doğrulandı. Özel depoda Secret scanning kapalı olduğundan bu işlem API ile tamamlanamadı. Güvenlik paketini ücretli olarak etkinleştirme işlemi yapılmadı.

Geçmiş yeniden yazılmadı; eski değerler geçmişte bulunabilir ancak doğrulanan üç eski anahtar artık kullanılamaz. Özel anahtar veya başka kimlik bilgileri için ayrı inceleme gerekir. Mevcut kullanıcılar, projeler ve Firestore verileri silinmedi.

## Commit öncesi kontrol

```bash
python scripts/check_public_config.py
git status --short
```

Kontrol, Git'in izlediği ve yok sayılmamış yeni UTF-8 metin dosyalarını (dosya başına en fazla 2 MiB) tarar; eşleşen değerleri yazdırmaz. Tüm Git geçmişini veya her olası kimlik bilgisi biçimini denetlediği iddia edilmez. `.local` ve gerçek Android ayarını `git add -f` ile eklemeyin.