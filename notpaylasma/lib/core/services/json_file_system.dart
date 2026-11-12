import 'dart:typed_data';

abstract class JsonFileSystem {
  String get location;
  Future<Uint8List?> read(String path);
  Future<void> write(String path, Uint8List bytes);
  Future<void> delete(String path);
  Future<void> locked(Future<void> Function() action);
}

String safeLocalPath(String path) {
  if (path.isEmpty ||
      path.contains('\\') ||
      path
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw const FormatException('Geçersiz dosya yolu.');
  }
  return path;
}
