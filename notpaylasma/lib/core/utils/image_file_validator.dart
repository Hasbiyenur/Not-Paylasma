import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../models/selected_file.dart';
import 'app_exception.dart';
import 'file_validator.dart';

abstract final class ImageFileValidator {
  static const maxPixels = 24000000;

  static void _checkSize(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw const AppException('Görsel boyutları geçersiz.');
    }
    if (width * height > maxPixels) {
      throw const AppException('Görsel en fazla 24 megapiksel olabilir.');
    }
  }

  // Büyük bir görseli çözmeden önce PNG IHDR / JPEG SOF boyutlarını sınırla.
  static (int, int)? _headerSize(Uint8List bytes, String extension) {
    if (extension == 'png') {
      if (bytes.length < 24) return null;
      int word(int offset) =>
          bytes[offset] * 16777216 +
          bytes[offset + 1] * 65536 +
          bytes[offset + 2] * 256 +
          bytes[offset + 3];
      return (word(16), word(20));
    }
    var offset = 2;
    while (offset < bytes.length) {
      if (bytes[offset++] != 0xff) return null;
      while (offset < bytes.length && bytes[offset] == 0xff) {
        offset++;
      }
      if (offset >= bytes.length) return null;
      final marker = bytes[offset++];
      if (marker == 0xda || marker == 0xd9) return null;
      if (marker == 0x01 || (marker >= 0xd0 && marker <= 0xd8)) continue;
      if (offset + 1 >= bytes.length) return null;
      final length = bytes[offset] * 256 + bytes[offset + 1];
      if (length < 2 || offset + length > bytes.length) return null;
      if (const [
        0xc0,
        0xc1,
        0xc2,
        0xc3,
        0xc5,
        0xc6,
        0xc7,
        0xc9,
        0xca,
        0xcb,
        0xcd,
        0xce,
        0xcf,
      ].contains(marker)) {
        if (length < 7) return null;
        return (
          bytes[offset + 5] * 256 + bytes[offset + 6],
          bytes[offset + 3] * 256 + bytes[offset + 4],
        );
      }
      offset += length;
    }
    return null;
  }

  static Future<void> validate(SelectedFile file, {bool avatar = false}) async {
    FileValidator.validate(file, avatar: avatar);
    if (!const ['png', 'jpg', 'jpeg'].contains(file.extension)) {
      throw const AppException('PNG veya JPEG görsel seçin.');
    }
    final dimensions = _headerSize(file.bytes, file.extension);
    if (dimensions != null) _checkSize(dimensions.$1, dimensions.$2);
    try {
      // ImageDescriptor.encoded(...).width/height web'de desteklenmez.
      // Codec'in çözdüğü frame boyutları web ve native'de kullanılabilir.
      final codec = await ui.instantiateImageCodec(file.copyBytes());
      try {
        final frame = await codec.getNextFrame();
        try {
          _checkSize(frame.image.width, frame.image.height);
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        'Görsel dosyası okunamadı. Geçerli bir PNG veya JPEG seçin.',
      );
    }
  }
}
