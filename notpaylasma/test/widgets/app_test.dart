import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/services/app_dependencies.dart';
import 'package:notpaylas/core/services/app_scope.dart';
import 'package:notpaylas/core/services/device_file_service.dart';
import 'package:notpaylas/models/selected_file.dart';
import 'package:notpaylas/models/note_model.dart';
import 'package:notpaylas/shared/widgets/app_status_view.dart';

class FakeDeviceFiles implements DeviceFileService {
  SelectedFile? next;
  ExportResult result = ExportResult.saved;
  int exports = 0, opens = 0;
  @override
  Future<SelectedFile?> pick({bool avatar = false}) async => next;
  @override
  Future<ExportResult> export(SelectedFile file) async {
    exports++;
    return result;
  }

  @override
  Future<void> open(SelectedFile file) async {
    opens++;
  }
}

Future<AppDependencies> openApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool signedIn = true,
  FakeDeviceFiles? device,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final deps = (await tester.runAsync(
    () => AppDependencies.mock(device: device),
  ))!;
  if (signedIn) await deps.auth.signIn('ayse@example.com', 'NotPaylas123!');
  await tester.pumpWidget(AppScope(dependencies: deps));
  await tester.pumpAndSettle();
  addTearDown(() => deps.onDispose?.call());
  return deps;
}

Future<void> selectTab(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey('nav-$key')));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('Giriş formu doğrular ve demo hesabıyla oturum açar', (
    tester,
  ) async {
    await openApp(tester, signedIn: false);
    await tapVisible(tester, find.text('Giriş yap'));
    expect(find.text('Geçerli bir e-posta girin.'), findsOneWidget);
    expect(find.text('Şifrenizi girin.'), findsOneWidget);
    await tapVisible(tester, find.text('Ayşe ile demo girişi'));
    expect(find.text('Merhaba, Ayşe 👋'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
  testWidgets('Beş sekme, kısayollar ve geri çalışır', (tester) async {
    await openApp(tester);
    await tapVisible(tester, find.text('Keşfetmeye başla'));
    expect(find.text('Merak ettiğin her şey.'), findsOneWidget);
    await selectTab(tester, 'share');
    expect(find.text('Notu paylaş'), findsOneWidget);
    await selectTab(tester, 'favorites');
    await tapVisible(tester, find.text('Keşif alanına git'));
    expect(find.text('Merak ettiğin her şey.'), findsOneWidget);
    // İç Navigator'ın root route'u Android geri olayını kabuğa devreder.
    final navigator = Navigator.of(
      tester.element(find.text('Merak ettiğin her şey.')),
    );
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Merhaba, Ayşe 👋'), findsOneWidget);
  });
  testWidgets('Tema tercihi değişir; çıkış ve geri korumalı ekranı açmaz', (
    tester,
  ) async {
    await openApp(tester);
    await selectTab(tester, 'profile');
    await tapVisible(tester, find.byKey(const ValueKey('theme-dark')));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await selectTab(tester, 'home');
    await selectTab(tester, 'profile');
    await tapVisible(tester, find.byKey(const ValueKey('theme-light')));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tapVisible(tester, find.text('Çıkış yap'));
    expect(find.text('Tekrar hoş geldin.'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tekrar hoş geldin.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
  testWidgets('Hakkında penceresi Türkçe açılır ve kapatılır', (tester) async {
    await openApp(tester);
    await tester.tap(find.byTooltip('Uygulama hakkında'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutDialog), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutDialog), findsNothing);
  });
  for (final size in [const Size(320, 640), const Size(1024, 768)]) {
    testWidgets('${size.width} genişlikte yüzde 200 metin taşmaz', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openApp(tester, size: size);
      for (final tab in ['home', 'explore', 'share', 'favorites', 'profile']) {
        await selectTab(tester, tab);
        expect(tester.takeException(), isNull, reason: tab);
      }
    });
  }
  testWidgets('Arama sonucu değişir ve sonuçsuz durum gösterilir', (
    tester,
  ) async {
    await openApp(tester);
    await selectTab(tester, 'explore');
    await tester.enterText(
      find.byKey(const ValueKey('search-notes')),
      'olmayanbaslik',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Henüz not yok'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('search-notes')), 'Dart');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Dart ve koleksiyonlar • 1'), findsOneWidget);
  });
  testWidgets('Not formu doğrular; dosya iptali ve gerçek baytlı kayıt akışı', (
    tester,
  ) async {
    final device = FakeDeviceFiles();
    final deps = await openApp(tester, device: device);
    await selectTab(tester, 'share');
    await tapVisible(tester, find.text('Notu paylaş'));
    expect(find.text('Başlık 3–120 karakter olmalı.'), findsNothing);
    expect(find.text('Not başlığı 3–120 karakter olmalı.'), findsOneWidget);
    await tapVisible(tester, find.text('Dosya seç'));
    expect(find.text('Henüz dosya seçilmedi'), findsOneWidget);
    for (final entry in [
      ('Not başlığı', 'Yeni widget notu'),
      ('Açıklama', 'Widget ile paylaşılan geçerli açıklama.'),
      ('Ders adı', 'Mobil'),
    ]) {
      final finder = field(entry.$1);
      await tester.ensureVisible(finder);
      await tester.enterText(finder, entry.$2);
    }
    final dropdown = find.byType(DropdownButtonFormField<String>);
    await tapVisible(tester, dropdown);
    await tester.tap(find.text('Yazılım').last);
    await tester.pumpAndSettle();
    final data = await tester.runAsync(
      () => rootBundle.load('assets/mock/files/ornek.pdf'),
    );
    device.next = SelectedFile('widget.pdf', data!.buffer.asUint8List());
    await tapVisible(tester, find.text('Dosya seç'));
    await tapVisible(tester, find.text('Notu paylaş'));
    expect(
      (await deps.notes.query(const NoteQuery(search: 'Yeni widget')))
          .items
          .length,
      1,
    );
    expect(find.text('Not bu demo oturumuna eklendi.'), findsOneWidget);
  });
  testWidgets('Detay, favori, indirme iptali ve başarı sayacı', (tester) async {
    final device = FakeDeviceFiles();
    final deps = await openApp(tester, device: device);
    await tapVisible(tester, find.text('Notu incele').first);
    expect(find.text('Not detayı'), findsOneWidget);
    await tapVisible(tester, find.text('Favoriye ekle'));
    expect(await deps.favorites.getForCurrentUser(), contains('demo-note-000'));
    device.result = ExportResult.cancelled;
    await tapVisible(tester, find.text('İndir'));
    expect((await deps.notes.getById('demo-note-000'))!.downloadCount, 0);
    device.result = ExportResult.saved;
    await tapVisible(tester, find.text('İndir'));
    expect((await deps.notes.getById('demo-note-000'))!.downloadCount, 1);
    expect(device.exports, 2);
  });
  testWidgets('Yüklenme ve hata durumları ile tekrar deneme', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppStatusView(
            title: 'Yükleniyor',
            message: 'Bekleyin.',
            status: AppStatus.loading,
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppStatusView(
            title: 'Hata',
            message: 'Tekrar deneyin.',
            status: AppStatus.error,
            actionLabel: 'Tekrar dene',
            onAction: () => retries++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tekrar dene'));
    expect(retries, 1);
  });
}
