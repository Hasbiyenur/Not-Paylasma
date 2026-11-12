import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../repositories/category_repository.dart';
import '../core/utils/app_exception.dart';

class CategoryProvider extends ChangeNotifier {
  CategoryProvider(this.repository);
  final CategoryRepository repository;
  List<CategoryModel> items = [];
  String? error;
  bool loading = true;
  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await repository.listCategories();
    } catch (e) {
      error = errorMessage(e);
    }
    loading = false;
    notifyListeners();
  }

  String name(String id) =>
      items.where((c) => c.id == id).firstOrNull?.name ?? id;
}
