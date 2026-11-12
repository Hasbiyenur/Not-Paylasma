# Firebase yapılandırması ve GitHub uyarıları

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

Komut mevcut projeyi hedefler. `lib/firebase_options.dart` üzerine gerçek anahtar üreten varsayılan FlutterFire çıktısını yazdırmayın. Hazırlama betiği yerel JSON yoksa `.local/firebase_options.generated.dart` içindeki üç platform anahtarını alır; Android dosyası yoksa anahtarsız örnekten üretir. Bu çalışmada CLI login, bulut anahtarı değiştirme veya ücretli plan işlemi yapılmadı.

Manuel derlemelere `--dart-define-from-file=.local/firebase-keys.json` eklenmelidir. IDE çalıştırma ayarlarında da aynı Flutter argümanı kullanılmalıdır. Dosya yoksa uygulama gerçek Firebase bağlantısı kuramaz; mock'a sessizce geçmez.

## Commit edilmiş eski uyarılar

Bu değişiklik, geçmiş commit'leri yeniden yazmaz ve anahtarı iptal etmez. GitHub, dosya kaldırıldığında eski secret scanning uyarısını kendiliğinden kapatmaz: https://docs.github.com/en/code-security/how-tos/manage-security-alerts/manage-secret-scanning-alerts/resolving-alerts

Depo sahibi GitHub > Security > Secret scanning içinde her kaydı incelemelidir. İncelenen anahtar yalnızca bu uygulamanın Firebase istemci anahtarıysa, açıklamasıyla uygun gerekçeyle kapatılabilir. Örnek açıklama: `Intentionally public Firebase client configuration, not an admin/private credential. User data access is controlled by Firebase Authentication and Firestore Security Rules.` Anahtar iptal edilmediği için Revoked gerekçesi kullanılmamalıdır. GitHub uyarıları bu bilgisayardan kapatılmadı; doğrulanmış yetkili oturum bulunmuyor.

Gerçek sunucu/private key veya Firebase dışında kullanılan bir anahtar sızıntısı varsa ilgili anahtar ayrıca iptal edilip yenilenmelidir. Mevcut uygulamanın anahtarları kullanıcı onayı olmadan değiştirilmedi; bulut API izinleri de değiştirilmedi.

## Commit öncesi kontrol

```bash
python scripts/check_public_config.py
git status --short
```

Kontrol, Git'in izlediği ve yok sayılmamış yeni UTF-8 metin dosyalarını (dosya başına en fazla 2 MiB) tarar; eşleşen değerleri yazdırmaz. Tüm Git geçmişini veya her olası kimlik bilgisi biçimini denetlediği iddia edilmez. `.local` ve gerçek Android ayarını `git add -f` ile eklemeyin.