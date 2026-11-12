import '../../core/utils/app_exception.dart';
import '../favorite_repository.dart';
import 'mock_store.dart';

class MockFavoriteRepository implements FavoriteRepository {
  MockFavoriteRepository(this.store);
  final MockStore store;
  @override
  Stream<void> get changes => store.favoriteEvents.stream;
  @override
  Future<Set<String>> getForCurrentUser() async {
    await store.settled;
    return Set.unmodifiable(store.favorites[store.requireUser.uid] ?? {});
  }

  @override
  Future<void> setFavorite(String noteId, bool value) async {
    final uid = store.requireUser.uid;
    await store.write(() {
      if (uid != store.requireUser.uid) {
        throw const AppException('Oturum değişti.');
      }
      final note = store.notes[noteId];
      if (note == null) throw const AppException('Not artık mevcut değil.');
      final favorites = store.favorites.putIfAbsent(uid, () => {});
      final changed = value ? favorites.add(noteId) : favorites.remove(noteId);
      if (changed) {
        store.notes[noteId] = note.changed({
          'favoriteCount': note.favoriteCount + (value ? 1 : -1),
        });
      }
    });
    store.dataChanged();
  }
}
