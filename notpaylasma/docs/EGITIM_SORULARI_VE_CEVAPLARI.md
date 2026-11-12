# NotPaylaş — Klasik sorular ve örnek cevaplar

Hazırlanma tarihi: 11 Kasım 2026. Düzey: temel–orta. Toplam 30 açık uçlu soru: 15 teorik, 15 teknik/uygulamalı. Cevaplar örnek cevap anahtarıdır; aynı anlamı doğru açıklayan farklı ifadeler de kabul edilebilir.

Kapsam: NotPaylaş'ın mevcut kaynakları ve eğitim referansının `_6kasim/altikasimiki` klasörü. Eğitim deposunun bütün dersleri incelenmiş sayılmaz. Referans klasörde sayaç, widget ve Analytics/Crashlytics/Remote Config servis örnekleri bulunur. Provider, repository, form ve not paylaşımı soruları NotPaylaş uygulamasından türetilmiştir. Authentication, Firestore ve Storage entegrasyonu mevcut projede yapılmamıştır; ilgili sorular 5. aşamaya hazırlık içindir. Örnek not ekleri kapsamlı ders materyali değildir.

## Teorik sorular

### 1. Flutter ile Dart arasındaki ilişkiyi açıklayınız. NotPaylaş projesinde görevleri nelerdir?

**Cevap:** Dart, uygulamanın yazıldığı programlama dilidir. Flutter ise Dart ile arayüz ve uygulama geliştirmeyi sağlayan araç takımıdır. NotPaylaş'ta modeller, doğrulamalar ve repository işlemleri Dart ile yazılır; ekranlar, formlar ve not kartları Flutter widget'larıyla oluşturulur. Ortak kod kullanılsa da dosya açma gibi platform davranışları ayrıca ele alınır.

### 2. StatelessWidget ve StatefulWidget arasındaki farkı birer örnekle açıklayınız.

**Cevap:** StatelessWidget kendi içinde değişken bir State nesnesi yönetmez; aldığı verilere göre arayüz üretir. Üst widget'tan gelen veri veya bağımlılık değişirse yeniden oluşturulabilir. StatefulWidget'ın değişen durumu ayrı bir State nesnesinde tutulur. Eğitimde MyApp stateless, sayacı yöneten MyHomePage stateful örneğidir. Bir formdaki seçili dosya da yerel durum örneğidir. [Flutter açıklaması](https://docs.flutter.dev/ui/interactivity)

### 3. setState metodunun amacı nedir? Her veri değişikliğinde kullanılması gerekir mi?

**Cevap:** setState, ilgili State nesnesinde arayüzü etkileyen bir değişiklik olduğunu bildirir ve yeniden build yapılmasını planlar. Tek başına veriyi diske kaydetmez. Yerel ekran durumunda uygundur; Provider tarafından yönetilen veride ChangeNotifier bildirimi gibi o yapının mekanizması kullanılır. Arayüzü etkilemeyen her değişken için setState çağırmak gerekli değildir.

### 4. initState, build ve dispose metotlarının görevlerini açıklayınız.

**Cevap:** initState, State nesnesi oluşturulurken bir kez çalışır ve uygun başlangıç işlemlerini yapar. build, widget ağacını üretir ve birçok kez çağrılabilir; her çağrıda kontrolsüz veri kaydı başlatılmamalıdır. dispose, ekranın ömrü sona ererken controller, zamanlayıcı ve abonelik gibi kaynakları bırakmak için kullanılır. Kaynakları açık bırakmak gereksiz işlem ve bellek kullanımına yol açabilir.

### 5. Dart'ta final, const ve nullable tür kavramlarını açıklayınız.

**Cevap:** final değişkenine bir kez değer atanır; değer çalışma anında belirlenebilir. const derleme zamanı sabitini ifade eder. final bir listeye yeniden atama yapılamaması, listenin elemanlarının değiştirilemeyeceği anlamına gelmez. String? gibi nullable türler null değerini kabul eder. NotPaylaş'ta seçilmemiş dosya veya henüz bulunmayan kullanıcı bilgisi uygun nullable türlerle temsil edilir.

### 6. Future ile Stream arasındaki fark nedir? async ve await ne işe yarar?

**Cevap:** Future, daha sonra tek bir değerle veya hatayla tamamlanan işlemi temsil eder. Stream zaman içinde birden fazla olay üretebilir. Dosya kaydetme Future, oturum değişikliklerini izleme Stream örneğidir. async ve await asenkron akışın okunabilir biçimde yazılmasını sağlar. await beklerken olay döngüsü başka işlere devam edebilir; ancak ağır senkron hesaplamayı kendiliğinden başka bir iş parçacığına taşımaz.

### 7. Verileri doğrudan Map ile taşımak yerine model sınıfları kullanmanın yararları nelerdir?

**Cevap:** Model sınıfları alanları ve türleri açıkça tanımlar; yanlış alan adı ve tür kullanımını azaltır. JSON dönüşümü, kopyalama ve ilgili veri davranışları belirli bir yerde tutulabilir. NotPaylaş'taki UserModel, NoteModel ve CategoryModel farklı veri sorumluluklarını ayırır. Model kullanılması, kullanıcıdan gelen verinin doğrulanması gereğini ortadan kaldırmaz.

### 8. Provider neden kullanılmıştır? Yerel durum ile paylaşılan durumu ayırınız.

**Cevap:** Oturum, favoriler ve tema gibi bilgiler birden fazla ekranı etkiler. Provider bu nesneleri widget ağacına sunar; ChangeNotifier kullanan sağlayıcılar değişiklikleri dinleyen arayüze bildirir. Şifreyi göster/gizle gibi yalnızca bir formu ilgilendiren durum yerel tutulabilir. Provider veri tabanı değildir ve tek başına kalıcı saklama sağlamaz.

### 9. Repository tasarımının amacı nedir? Firebase geçişini nasıl kolaylaştırır?

**Cevap:** Repository, veriye erişim davranışını bir sözleşme arkasında toplar. Ekranlar belleğe veya Firestore'a doğrudan bağlanmak yerine bu sözleşmeyle çalışır. MockNoteRepository ve ilerideki FirebaseNoteRepository aynı davranışı sağlarsa ekranların büyük ölçüde korunması mümkün olur. Geçişte repository ve dosya servisi implementasyonları ile başlangıç bağlaması değişir; hata, yetki ve sayfalama davranışları ayrıca doğrulanır.

### 10. Mock sistemin amacı ve sınırları nelerdir? Mevcut veriler uygulama yeniden açılınca ne olur?

**Cevap:** Mock sistem, dış servise ihtiyaç duymadan özellik geliştirmeyi ve kontrollü senaryoları test etmeyi sağlar. NotPaylaş'ın mevcut mock sistemi kayıtları ve dosya baytlarını bellekte tutar. Uygulama yeniden başlatıldığında veya web sayfası yenilendiğinde sonradan yapılan değişiklikler kaybolur, örnek veriler yeniden yüklenir. Mock başarısı gerçek ağ, sunucu güvenliği veya kalıcılık başarısının kanıtı değildir.

### 11. Navigator ile IndexedStack'in görevleri nasıl farklılaşır?

**Cevap:** Navigator, detay gibi ekranları bir route yığını üzerinden açma ve geri dönme işlemlerini yönetir. IndexedStack çocukları ağaçta tutarak seçilen sekmeyi gösterir; böylece sekmelerin yerel durumu korunabilir. NotPaylaş'ta beş ana sekme ile not detayına geçiş farklı ihtiyaçlardır. Oturum değiştiğinde eski kullanıcının ekran ağacının kaldırılması da önemlidir.

### 12. Kimlik doğrulama ile yetkilendirme arasındaki farkı NotPaylaş üzerinden açıklayınız.

**Cevap:** Kimlik doğrulama, kullanıcının kim olduğunu belirler. Yetkilendirme, o kullanıcının hangi işlemleri yapabileceğini belirler. Giriş yapmış bir kullanıcı notları görebilirken başka kullanıcının notunu silememelidir. Sil düğmesini gizlemek yeterli değildir; mevcut mock repository'de sahiplik, ileride uzak sistemde sunucu kuralları da denetlenmelidir.

### 13. Firebase Authentication, Cloud Firestore ve Cloud Storage hangi verilerden sorumlu olacaktır?

**Cevap:** Planlanan yapıda Authentication hesap, giriş ve kimlik işlemlerini; Firestore profil, kategori, not bilgileri ve favori kayıtlarını; Storage ise PDF, DOCX ve görsel dosyaların baytlarını yönetir. Bir notun başlığı Firestore'da, PDF içeriği Storage'da tutulur. Kullanıcı parolası profil belgesine yazılmaz. Bu üç bağlantı projede henüz uygulanmamıştır.

### 14. Eğitim örneğindeki Analytics ve Crashlytics servislerinin amaçlarını karşılaştırınız.

**Cevap:** Analytics örneği ekran görüntüleme, olay gönderme ve kullanıcı özelliği belirleme işlemlerini sarar; kullanım davranışını anlamaya yöneliktir. Crashlytics örneği kullanıcı kimliği, ek hata bağlamı, günlük ve fatal olmayan hata kaydı sağlar; hata nedenlerini incelemeye yöneliktir. Örnekteki kasıtlı çökertme metodu bir test aracıdır. Servis sınıflarının bulunması, uygulamanın başlatılıp veri gönderdiğinin kanıtı değildir. [Eğitim kaynağı](https://github.com/Hasbiyenur/SoftITo_Mobil_Uyg_Egitim/tree/e70b9a56fe529adad37c484d9653364a2963fc40/_6kasim/altikasimiki/lib/services)

### 15. Remote Config örneğinde varsayılan değerlerin ve hata yönetiminin önemi nedir?

**Cevap:** Örnekte kampanya metni ve zorunlu güncelleme gibi ayarlar tanımlanır. Varsayılanlar uzak değer alınamasa da uygulamanın anlamlı değerlerle çalışmasını sağlar. fetchAndActivate uzak değerleri alıp etkinleştirmeye çalışır. Örnekteki boş catch hatayı görünmez kılar; hata kaydedilip varsayılanlarla devam edilmesi daha izlenebilir bir yaklaşımdır. Remote Config erişim yetkisini güvenceye alan sunucu kurallarının yerine geçmez. [Eğitim kodu](https://github.com/Hasbiyenur/SoftITo_Mobil_Uyg_Egitim/blob/e70b9a56fe529adad37c484d9653364a2963fc40/_6kasim/altikasimiki/lib/services/remote_config_servisi.dart)

## Teknik ve uygulamalı sorular

### 16. Aşağıdaki sayaç kodunda arayüz neden hemen güncellenmeyebilir? Kodu düzeltiniz.

```dart
void artir() {
  sayac++;
}
```

**Cevap:** State içindeki değer değişir fakat Flutter'a yeniden build gerektiği bildirilmez. Başka bir nedenle build yapılana kadar ekranda eski değer kalabilir. Metot bir State sınıfındaysa şöyle düzeltilir:

```dart
void artir() {
  setState(() {
    sayac++;
  });
}
```

### 17. Not başlığının 3–120 karakter olmasını kontrol eden bir TextFormField doğrulaması yazınız. Kontrol neden repository'de de yapılmalıdır?

**Cevap:** Alanın validator'ı geçerli değerde null, hatalı değerde mesaj döndürür:

```dart
TextFormField(
  validator: (value) {
    final title = (value ?? '').trim();
    if (title.length < 3 || title.length > 120) {
      return 'Başlık 3–120 karakter olmalı.';
    }
    return null;
  },
)
```

Alan bir Form içinde kullanılmalı ve gönderimde `formKey.currentState!.validate()` kontrol edilmelidir. Repository başka ekran veya test tarafından doğrudan çağrılabildiğinden doğrulamayı tekrarlamalıdır. Gerçek Firebase aşamasında sunucu tarafı alan ve yetki doğrulaması da gerekir.

### 18. Asenkron kaydetme başarısız olduğunda yükleniyor göstergesi açık kalmaktadır. Olası nedeni ve çözümünü açıklayınız.

**Cevap:** Meşgul durumu yalnızca başarılı yolun sonunda sıfırlanıyorsa exception bu satıra ulaşılmasını engeller. İşlem try içinde beklenmeli, catch içinde uygun hata gösterilmeli, meşgul durumu finally içinde temizlenmelidir. Ekran await sırasında kapanmış olabileceğinden sonrasında context veya setState kullanılacaksa mounted kontrolü yapılmalıdır. İşlem sürerken tekrar gönderim de engellenmelidir.

### 19. Bir dosyanın adının .pdf ile bitmesi yükleme için yeterli midir? Projede hangi kontroller uygulanır?

**Cevap:** Yeterli değildir; uzantı değiştirilebilir. Mevcut uygulama izin verilen uzantıyı, sıfırdan büyük boyutu ve içerik imzasını kontrol eder; not eki sınırı 20 MiB, avatar sınırı 5 MiB'dir. DOCX için ZIP içindeki Office yapısı, seçilen görseller için okunabilirlik ve piksel sınırı da kontrol edilir. Bu kontroller zararlı içerik taraması değildir. Gelecekte uzak yükleme kuralları da ayrıca uygulanmalıdır.

### 20. Kullanıcı başka birinin not kimliğini göndererek silme işlemini çağırırsa ne olmalıdır?

**Cevap:** Repository aktif oturumu alır, notu bulur ve notun userId alanını oturumdaki uid ile karşılaştırır. Eşleşmiyorsa dosya veya not değiştirilmeden işlem reddedilir. Kullanıcının arayüzden gönderdiği sahiplik iddiasına güvenilmez. MockNoteRepository.delete bu kontrolü yapar; gerçek Firebase implementasyonunda uzak yetkilendirme de zorunludur.

### 21. Projedeki 26 not, sayfa boyutu 10 olacak şekilde nasıl listelenir? Aynı sıralama değerine sahip notlar nasıl ele alınır?

**Cevap:** Filtre olmadan sabit veri kümesinde sayfalar 10, 10 ve 6 not içerir. Mevcut mock son dönen notun kimliğini devam işareti olarak kullanır. Tarih veya sayaç eşitse kimlik ek sıralama ölçütüdür; böylece sıralama belirli olur. Filtre ya da sıralama değiştiğinde eski devam işareti bırakılıp ilk sayfa istenir. Bu yaklaşım değişen veri kümesinde kusursuz anlık görüntü garantisi vermez.

### 22. “Veri Yapıları” başlıklı bir not için “ver yap” ve “apı” aramaları nasıl sonuçlanır? Türkçe harfler nasıl ele alınır?

**Cevap:** Mevcut mock, arama terimlerinin her birinin başlık veya ders adındaki bir kelimenin başlangıcıyla eşleşmesini ister. Dolayısıyla “ver yap” eşleşir. Ders adında ek bir eşleşme yoksa “apı”, “Yapıları” kelimesinin içinden başladığı için eşleşmez. Normalleştirmede İ → i ve I → ı dönüşümü küçük harfe çevirmeden önce uygulanır; bu davranış Türkçe örneklerle test edilmelidir.

### 23. Aynı notun iki kez favoriye eklenmesi favori sayısını iki kez artırmalı mıdır? Açıklayınız.

**Cevap:** Hayır. Kullanıcı-not ilişkisi tektir; aynı hedef duruma tekrar geçme isteği sonucu değiştirmemelidir. Bu davranış idempotent olarak adlandırılır. Mock kullanıcı başına not kimliği kümesi tutar. Planlanan `users/{uid}/favorites/{noteId}` yolu da ilişkiye tek kimlik verir; gerçek sistemde ilişkiyle toplam sayının tutarlılığı eşzamanlı işlemler altında ayrıca korunmalıdır.

### 24. Ayşe'nin favori sorgusu sürerken Mehmet giriş yaparsa hangi sorun oluşabilir? Proje bunu nasıl önler?

**Cevap:** Eski sorgu geç tamamlanarak Ayşe'nin favorilerini Mehmet'in ekranına yazabilir. FavoriteProvider oturum değişince eski listeyi temizler. Her yenilemede sorgu nesli artırılır; sonucu dönen işlemin nesli güncel değilse cevap uygulanmaz. Böylece eski asenkron yanıt yeni kullanıcı durumunu ezmez. Bu istemci önlemi sunucu erişim kontrolünün yerine geçmez.

### 25. Notun dosyası değiştirilirken eski dosya hangi aşamada silinmelidir? Hata durumunu da açıklayınız.

**Cevap:** Önce yeni dosya yazılır, ardından not bilgileri yeni dosyaya bağlanır; eski dosya bundan sonra silinir. Önce eskisi silinirse yeni yüklemenin başarısız olması çalışan notu dosyasız bırakabilir. Yeni kayıt bağlanmadan hata oluşursa yeni dosya temizlenir. Kayıt başarılı, eski dosya temizliği başarısızsa yeni dosya korunmalı ve eski dosyanın temizliği yeniden denenmelidir. Uzak depoda bu çok adımlı işlem için ek kurtarma tasarımı gerekir.

### 26. Bir indirme düğmesine basılması, dosyanın diske başarıyla kaydedildiğini kanıtlar mı? Sayaç nasıl yorumlanmalıdır?

**Cevap:** Hayır; kullanıcı iptal edebilir veya kaydetme tamamlanmayabilir. Projedeki sonuç sözleşmesi iptal, kaydedildi ve tarayıcıya iletildi durumlarını ayırır. İptalde sayaç artırılmaz. Webde sayaç tarayıcıya gönderilen indirme isteğini temsil eder; fiziksel disk yazımının tamamlandığı söylenemez. Sayaç adı ve açıklaması ölçülen davranışla uyumlu olmalıdır.

### 27. Firebase implementasyonları eklenirken yapılandırmasız mock açılış nasıl korunabilir?

**Cevap:** Başlangıçta kullanılacak çalışma modu belirlenir. Mock modunda mock repository'ler ve yerel dosya servisi bağlanır; Firebase başlatılmaz. Firebase modunda gerçek proje seçenekleriyle initialize işlemi tamamlandıktan sonra gerçek implementasyonlar bağlanır. Firebase açıkça seçilmişken bağlantı hatası sessizce mock'a çevrilmez; kullanıcıya hata ve yeniden deneme sunulur. SDK paketlerini eklemek tek başına bağlantının kurulduğu anlamına gelmez. [Resmî Flutter/Firebase kurulumu](https://firebase.google.com/docs/flutter/setup)

### 28. Firestore'da yalnızca not sahibinin düzenleme yapabilmesi için hangi kontroller gerekir? userId alanı neden korunmalıdır?

**Cevap:** İstek kimliği doğrulanmış olmalı, mevcut belgedeki userId ile request.auth.uid eşleşmeli ve yeni veride sahiplik başka bir uid'ye çevrilememelidir. Oluşturmada gönderilen userId, oturum uid'siyle eşleşmelidir. İzin verilen alanlar, veri türleri ve ayrı yönetilen sayaçlar da kontrol edilmelidir. Bu, tam kural dosyası değil tasarım cevabıdır; güvenlik kuralları projede henüz uygulanmamıştır. [Firestore kural koşulları](https://firebase.google.com/docs/firestore/security/rules-conditions)

### 29. Not paylaşma özelliği için birim, widget ve entegrasyon testi örnekleri veriniz.

**Cevap:** Birim testinde repository'nin geçersiz başlığı veya yetkisiz düzenlemeyi reddettiği kontrol edilir. Widget testinde alan hatalarının ekranda görünmesi ve kaydetme sırasında düğmenin davranışı sınanır. Entegrasyon testinde hedef platformda gerçek dosya seçilerek not oluşturma, listeleme ve açma akışı denenir. Sahte dosya seçiciyle geçen widget testi gerçek Android seçicisini kanıtlamaz; Firebase kuralları da ayrı güvenlik testleri gerektirir.

### 30. Debug ve release APK'nın amaçlarını açıklayınız. Web derlemesinin geçmesi Android teslimi için yeterli midir?

**Cevap:** Debug APK geliştirme ve hata ayıklama içindir; release APK dağıtım için optimize edilir ve uygun imzalama süreciyle üretilir. Web derlemesi Android'in derlendiğini veya yerel dosya işlemlerinin çalıştığını göstermez. Android araç zinciri, gerçek cihaz/emülatör akışları, seçilen backend ve release imzası ayrıca doğrulanmalıdır. Proje planında Firebase entegrasyonu 5, gerçek bağlantıyla final testleri ve debug/release APK üretimi 6. aşamadadır.

## İncelenen proje kaynakları

- [Referans inceleme raporu](REFERENCE_REVIEW.md)
- [README](../README.md), [Mimari](../ARCHITECTURE.md), [Veri modeli](../DATABASE.md), [Firebase planı](../FIREBASE_SETUP.md)
- [NoteRepository](../lib/repositories/note_repository.dart), [MockNoteRepository](../lib/repositories/mock/mock_note_repository.dart)
- [FavoriteProvider](../lib/providers/favorite_provider.dart), [Validators](../lib/core/utils/validators.dart)
- [Repository testleri](../test/repositories/mock_repositories_test.dart), [Provider testleri](../test/providers/providers_test.dart), [Widget testleri](../test/widgets/app_test.dart)

Bu çalışma eğitim dokümanıdır; uygulama kodunu, veri modelini veya geliştirme aşamalarının tamamlanma durumunu değiştirmez.
