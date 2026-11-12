# Proje planı

## Amaç ve kapsam

Eğitimde öğrenilen Flutter widget yapısını koruyarak Android üzerinde çalışan bir not paylaşım uygulaması oluşturmak. Önce Firebase'siz özellikler ve mock sistem doğrulanır; Firebase 5. aşamada eklenir, nihai debug/release APK'lar 6. aşamada oluşturulur. iOS sonraki platform hedefidir.

11 Kasım 2026 plan revizyonu: önceki on aşamalı plan aşağıdaki altı aşamaya birleştirildi. Aşama 1'in incelemeleri korunur. Kullanıcının devam talimatıyla Aşama 3 başlatılmıştır; Aşama 2'nin Android cihaz kontrolü ayrıca açık görev olarak korunur. Aşama 3'te özelliklerin geliştirilmesi için gereken mock implementasyonları da eklenir; Aşama 4 bu sistemi ve testlerini tamamlar. Firebase öncesinde çalışan mock akışları korunur.

## Sıralı geliştirme aşamaları

| Aşama | İşler | Çıkış ölçütü | Durum |
| --- | --- | --- | --- |
| 1 | Referans, ortam, mimari, klasörler ve tüm Markdown belgeleri | Bulgular doğrulanmış ve görevler sıralanmış | Tamamlandı |
| 2 | Arayüz tasarımı ve temel yapı: Flutter iskeleti, tema, ortak durum bileşenleri, beş sekme | Firebase'siz açılış, responsive görünüm ve temel navigasyon testleri; Android ortamı ve cihaz açılışı doğrulanır | Temel UI uygulandı; Android doğrulaması bekliyor |
| 3 | Uygulama özellikleri: modeller/sözleşmeler, mock destekli auth, not CRUD, gerçek dosya seçimi, keşif, detay, favoriler ve profil | Kullanıcı akışları Firebase olmadan çalışır | Kod uygulandı; final doğrulama sürüyor |
| 4 | Mock sistem ve testler: dört mock repository, kalıcılık, örnek dosyalar, hata/sahiplik ve uçtan uca testler | Mock kabul senaryoları geçer; Firebase entegrasyonuna hazır sözleşmeler | Kullanıcı talimatıyla başlatıldı; kalıcılık ve hata testleri sürüyor |
| 5 | Firebase entegrasyonu ve gerçek veri sistemi: Authentication, Firestore, Storage, repository implementasyonları, rules/index | Koleksiyon, güvenlik, dosya işlemleri emulator ve gerçek test projesinde doğrulanır; mock korunur | Bekliyor |
| 6 | Final testleri, hata düzeltmeleri ve APK oluşturma | Bütün özellikler gerçek Firebase ile test edilir; performans/UX kontrolü ve debug/release APK; ayrıca mock regresyon kontrolü | Bekliyor |

Her önemli değişiklikte README ve ilgili teknik belge, yeni dosyalarda ARCHITECTURE, görevlerde TASKS, ilerleme/hata çözümünde DEVELOPMENT güncellenir. Veri değişiklikleri DATABASE, Firebase değişiklikleri FIREBASE_SETUP, aşama değişiklikleri bu belgeye işlenir. İlgili belgeler güncellenmeden görev tamamlanmış sayılmaz. Her kod aşamasında analiz ve ilgili testler çalıştırılır; çalıştırılmayan kontroller ayrıca belirtilir.

## Mock sürüm kabul senaryosu

1. Aşama 4'te Firebase dosyaları ve hesabı olmadan uygulamayı çalıştır; Aşama 6'da mock APK üretim regresyonunu ayrıca kontrol et.
2. Demo kullanıcıyla giriş yap; yeni hesap oluştur; çıkış ve tekrar giriş yap.
3. Dosya seçiciyi aç, iptal et; desteklenmeyen ve 20 MiB üstü dosyaları reddet.
4. Eksik formu reddet; geçerli PDF/DOCX/görseli seçip not oluştur; ilerleme ve sonucu göster.
5. Yeni notu listede bul; başlık/ders/kategori/etiket filtrelerini ve sonraki sayfayı dene.
6. Detayda gerçek dosyayı görüntüle/aç ve cihazda seçilen konuma kaydet. Kaydetme tamamlandıktan sonra sayacı artır.
7. Favoriye ekle/çıkar; uygulamayı yeniden açıp durumun korunduğunu gör.
8. Diğer hesapla giriş yap; ilk kullanıcının favorilerini gösterme, notunu düzenletme/sildirtme.
9. Profil adını ve fotoğrafını değiştir; kendi notunu düzenle/sil; dosya temizliğini doğrula.
10. Eksik dosya, yazma hatası, bozuk yerel kayıt ve hızlı tekrar tıklama senaryolarını dene.

## Ürün kararları

- Popülerlik: ilk sürümde favori sayısı; en çok indirilen ayrı sıralama. Eşitlikte tarih ve ID ile kararlı sıralama.
- Not dosyası üst sınırı 20 MiB; avatar üst sınırı 5 MiB (JPG/JPEG/PNG).
- Paylaşım ve içerik erişimi oturum gerektirir; demo hesaplar açıkça örnektir.
- Tam metin arama ilk sürüm kapsamı dışındadır; başlık/ders kelime öneki ve tek etiket filtresi ortak sözleşmedir.
- Firebase'e geçerken UI ve Provider iş kuralları yeniden yazılmaz; veri/servis implementasyonları ve başlangıç yapılandırması değişir.


## Güncel durum — Aşama 5 hazırlığı

11 Kasım 2026: Firebase Auth/Firestore repository'leri, Firebase Storage servisi ve AppDependencies bağlantısı eklendi. Ayrı Firebase açılışı lib/main_firebase.dart; varsayılan lib/main.dart kalıcı mock olarak korunur. firebase.json, firestore.rules, storage.rules ve firestore.indexes.json eklendi. Yerel demo-notpaylas emulator'larında 16/16 güvenlik testi geçti; gerçek hesaba giriş, proje oluşturma veya deploy yapılmadı.

Bekleyenler: uygulama sahibinin bilgisayarında flutterfire configure ile gerçek options üretimi, test projesine kurallar/indekslerin uygulanması, kategorilerin yetkili olarak eklenmesi, gerçek repository ve Android/ağ kesintisi kabulü. Aşama 5 canlı bağlantı kabulü ve 6. aşama APK teslimi tamamlanmış değildir. Kurulum komutları ve bilinen sınırlar FIREBASE_SETUP.md içindedir.

Yeni rehber: [Başka bilgisayarda kurulum](docs/BASKA_BILGISAYARDA_KURULUM.md).
