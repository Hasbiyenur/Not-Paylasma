# Veri modeli ve Firestore tasarımı

12 Kasım 2026 güncel model: Firebase Auth hesap ve parola; Firestore users/{uid} ad, soyad, e-posta ve tarihler. Fotoğraf alanı Firestore'da yoktur. JSON şema 2 kullanıcı profili/credentials/currentUid içermez; not, favori, kategori, tema ve localAvatars tutar. Dosyalar ayrı yereldir. Eski hesaplar geçici geçiş yedeğinden açık kullanıcı işlemiyle taşınır; ayrıntı docs/FIREBASE_HESAP_YEREL_DOSYALAR.md.

Güncel uygulama varsayılanı yerel JSON'dur: `data.json` zarfı `revision` ve `data` içerir. `data` içinde schemaVersion, users, credentials (salt/hash), categories, notes, favorites, currentUid ve theme vardır. Ekler ayrı yerel dosyalardır. Önceki Sembast/Firestore tasarımı aşağıda tarihçe olarak korunur. Ayrıntı: docs/YEREL_JSON_KAYIT.md.

## Aşama 4 yerel kayıt — doğrulama sürüyor

Firebase henüz yoktur. Sembast/IndexedDB içinde metadata/state kaydı revision ve state içerir. state.schemaVersion = 1; users, credentials (demo salt/hash), notes, favorites, currentUid ve theme saklanır. Kategoriler sabit örnek katalogdur. files kayıt anahtarı storagePath; alanları name, size, data (base64), sha256, createdAt. Tek dosya kaydı atomiktir; metadata değişikliği ayrı atomik işlemle bağlanır. Uygulama kapanmasıyla yarım kalan dosya, 24 saat geçtikten sonraki açılışta sahipsizse temizlenir. Bozuk veya bilinmeyen şema otomatik sıfırlanmaz. Reset kodları kalıcı değildir. Veritabanı şifrelenmiş değildir; gerçek parola/özel belge için üretim sistemi sayılmaz.

Bu belge uygulanacak sözleşmedir; henüz Firebase veritabanı veya yerel kayıt dosyası oluşturulmadı. Örnekler sentetiktir. Tarihler JSON'da ISO 8601 UTC, Dart'ta DateTime, 5. aşamada Firestore adapter'ında Timestamp olarak saklanır.

Modeller ve mock destekli özellikler Aşama 3'te uygulandı. Kalıcılık Aşama 4, gerçek koleksiyon/rules doğrulaması Aşama 5, gerçek verilerle final kabul Aşama 6'dadır. Aşağıdaki Firestore şeması hedef tasarımdır; mevcut bellek modeli farkları belgenin sonundadır.

## Modeller

| Model / yol | Alanlar |
| --- | --- |
| UserModel — users/{uid} | uid, firstName, lastName, email, photoUrl (nullable), createdAt, updatedAt |
| NoteModel — notes/{id} | id, title, description, courseName, categoryId, university (nullable), tags, userId, userName, fileName, fileUrl (nullable), storagePath, fileType, fileSize, downloadCount, favoriteCount, createdAt, updatedAt |
| CategoryModel — categories/{id} | id, name, description, icon, createdAt |
| Favorite — users/{uid}/favorites/{noteId} | noteId, createdAt |

`fileSize` byte cinsinden pozitif tamsayıdır. İndirme/favori sayıları sıfır veya pozitif tamsayıdır. `fileType` normalize edilmiş uzantıdır. Kategori ikonu taşınabilir anahtardır (ör. `code`), Flutter IconData nesnesi değildir.

`favoriteCount` popüler sıralama için eklenmiştir. `searchPrefixes` ve `tagsNormalized` Firebase sorguları için adapter tarafından türetilen alanlardır; UI bu alanları düzenlemez. Parola kullanıcı profil belgesine yazılmaz. İleride başka kullanıcılara gösterilen profil için e-posta dahil özel users belgeleri açılmaz; not üzerindeki `userName` kullanılır veya ayrı güvenli herkese açık profil görünümü tasarlanır.

## Örnek kayıtlar

```json
{
  "uid": "demo-ayse",
  "firstName": "Ayşe",
  "lastName": "Yılmaz",
  "email": "ayse@example.com",
  "photoUrl": null,
  "createdAt": "2026-11-01T09:00:00Z",
  "updatedAt": "2026-11-01T09:00:00Z"
}
```

```json
{
  "id": "yazilim",
  "name": "Yazılım",
  "description": "Programlama ve mobil uygulama dersleri",
  "icon": "code",
  "createdAt": "2026-11-01T09:00:00Z"
}
```

```json
{
  "id": "demo-note-001",
  "title": "Dart Temelleri",
  "description": "Değişkenler, koleksiyonlar ve fonksiyonlar için çalışma notu.",
  "courseName": "Mobil Programlama",
  "categoryId": "yazilim",
  "university": null,
  "tags": ["dart", "flutter"],
  "userId": "demo-ayse",
  "userName": "Ayşe Yılmaz",
  "fileName": "dart-temelleri.pdf",
  "fileUrl": null,
  "storagePath": "mock/files/demo-note-001/dart-temelleri.pdf",
  "fileType": "pdf",
  "fileSize": 2048,
  "downloadCount": 8,
  "favoriteCount": 3,
  "createdAt": "2026-11-10T09:00:00Z",
  "updatedAt": "2026-11-10T09:00:00Z"
}
```

Yukarıdaki yol ve boyut şema örneğidir. Gerçek örnek dosyalar assets/mock/files/ornek.pdf, ornek.docx ve ornek.png altındadır; seed gerçek byte boyutlarını kullanır.

```json
{
  "noteId": "demo-note-001",
  "createdAt": "2026-11-11T09:00:00Z"
}
```

Favori örneğinin yolu `users/demo-mehmet/favorites/demo-note-001` olur. Her kullanıcının aynı nota ait tek favorisi bulunur. İlk demo kümesi Ayşe ve Mehmet hesaplarını; Yazılım, Matematik, Fizik ve Dil kategorilerini; PDF, DOCX ve görsel örneklerini kapsayacak. Sayfalama için en az 25 not hazırlanacak.

## İlişkiler ve bütünlük

- `notes.userId → users.uid`, `notes.categoryId → categories.id`.
- Favori belge ID'si not ID'sidir. Silinmiş notlara ait favoriler listede gösterilmez; kalan belgeler temizleme sürecine alınır.
- `userName` not üzerindeki görüntüleme kopyasıdır. Profil değişince kullanıcının notlarındaki adın güncellenmesi mock'ta aynı depoda, Firebase'de tekrar denenebilir iş olarak ele alınır.
- Mock `storagePath` yerel dosya servisi tarafından çözülür. Firebase yolu `notes/{uid}/{noteId}/{fileId}` olur; avatar yolu `avatars/{uid}/{fileId}`.
- Firebase'de oturumla yetkili SDK indirmesi tercih edilir. Paylaşıldığında kimlik denetimini aşabilen kalıcı indirme token URL'leri özel dosya erişim mekanizması olarak kullanılmaz; fileUrl null kalabilir.

## Doğrulama sınırları

Başlık 3–120, açıklama 10–3000, ders 2–100 karakter; ad/soyad 1–60 karakter; üniversite en çok 160 karakter. En çok 5 etiket, her biri 2–30 karakter. Boşluklar kırpılır; boş etiketler çıkarılır ve tekrarlar birleştirilir. E-posta biçimi ve en az 8 karakter demo şifre politikası formda/repository'de doğrulanır; gerçek Auth politikası 5. aşamada bununla uyumlu ayarlanır.

Dosya 0 < boyut ≤ 20 MiB; PDF, DOCX, JPG, JPEG, PNG. Uzantı tek başına yeterli kabul edilmez: MIME ve dosya imzası kontrol edilir; DOCX için ZIP içindeki Office yapısı doğrulanır. Bunlar zararlı içerik taraması değildir. Avatar yalnızca görsel ve ≤ 5 MiB.

## Arama ve sayfalama

Mevcut mock arama davranışı: Türkçe I/İ/ı/i dönüşümü tanımlanmış normalize kelime öneki araması; başlık ve ders aynı arama alanına katkı verir. Tek arama ifadesi ve isteğe bağlı tek etiket desteklenir. Mock aynı anlamı uygular; sınırsız substring araması sunup Firebase'e geçince işlev kaybı yaratmaz.

Planlanan Firestore Standard yaklaşımı: başlık/ders kelimelerinden sınırlı sayıda `searchPrefixes` dizisi, sorguda `array-contains`; kategori için equality, sıralama için orderBy. Etiket yalnızken `tagsNormalized array-contains` kullanılır. Metin ve etiket birlikteyse iki array-contains kullanmak yerine metin sorgusunun sayfaları repository içinde taranır, etiket filtrelenir. Cursor son döndürülen değil son taranan belgeyi izler; boş sayfa ve devam ihtimali açıkça taşınır. Büyük veri için ayrı arama servisine geçiş repository içinde yapılır.

Bu tasarım tam metin arama vaadi değildir. Güncel Firebase arama belgesi Enterprise metin aramasına yönlenmektedir; bu ayrı ürün özelliği ilk sürümün Standard SDK sorgu planıyla karıştırılmayacak. 5. aşamada ürün/sorgu desteği tekrar kontrol edilecek.

Mevcut mock UI her sayfada 10 öğe kullanır (ana sayfa bölümleri 3 öğe). Firestore hedef sayfa boyutu 20 olarak değerlendirilecektir; `createdAt DESC, documentId DESC` veya `downloadCount DESC, documentId DESC` veya `favoriteCount DESC, documentId DESC`. Firebase adapter'ı `startAfterDocument` kullanır. Filtre değiştiğinde yeni sorgu başlatılır. Çoklu sıralama alanları içeren cursor değerleri ve eşitlik durumları test edilir.

## Composite index planı

`notes` collection scope için, her satır sonuna sorgunun `__name__ DESC` sırası eklenir:

| Filtre | Sıralama/index alanları |
| --- | --- |
| categoryId | categoryId ASC + createdAt DESC / downloadCount DESC / favoriteCount DESC (ayrı index'ler) |
| userId | userId ASC + createdAt DESC |
| searchPrefixes | searchPrefixes ARRAY_CONTAINS + seçilen sıralama alanı DESC |
| categoryId + searchPrefixes | categoryId ASC + searchPrefixes ARRAY_CONTAINS + seçilen sıralama alanı DESC |
| tagsNormalized | tagsNormalized ARRAY_CONTAINS + seçilen sıralama alanı DESC |
| categoryId + tagsNormalized | categoryId ASC + tagsNormalized ARRAY_CONTAINS + seçilen sıralama alanı DESC |

Sıralama alanı tek başına olan sorgular önce otomatik index'lerle denenir. Kesin `firestore.indexes.json` 5. aşamada gerçekten kullanılan sorgulardan üretilecek ve hedef test projesinde doğrulanacak. Uzun açıklama alanı sorgulanmayacak; gereksiz index maliyeti önlenecek.

## Sayaçlar ve tutarlılık

Mock indirme sayacı, dosyanın kaydı başarıyla tamamlandıktan sonra seri yazmayla artırılır. Firebase için atomik increment/transaction planlanır; diğer not alanlarına yazma izni verilmez. İstemci olayı bir insanın benzersiz indirmesini kanıtlamaz; kötüye kullanıma dayanıklı sayaç gerekirse kimliği doğrulayan sunucu işlemi ve tekrar önleme anahtarı gerekir.

Mock favori ve favoriteCount aynı yerel işlemde güncellenir. Firebase'de favori oluşturma/silme ile sayaç değişimi aynı transaction ve kurallarda belge varlığı/önceki durum kontrolüyle doğrulanacak; sahibi bile favoriteCount'u keyfi değiştiremeyecek. 5. aşama sözleşme ve güvenlik testleri bu tutarlılığı kapsar.

Kaynaklar: [Firestore cursor sayfalama](https://firebase.google.com/docs/firestore/query-data/query-cursors), [güncel metin arama belgesi](https://firebase.google.com/docs/firestore/enterprise/text-search).

## Aşama 3 gerçek uygulama durumu

UserModel ve NoteModel JSON dönüşümleri uygulandı. Kategori modeli şu an id/name/description içerir; icon/createdAt Firebase adapter aşamasında eklenecek plan alanlarıdır. NoteModel fileUrl kullanmaz; storagePath FileStorageService anahtarıdır. MockStore bellek içinde users/credentials/notes/favorites tutar. Parolalar profil JSON'unda yoktur; ayrı oturumluk credential haritasında rastgele salt ve SHA-256 özeti vardır. Bu yalnızca demo doğrulamasıdır, üretim parola saklama çözümü değildir. Demo sıfırlama kodu 5 dakika ve 5 denemeyle sınırlandırılır; kod ekranda görünür, e-posta gönderilmez.

İki örnek kullanıcı, dört kategori, 26 örnek metadata kaydı ve üç gerçek örnek dosya eklendi. Not açıklamaları örnek ekin dersin tam içeriği olmadığını belirtir. Yeniden başlatmada veriler yeniden tohumlanır. Uzak koleksiyon oluşturulmadı. Kategori, başlık/ders kelime öneki, etiket, sıralama ve ID cursor ile sayfalama mock repository'de uygulanıyor. Tarayıcı indirmenin diskte tamamlandığını bildiremediğinden web indirme sayacı kabul edilen indirme isteğini sayar; Android adapter'ında saveFile sonucu esas alınır.

Aşama 4 sonucu: yerel Sembast/IndexedDB kayıtları ve tekrar açılış doğrulandı. Önceki Aşama 3 oturumluk kayıt açıklaması yalnızca bellek test moduna aittir. Normal başlangıç mevcut kaydı geri yükler. Firebase koleksiyonları henüz oluşturulmadı.
