import 'package:firebase_storage/firebase_storage.dart';

import '../../models/selected_file.dart';
import '../utils/app_exception.dart';
import '../utils/file_validator.dart';
import 'file_storage_service.dart';

class FirebaseFileStorageService implements FileStorageService {
  FirebaseFileStorageService(this.storage);
  final FirebaseStorage storage;
  @override
  Future<void> put(
    String key,
    SelectedFile file, {
    void Function(double)? onProgress,
  }) async {
    FileValidator.validate(file, avatar: key.startsWith('avatars/'));
    final task = storage
        .ref(key)
        .putData(
          file.bytes,
          SettableMetadata(
            contentType: file.mimeType,
            customMetadata: {'originalName': file.name},
          ),
        );
    final subscription = task.snapshotEvents.listen((event) {
      if (event.totalBytes > 0) {
        onProgress?.call(event.bytesTransferred / event.totalBytes);
      }
    });
    try {
      await task;
    } on FirebaseException {
      throw const AppException(
        'Dosya yüklenemedi. Bağlantıyı ve erişim izinlerini kontrol edin.',
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<SelectedFile> read(String key) async {
    try {
      final ref = storage.ref(key);
      final metadata = await ref.getMetadata();
      final bytes = await ref.getData(20 * 1024 * 1024);
      if (bytes == null) throw const AppException('Dosya bulunamadı.');
      return SelectedFile(
        metadata.customMetadata?['originalName'] ?? ref.name,
        bytes,
      );
    } on FirebaseException {
      throw const AppException(
        'Dosya okunamadı. Bağlantıyı ve erişim izinlerini kontrol edin.',
      );
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await storage.ref(key).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        throw const AppException('Dosya silinemedi. İşlem yeniden denenmeli.');
      }
    }
  }
}
