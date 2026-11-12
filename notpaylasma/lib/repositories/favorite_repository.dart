abstract class FavoriteRepository {
  Stream<void> get changes;
  Future<Set<String>> getForCurrentUser();
  Future<void> setFavorite(String noteId, bool value);
}
