import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/utils/app_exception.dart';
import 'package:notpaylas/main.dart';

void main() {
  testWidgets('Eksik Firebase ayarı hata verir ve mock moda dönmez', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      NotPaylasBootstrap(
        loadDependencies: () {
          attempts++;
          throw const AppException(
            'Firebase yapılandırılmadı. flutterfire configure çalıştırın.',
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Uygulama açılamadı'), findsOneWidget);
    expect(find.textContaining('flutterfire configure'), findsOneWidget);
    expect(find.text('Ayşe ile demo girişi'), findsNothing);
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Uygulama açılamadı'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
