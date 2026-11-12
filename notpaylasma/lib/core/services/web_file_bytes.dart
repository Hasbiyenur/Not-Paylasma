import 'dart:js_interop';
import 'dart:typed_data';

/// JS interop debug derleyicisi salt okunur Dart Uint8List sarmalayıcısını
/// NativeUint8List olarak kabul etmez. Sınırda gerçek typed-array kopyası oluştur.
JSUint8Array toWebFileBytes(Uint8List bytes) => Uint8List.fromList(bytes).toJS;
