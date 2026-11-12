import 'dart:async';

import 'package:flutter/foundation.dart';

import '../repositories/auth_repository.dart';
import '../repositories/favorite_repository.dart';
import '../core/utils/app_exception.dart';

class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider(this.repository, this.auth) {
    _subscriptions.add(auth.changes.listen((_) => reload()));
    _subscriptions.add(repository.changes.listen((_) => reload()));
  }
  final FavoriteRepository repository;
  final AuthRepository auth;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Set<String> ids = {};
  final pending = <String>{};
  String? error;
  int _generation = 0;
  String? _uid;
  Future<void>? _latestLoad;
  bool _disposed = false;

  Future<void> reload() async {
    if (_disposed) return;
    final load = _latestLoad = _load();
    await load;
    await _waitForLatest();
  }

  Future<void> _waitForLatest() async {
    while (!_disposed) {
      final latest = _latestLoad;
      await latest;
      if (identical(latest, _latestLoad)) break;
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final uid = auth.currentUser?.uid;
    if (uid != _uid) {
      ids = {};
      pending.clear();
      _uid = uid;
    }
    error = null;
    notifyListeners();
    if (auth.currentUser == null) return;
    try {
      final result = await repository.getForCurrentUser();
      if (generation != _generation) return;
      ids = result;
    } catch (e) {
      if (generation == _generation) error = errorMessage(e);
    }
    if (generation == _generation) notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (!pending.add(id)) return;
    final value = !ids.contains(id);
    notifyListeners();
    try {
      await repository.setFavorite(id, value);
      await reload();
      // Repository olayı açık yenilemeden sonra gelirse onun sonucunu da bekle.
    } finally {
      pending.remove(id);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
