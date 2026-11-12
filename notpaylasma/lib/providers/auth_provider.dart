import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/file_storage_service.dart';
import '../core/utils/file_validator.dart';
import '../core/utils/app_exception.dart';
import '../models/user_model.dart';
import '../models/selected_file.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.repository, this.files) {
    _subscription = repository.changes.listen((_) => notifyListeners());
  }
  final AuthRepository repository;
  final FileStorageService files;
  late final StreamSubscription<UserModel?> _subscription;
  bool busy = false;
  UserModel? get user => repository.currentUser;
  Future<T> run<T>(Future<T> Function() operation) async {
    if (busy) {
      throw const AppException('Lütfen devam eden işlemin bitmesini bekleyin.');
    }
    busy = true;
    notifyListeners();
    try {
      return await operation();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String first, String last, SelectedFile? photo) =>
      run(() async {
        final current = user;
        if (current == null) throw const AppException('Önce giriş yapın.');
        String? path;
        try {
          if (photo != null) {
            FileValidator.validate(photo, avatar: true);
            path = 'avatars/${current.uid}/${const Uuid().v4()}';
            await files.put(path, photo);
          }
          if (user?.uid != current.uid) {
            throw const AppException('Oturum değişti.');
          }
          await repository.updateProfile(first, last, photoUrl: path);
        } catch (_) {
          if (path != null) await _cleanup(path);
          rethrow;
        }
        if (path != null && current.photoUrl != null) {
          await _cleanup(current.photoUrl!);
        }
      });
  Future<void> _cleanup(String path) async {
    try {
      await files.delete(path);
    } catch (_) {
      // Yarım kalan dosya, yerel deponun sonraki sahipsiz ek taramasına kalır.
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
