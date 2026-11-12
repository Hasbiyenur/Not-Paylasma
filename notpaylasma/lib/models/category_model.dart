class CategoryModel {
  const CategoryModel(this.id, this.name, this.description);
  final String id, name, description;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
  factory CategoryModel.fromJson(Map<String, dynamic> value) => CategoryModel(
    value['id'] as String,
    value['name'] as String,
    value['description'] as String,
  );
}
