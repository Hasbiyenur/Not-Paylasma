import '../../models/category_model.dart';
import '../category_repository.dart';
import 'local_json_store.dart';

class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository(this.store);
  final LocalJsonStore store;
  @override
  Future<List<CategoryModel>> listCategories() async =>
      List.unmodifiable(store.categories);
}
