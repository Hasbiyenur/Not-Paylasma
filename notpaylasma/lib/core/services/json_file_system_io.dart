import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'json_file_system.dart';

Future<JsonFileSystem> openJsonFileSystem() async {
  final directory = await getApplicationSupportDirectory();
  return DiskJsonFileSystem(Directory('${directory.path}/notpaylas_json'));
}

class DiskJsonFileSystem implements JsonFileSystem {
  DiskJsonFileSystem(this.directory);
  final Directory directory;
  @override
  String get location => directory.path;
  File _file(String path) => File('${directory.path}/${safeLocalPath(path)}');
  @override
  Future<Uint8List?> read(String path) async {
    final file = _file(path);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final target = _file(path);
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.${const Uuid().v4()}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<void> delete(String path) async {
    final target = _file(path);
    if (await target.exists()) await target.delete();
  }

  @override
  Future<void> locked(Future<void> Function() action) async {
    await directory.create(recursive: true);
    final handle = await File('${directory.path}/write.lock')
        .open(mode: FileMode.append);
    try {
      await handle.lock(FileLock.blockingExclusive);
      await action();
    } finally {
      await handle.close();
    }
  }
}
