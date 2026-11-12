import 'dart:typed_data';

class SelectedFile {
  SelectedFile(this.name, Uint8List bytes)
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final String name;
  final Uint8List bytes;

  /// Flutter görsel motoru ve platform eklentileri salt okunur Dart
  /// sarmalayıcılarını debug web modunda kabul etmeyebilir.
  Uint8List copyBytes() => Uint8List.fromList(bytes);
  String get extension => name.split('.').last.toLowerCase();
  int get size => bytes.length;
  String get mimeType => switch (extension) {
    'pdf' => 'application/pdf',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };
}
