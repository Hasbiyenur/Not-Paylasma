import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';

Future<void> openDocument(SelectedFile file) async {
  final directory = await getTemporaryDirectory();
  final path = '${directory.path}/${const Uuid().v4()}.${file.extension}';
  await File(path).writeAsBytes(file.bytes, flush: true);
  if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
    final result = await Process.run(
      Platform.isMacOS
          ? '/usr/bin/open'
          : Platform.isLinux
          ? 'xdg-open'
          : 'rundll32.exe',
      Platform.isWindows ? ['url.dll,FileProtocolHandler', path] : [path],
      runInShell: false,
    );
    if (result.exitCode != 0) {
      throw const AppException(
        'Dosya açılamadı. İndirip uygun uygulamayla açın.',
      );
    }
    return;
  }
  final result = await OpenFilex.open(path, type: file.mimeType);
  if (result.type != ResultType.done) {
    throw const AppException(
      'Dosyayı açacak uygulama bulunamadı veya erişim reddedildi. İndir seçeneğini kullanın.',
    );
  }
}
