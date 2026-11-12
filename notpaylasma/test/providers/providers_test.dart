import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/services/app_dependencies.dart';
import 'package:notpaylas/core/utils/app_exception.dart';
import 'package:notpaylas/models/category_model.dart';
import 'package:notpaylas/models/note_model.dart';
import 'package:notpaylas/models/selected_file.dart';
import 'package:notpaylas/providers/auth_provider.dart';
import 'package:notpaylas/providers/category_provider.dart';
import 'package:notpaylas/providers/favorite_provider.dart';
import 'package:notpaylas/providers/note_provider.dart';
import 'package:notpaylas/repositories/category_repository.dart';
import 'package:notpaylas/repositories/favorite_repository.dart';

class DelayedFavorites implements FavoriteRepository {
  final requests = <Completer<Set<String>>>[];
  @override
  Stream<void> get changes => const Stream<void>.empty();
  @override
  Future<Set<String>> getForCurrentUser() {
    final result = Completer<Set<String>>();
    requests.add(result);
    return result.future;
  }

  @override
  Future<void> setFavorite(String id, bool value) async {}
}

class FailingCategories implements CategoryRepository {
  bool fails = true;
  @override
  Future<List<CategoryModel>> listCategories() async {
    if (fails) throw const AppException('Deneme hatası');
    return [const CategoryModel('test', 'Test', 'Açıklama')];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDependencies deps;
  setUp(() async {
    deps = await AppDependencies.mock();
    await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
  });
  tearDown(() => deps.onDispose?.call());
  test(
    'Geç dönen eski favori sorgusu yeni kullanıcı listesini ezmez',
    () async {
      final repository = DelayedFavorites();
      final provider = FavoriteProvider(repository, deps.auth);
      addTearDown(provider.dispose);
      final first = provider.reload();
      await deps.auth.signIn('mehmet@example.com', 'NotPaylas123!');
      await Future<void>.delayed(Duration.zero);
      final last = provider.reload();
      repository.requests.last.complete({'mehmet-notu'});
      await last;
      for (final request in repository.requests.take(
        repository.requests.length - 1,
      )) {
        request.complete({'ayse-notu'});
      }
      await first;
      expect(provider.ids, {'mehmet-notu'});
    },
  );
  test(
    'Favori provider kullanıcı değiştiğinde önceki hesabı temizler',
    () async {
      final provider = FavoriteProvider(deps.favorites, deps.auth);
      addTearDown(provider.dispose);
      await provider.toggle('demo-note-000');
      expect(provider.ids, contains('demo-note-000'));
      await deps.auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(provider.ids, isEmpty);
      await deps.auth.signIn('mehmet@example.com', 'NotPaylas123!');
      await provider.reload();
      expect(provider.ids, isEmpty);
      await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
      await provider.reload();
      expect(provider.ids, contains('demo-note-000'));
    },
  );
  test('Not provider hata sonrası meşgul durumunu bırakır', () async {
    final provider = NoteProvider(deps.notes);
    addTearDown(provider.dispose);
    const draft = NoteDraft(
      title: 'Valid',
      description: 'Geçerli açıklama',
      courseName: 'Ders',
      categoryId: 'yazilim',
    );
    await expectLater(provider.save(draft), throwsA(isA<AppException>()));
    expect(provider.saving, isFalse);
    final data = await rootBundle.load('assets/mock/files/ornek.pdf');
    await provider.save(
      draft,
      file: SelectedFile('test.pdf', data.buffer.asUint8List()),
    );
    expect(provider.saving, isFalse);
    expect(provider.progress, 1);
  });
  test('Profil fotoğrafı değiştirilir ve eski fotoğraf temizlenir', () async {
    final provider = AuthProvider(deps.auth, deps.files);
    addTearDown(provider.dispose);
    final data = await rootBundle.load('assets/mock/files/ornek.png');
    final photo = SelectedFile('foto.png', data.buffer.asUint8List());
    await provider.updateProfile('Ayşe', 'Yeni', photo);
    final oldPath = provider.user!.photoUrl!;
    expect((await deps.files.read(oldPath)).size, photo.size);
    await provider.updateProfile('Ayşe', 'Yeni', photo);
    expect(provider.user!.photoUrl, isNot(oldPath));
    await expectLater(deps.files.read(oldPath), throwsA(isA<AppException>()));
    expect(provider.busy, isFalse);
  });
  test(
    'Kategori hatası kullanıcıya taşınır ve tekrar deneme kurtarır',
    () async {
      final repository = FailingCategories();
      final provider = CategoryProvider(repository);
      addTearDown(provider.dispose);
      await provider.load();
      expect(provider.error, 'Deneme hatası');
      expect(provider.loading, isFalse);
      repository.fails = false;
      await provider.load();
      expect(provider.error, isNull);
      expect(provider.items.single.id, 'test');
    },
  );
}
