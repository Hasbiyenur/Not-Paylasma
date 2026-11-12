// Yerel istemci yapılandırmasını hazırlar; anahtar değerlerini yazdırmaz.
import 'dart:convert';
import 'dart:io';

void main() {
  final root = File.fromUri(Platform.script).parent.parent;
  final local = File('${root.path}/.local/firebase-keys.json');
  try {
    if (!local.existsSync()) {
      final generated = File(
        '${root.path}/.local/firebase_options.generated.dart',
      );
      if (!generated.existsSync()) {
        throw const FormatException(
          'Yerel Firebase ayarı eksik. SECURITY.md içindeki kurulumu tamamlayın.',
        );
      }
      final content = generated.readAsStringSync();
      if (!content.contains("projectId: 'not-paylasma-proje'")) {
        throw const FormatException(
          'Üretilen seçenekler beklenen Firebase projesine ait değil.',
        );
      }
      final pattern = RegExp(
        r"static const FirebaseOptions\s+(web|android|macos)\s*=\s*FirebaseOptions\([\s\S]*?apiKey:\s*'([^']+)'",
      );
      final values = <String, String>{};
      for (final match in pattern.allMatches(content)) {
        values['FIREBASE_${match[1]!.toUpperCase()}_API_KEY'] = match[2]!;
      }
      if (values.length != 3) {
        throw const FormatException('Üç platform seçeneği bulunamadı.');
      }
      local.parent.createSync(recursive: true);
      local.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(values),
      );
    }
    final keys = jsonDecode(local.readAsStringSync()) as Map<String, dynamic>;
    for (final platform in ['WEB', 'ANDROID', 'MACOS']) {
      final value = keys['FIREBASE_${platform}_API_KEY'];
      if (value is! String ||
          !RegExp(r'^AIza[0-9A-Za-z_-]{35}$').hasMatch(value)) {
        throw FormatException(
          '$platform için yerel Firebase anahtarı eksik/geçersiz.',
        );
      }
    }
    final output = File('${root.path}/android/app/google-services.json');
    if (!output.existsSync()) {
      final template = File(
        '${root.path}/android/app/google-services.example.json',
      );
      final config =
          jsonDecode(template.readAsStringSync()) as Map<String, dynamic>;
      for (final client in config['client'] as List) {
        for (final entry in client['api_key'] as List) {
          entry['current_key'] = keys['FIREBASE_ANDROID_API_KEY'];
        }
      }
      output.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(config),
      );
    }
    stdout.writeln(
      'Yerel Firebase yapılandırması hazır. Değerler Git dışında tutuluyor.',
    );
  } catch (_) {
    stderr.writeln(
      'Yerel Firebase yapılandırması hazırlanamadı. .local/firebase-keys.json ve SECURITY.md kurulumunu kontrol edin.',
    );
    exitCode = 1;
  }
}
