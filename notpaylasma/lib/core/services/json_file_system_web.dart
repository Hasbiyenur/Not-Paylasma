import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../utils/app_exception.dart';
import 'json_file_system.dart';
import 'web_file_bytes.dart';

Future<JsonFileSystem> openJsonFileSystem() async {
  try {
    final root = await web.window.navigator.storage.getDirectory().toDart;
    final folder = await root
        .getDirectoryHandle(
          'notpaylas_json',
          web.FileSystemGetDirectoryOptions(create: true),
        )
        .toDart;
    return BrowserJsonFileSystem(folder);
  } catch (_) {
    throw const AppException(
      'Yerel JSON dosyaları açılamadı. Chrome’da localhost veya HTTPS kullanın; site depolamasına izin verin.',
    );
  }
}

class BrowserJsonFileSystem implements JsonFileSystem {
  BrowserJsonFileSystem(this.root);
  final web.FileSystemDirectoryHandle root;
  @override
  String get location =>
      'Chrome yerel dosya alanı / notpaylas_json / data.json';
  Future<(web.FileSystemDirectoryHandle, String)> _parent(
    String path,
    bool create,
  ) async {
    final parts = safeLocalPath(path).split('/');
    var directory = root;
    for (final part in parts.take(parts.length - 1)) {
      directory = await directory
          .getDirectoryHandle(
            part,
            web.FileSystemGetDirectoryOptions(create: create),
          )
          .toDart;
    }
    return (directory, parts.last);
  }

  @override
  Future<Uint8List?> read(String path) async {
    try {
      final (directory, name) = await _parent(path, false);
      final handle = await directory.getFileHandle(name).toDart;
      final file = await handle.getFile().toDart;
      return (await file.arrayBuffer().toDart).toDart.asUint8List();
    } catch (error) {
      final exception = error as JSAny;
      if (exception.isA<web.DOMException>() &&
          (exception as web.DOMException).name == 'NotFoundError') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final (directory, name) = await _parent(path, true);
    final handle = await directory
        .getFileHandle(name, web.FileSystemGetFileOptions(create: true))
        .toDart;
    final stream = await handle.createWritable().toDart;
    try {
      await stream.write(toWebFileBytes(bytes)).toDart;
      await stream.close().toDart;
    } catch (_) {
      await stream.abort().toDart;
      rethrow;
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      final (directory, name) = await _parent(path, false);
      await directory.removeEntry(name).toDart;
    } catch (error) {
      final exception = error as JSAny;
      if (!exception.isA<web.DOMException>() ||
          (exception as web.DOMException).name != 'NotFoundError') {
        rethrow;
      }
    }
  }

  @override
  Future<void> locked(Future<void> Function() action) async {
    await web.window.navigator.locks
        .request('notpaylas-json-write', ((JSAny? _) => action().toJS).toJS)
        .toDart;
  }
}
