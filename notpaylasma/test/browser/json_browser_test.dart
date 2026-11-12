@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/services/json_file_system_web.dart';
import 'package:notpaylas/core/services/local_json_dependencies.dart';
import 'package:notpaylas/models/note_model.dart';
import 'package:notpaylas/models/selected_file.dart';
import 'package:notpaylas/core/services/web_file_bytes.dart';
import 'package:notpaylas/core/utils/file_validator.dart';
import 'package:notpaylas/core/utils/image_file_validator.dart';
import 'package:web/web.dart' as web;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Salt okunur PDF baytları debug tarayıcı doğrulamasından geçer',
    () async {
      final data = await rootBundle.load('assets/data/files/ornek.pdf');
      final file = SelectedFile(
        'ders.pdf',
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      expect(() => FileValidator.validate(file), returnsNormally);
    },
  );
  test('PNG dosyası ve avatarı Flutter web görsel motoru çözer', () async {
    final data = await rootBundle.load('assets/data/files/ornek.png');
    final file = SelectedFile(
      'foto.png',
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    FileValidator.validate(file);
    FileValidator.validate(file, avatar: true);
    await ImageFileValidator.validate(file);
    await ImageFileValidator.validate(file, avatar: true);
  });
  test(
    'Salt okunur dosya baytları debug JS dosya API’sinde kullanılabilir',
    () async {
      final file = SelectedFile(
        'test.pdf',
        Uint8List.fromList([37, 80, 68, 70, 45]),
      );
      final blob = web.Blob([toWebFileBytes(file.bytes)].toJS);
      final buffer = (await blob.arrayBuffer().toDart).toDart;
      expect(buffer.asUint8List(), file.bytes);
    },
  );
  test(
    'Chrome OPFS: JSON, ek dosyası ve oturum kapat/aç sonrası okunur',
    () async {
      final root = await web.window.navigator.storage.getDirectory().toDart;
      final folder = await root
          .getDirectoryHandle(
            'notpaylas_test_${DateTime.now().microsecondsSinceEpoch}',
            web.FileSystemGetDirectoryOptions(create: true),
          )
          .toDart;
      final fs = BrowserJsonFileSystem(folder);
      var deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      await deps.auth.register(
        'Chrome',
        'Kullanıcı',
        'chrome@example.com',
        'ChromeSifre123!',
      );
      final data = await rootBundle.load('assets/data/files/ornek.pdf');
      final file = SelectedFile(
        'chrome.pdf',
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final note = await deps.notes.save(
        const NoteDraft(
          title: 'Chrome JSON dosyası',
          description: 'Tarayıcı yerel dosya sistemi testi.',
          courseName: 'Dart',
          categoryId: 'yazilim',
        ),
        file: file,
      );
      await deps.auth.signOut();
      await deps.close();
      deps = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      await deps.auth.signIn('chrome@example.com', 'ChromeSifre123!');
      expect((await deps.notes.getById(note.id))!.title, 'Chrome JSON dosyası');
      expect((await deps.files.read(note.storagePath)).bytes, file.bytes);
      final json =
          jsonDecode(utf8.decode((await fs.read('data.json'))!)) as Map;
      expect((json['data'] as Map)['notes'], hasLength(27));
      expect(await fs.read('does-not-exist.json'), isNull);
      await fs.delete('does-not-exist.json');
      await deps.close();
      await root
          .removeEntry(
            folder.name,
            web.FileSystemRemoveOptions(recursive: true),
          )
          .toDart;
    },
  );
}
