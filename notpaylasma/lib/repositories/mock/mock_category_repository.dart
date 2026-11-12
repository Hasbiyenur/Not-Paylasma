import '../../models/category_model.dart';
import '../category_repository.dart';
import 'mock_store.dart';

class MockCategoryRepository implements CategoryRepository {
  MockCategoryRepository(this.store);
  final MockStore store;
  @override
  Future<List<CategoryModel>> listCategories() async =>
      List.unmodifiable(store.categories);
}
