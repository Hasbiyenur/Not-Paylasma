import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/category_model.dart';
import '../category_repository.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(this.db);
  final FirebaseFirestore db;
  @override
  Future<List<CategoryModel>> listCategories() async {
    final result = await db.collection('categories').orderBy('name').get();
    return result.docs
        .map((doc) => CategoryModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
