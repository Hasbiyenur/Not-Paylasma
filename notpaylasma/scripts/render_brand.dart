// Vektör logodan platform ikonlarını üretir.
// Çalıştırma: flutter test scripts/render_brand.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/shared/widgets/app_brand.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Marka ikonlarını vektör kaynaktan üret', () async {
    final targets = <String, int>{
      'assets/brand/notpaylas-logo.png': 1024,
      'web/favicon.png': 32,
      for (final size in [192, 512]) 'web/icons/Icon-$size.png': size,
      for (final size in [192, 512]) 'web/icons/Icon-maskable-$size.png': size,
      for (final size in [16, 32, 64, 128, 256, 512, 1024])
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png':
            size,
      for (final density in {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      }.entries)
        'android/app/src/main/res/mipmap-${density.key}/ic_launcher.png':
            density.value,
    };
    for (final entry in targets.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = entry.value.toDouble();
      if (entry.key.contains('maskable')) {
        canvas.drawColor(const Color(0xFF202C50), BlendMode.src);
        canvas.translate(size * .12, size * .12);
        const AppLogoPainter().paint(canvas, Size.square(size * .76));
      } else {
        const AppLogoPainter().paint(canvas, Size.square(size));
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(entry.value, entry.value);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(entry.key);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
      } finally {
        image.dispose();
        picture.dispose();
      }
    }
  });
}
