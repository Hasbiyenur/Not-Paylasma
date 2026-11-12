import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/services/app_dependencies.dart';
import 'package:notpaylas/core/utils/app_exception.dart';
import 'package:notpaylas/core/utils/file_validator.dart';
import 'package:notpaylas/models/note_model.dart';
import 'package:notpaylas/models/selected_file.dart';
import 'package:notpaylas/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDependencies deps;
  late SelectedFile pdf;
  const draft = NoteDraft(
    title: 'Dart test notu',
    description: 'Geçerli bir çalışma açıklaması.',
    courseName: 'Mobil Programlama',
    categoryId: 'yazilim',
    tags: ['dart'],
  );
  setUp(() async {
    deps = await AppDependencies.mock();
    final data = await rootBundle.load('assets/mock/files/ornek.pdf');
    pdf = SelectedFile('ders.pdf', data.buffer.asUint8List());
    await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
  });
  tearDown(() => deps.onDispose?.call());

  test('Yanlış şifre reddedilir, kayıt e-posta çakışmasını denetler', () async {
    await deps.auth.signOut();
    await expectLater(
      deps.auth.signIn('ayse@example.com', 'yanlis'),
      throwsA(isA<AppException>()),
    );
    expect(deps.auth.currentUser, isNull);
    await deps.auth.register(
      'Yeni',
      'Öğrenci',
      ' YENI@example.com ',
      'Deneme123!',
    );
    expect(deps.auth.currentUser!.email, 'yeni@example.com');
    await expectLater(
      deps.auth.register('Başka', 'Kişi', 'yeni@example.com', 'Deneme123!'),
      throwsA(isA<AppException>()),
    );
  });
  test('Girişsiz not ve favori erişimi reddedilir', () async {
    await deps.auth.signOut();
    await expectLater(
      deps.notes.query(const NoteQuery()),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      deps.favorites.getForCurrentUser(),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      deps.notes.save(draft, file: pdf),
      throwsA(isA<AppException>()),
    );
  });
  test(
    'Demo kod yanlışsa reddedilir, bir kez kullanılır ve yeni şifre işler',
    () async {
      final request = await deps.auth.requestPasswordReset('ayse@example.com');
      await expectLater(
        deps.auth.confirmPasswordReset(request.id, 'wrong', 'Degisti123!'),
        throwsA(isA<AppException>()),
      );
      await deps.auth.confirmPasswordReset(
        request.id,
        request.demoCode!,
        'Degisti123!',
      );
      expect(deps.auth.currentUser, isNull);
      await expectLater(
        deps.auth.signIn('ayse@example.com', 'NotPaylas123!'),
        throwsA(isA<AppException>()),
      );
      await deps.auth.signIn('ayse@example.com', 'Degisti123!');
      await expectLater(
        deps.auth.confirmPasswordReset(
          request.id,
          request.demoCode!,
          'Again123!',
        ),
        throwsA(isA<AppException>()),
      );
    },
  );
  test('Demo sıfırlama beş hatalı denemeden sonra kilitlenir', () async {
    final request = await deps.auth.requestPasswordReset('ayse@example.com');
    for (var i = 0; i < 5; i++) {
      await expectLater(
        deps.auth.confirmPasswordReset(request.id, '000000', 'Deneme123!'),
        throwsA(isA<AppException>()),
      );
    }
    await expectLater(
      deps.auth.confirmPasswordReset(
        request.id,
        request.demoCode!,
        'Deneme123!',
      ),
      throwsA(isA<AppException>()),
    );
  });
  test('Not oluşturma gerçek baytları saklar, ilerleme 1 olur', () async {
    final progress = <double>[];
    final note = await deps.notes.save(
      draft,
      file: pdf,
      onProgress: progress.add,
    );
    expect(note.userId, 'demo-ayse');
    expect((await deps.files.read(note.storagePath)).bytes, pdf.bytes);
    expect(progress.last, 1);
    expect(
      (await deps.notes.query(const NoteQuery(search: 'Dart test'))).items
          .map((n) => n.id),
      contains(note.id),
    );
  });
  test('Başkasının notu değiştirilemez veya silinemez', () async {
    await expectLater(
      deps.notes.save(draft, id: 'demo-note-001'),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      deps.notes.delete('demo-note-001'),
      throwsA(isA<AppException>()),
    );
    expect(await deps.notes.getById('demo-note-001'), isNotNull);
  });
  test(
    'Düzenleme sayaçları korur; dosya değiştirme eski dosyayı temizler',
    () async {
      final note = await deps.notes.save(draft, file: pdf);
      await deps.notes.recordDownload(note.id);
      await deps.favorites.setFavorite(note.id, true);
      final edited = await deps.notes.save(draft, id: note.id, file: pdf);
      expect(edited.downloadCount, 1);
      expect(edited.favoriteCount, 1);
      expect(edited.storagePath, isNot(note.storagePath));
      await expectLater(
        deps.files.read(note.storagePath),
        throwsA(isA<AppException>()),
      );
    },
  );
  test('Favori idempotent ve kullanıcıya özel; silme tüm artık favorileri temizler', () async {
    final note = await deps.notes.save(draft, file: pdf);
    await deps.favorites.setFavorite(note.id, true);
    await deps.favorites.setFavorite(note.id, true);
    expect((await deps.notes.getById(note.id))!.favoriteCount, 1);
    await deps.auth.signIn('mehmet@example.com', 'NotPaylas123!');
    expect(await deps.favorites.getForCurrentUser(), isEmpty);
    await deps.favorites.setFavorite(note.id, true);
    await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
    await deps.notes.delete(note.id);
    expect(await deps.favorites.getForCurrentUser(), isEmpty);
    await expectLater(
      deps.files.read(note.storagePath),
      throwsA(isA<AppException>()),
    );
    await deps.auth.signIn('mehmet@example.com', 'NotPaylas123!');
    expect(await deps.favorites.getForCurrentUser(), isEmpty);
  });
  test('Sayfalama bütün 26 notu birer kez getirir ve sonunda biter', () async {
    final ids = <String>[];
    String? cursor;
    do {
      final page = await deps.notes.query(NoteQuery(limit: 7, cursor: cursor));
      ids.addAll(page.items.map((n) => n.id));
      cursor = page.nextCursor;
    } while (cursor != null);
    expect(ids.length, 26);
    expect(ids.toSet().length, 26);
  });
  test('Türkçe arama, kategori, etiket ve sıralama birlikte çalışır', () async {
    final page = await deps.notes.query(
      const NoteQuery(search: 'İNG', categoryId: 'dil', tag: 'gramer'),
    );
    expect(page.items, isNotEmpty);
    expect(page.items.every((n) => n.categoryId == 'dil'), isTrue);
    expect(
      (await deps.notes.query(const NoteQuery(tag: 'bulunmayan'))).items,
      isEmpty,
    );
    await deps.notes.recordDownload('demo-note-002');
    expect(
      (await deps.notes.query(const NoteQuery(sort: NoteSort.downloads)))
          .items
          .first
          .id,
      'demo-note-002',
    );
  });
  test('Profil adı kendi notlarına yansır, diğer yazara dokunmaz', () async {
    await deps.auth.updateProfile('Ayşe Yeni', 'Yılmaz');
    expect(
      (await deps.notes.getById('demo-note-000'))!.userName,
      'Ayşe Yeni Yılmaz',
    );
    expect(
      (await deps.notes.getById('demo-note-001'))!.userName,
      'Mehmet Demir',
    );
  });
  test('JSON model dönüşümleri veri kaybetmez', () async {
    final user = deps.auth.currentUser!;
    expect(UserModel.fromJson(user.toJson()).toJson(), user.toJson());
    final note = (await deps.notes.getById('demo-note-000'))!;
    expect(NoteModel.fromJson(note.toJson()).toJson(), note.toJson());
    expect(() => NoteModel.fromJson({'id': 123}), throwsA(isA<TypeError>()));
  });
  test('Tür, imza, boyut, boş dosya ve avatar sınırları doğrulanır', () {
    FileValidator.validate(pdf);
    for (final file in [
      SelectedFile('bad.pdf', Uint8List.fromList([1, 2, 3])),
      SelectedFile('bad.exe', pdf.bytes),
      SelectedFile('empty.pdf', Uint8List(0)),
      SelectedFile('huge.pdf', Uint8List(20 * 1024 * 1024 + 1)),
    ]) {
      expect(() => FileValidator.validate(file), throwsA(isA<AppException>()));
    }
    expect(
      () => FileValidator.validate(pdf, avatar: true),
      throwsA(isA<AppException>()),
    );
  });
  test('Geçersiz form repository seviyesinde de reddedilir', () async {
    await expectLater(
      deps.notes.save(
        const NoteDraft(
          title: 'x',
          description: '',
          courseName: 'a',
          categoryId: 'fake',
        ),
        file: pdf,
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(deps.notes.save(draft), throwsA(isA<AppException>()));
  });
  test('Kaydın ortasında oturum değişirse yarım not oluşmaz', () async {
    var changed = false;
    await expectLater(
      deps.notes.save(
        draft,
        file: pdf,
        onProgress: (_) {
          if (!changed) {
            changed = true;
            deps.auth.signOut();
          }
        },
      ),
      throwsA(isA<AppException>()),
    );
    await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
    expect(
      (await deps.notes.query(const NoteQuery(limit: 100))).items.length,
      26,
    );
  });
}
