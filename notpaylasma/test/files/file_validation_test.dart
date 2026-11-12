import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/utils/app_exception.dart';
import 'package:notpaylas/core/utils/file_validator.dart';
import 'package:notpaylas/core/utils/image_file_validator.dart';
import 'package:notpaylas/models/selected_file.dart';

Future<SelectedFile> assetFile(String extension) async {
  final data = await rootBundle.load('assets/data/files/ornek.$extension');
  return SelectedFile(
    'dosya.$extension',
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'PDF salt okunur dosya baytlarından doğrulanır, eksik son imza reddedilir',
    () async {
      final file = await assetFile('pdf');
      expect(() => FileValidator.validate(file), returnsNormally);
      final truncated = SelectedFile('eksik.pdf', file.bytes.sublist(0, 20));
      expect(
        () => FileValidator.validate(truncated),
        throwsA(isA<AppException>()),
      );
    },
  );
  test(
    'PNG not eki ve profil fotoğrafı gerçek görsel motorunda okunur',
    () async {
      final file = await assetFile('png');
      await ImageFileValidator.validate(file);
      await ImageFileValidator.validate(file, avatar: true);
    },
  );
  test('Piksel sınırını aşan PNG çözülmeden reddedilir', () async {
    final file = await assetFile('png');
    final bytes = file.copyBytes();
    for (final offset in [16, 20]) {
      bytes[offset] = 0;
      bytes[offset + 1] = 0;
      bytes[offset + 2] = 0x13;
      bytes[offset + 3] = 0x88;
    }
    await expectLater(
      ImageFileValidator.validate(SelectedFile('buyuk.png', bytes)),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('24 megapiksel'),
        ),
      ),
    );
  });
  test('Sadece PNG imzası taşıyan bozuk görsel kabul edilmez', () async {
    final file = SelectedFile(
      'bozuk.png',
      Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
    );
    await expectLater(
      ImageFileValidator.validate(file),
      throwsA(isA<AppException>()),
    );
  });
  test(
    'Platform kopyası değişse de dosyanın orijinal baytları korunur',
    () async {
      final file = await assetFile('png');
      final copy = file.copyBytes();
      copy[0] = 0;
      expect(file.bytes[0], 137);
      expect(() => file.bytes[0] = 0, throwsUnsupportedError);
    },
  );
}
