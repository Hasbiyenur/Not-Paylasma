import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/note_model.dart';
import '../models/selected_file.dart';
import '../repositories/note_repository.dart';
import '../core/utils/app_exception.dart';

class NoteProvider extends ChangeNotifier {
  NoteProvider(this.repository) {
    _subscription = repository.changes.listen((_) {
      revision++;
      notifyListeners();
    });
  }
  final NoteRepository repository;
  late final StreamSubscription<void> _subscription;
  int revision = 0;
  bool saving = false;
  double progress = 0;
  Future<NoteModel> save(
    NoteDraft draft, {
    String? id,
    SelectedFile? file,
  }) async {
    if (saving) throw const AppException('Kayıt işlemi zaten devam ediyor.');
    saving = true;
    progress = 0;
    notifyListeners();
    try {
      return await repository.save(
        draft,
        id: id,
        file: file,
        onProgress: (v) {
          progress = v;
          notifyListeners();
        },
      );
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
