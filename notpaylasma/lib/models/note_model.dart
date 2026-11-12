class NoteModel {
  NoteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.courseName,
    required this.categoryId,
    this.university = '',
    required List<String> tags,
    required this.userId,
    required this.userName,
    required this.fileName,
    required this.storagePath,
    required this.fileType,
    required this.fileSize,
    this.downloadCount = 0,
    this.favoriteCount = 0,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = List.unmodifiable(tags);
  final String id, title, description, courseName, categoryId, university;
  final List<String> tags;
  final String userId, userName, fileName, storagePath, fileType;
  final int fileSize, downloadCount, favoriteCount;
  final DateTime createdAt, updatedAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'courseName': courseName,
    'categoryId': categoryId,
    'university': university,
    'tags': tags,
    'userId': userId,
    'userName': userName,
    'fileName': fileName,
    'storagePath': storagePath,
    'fileType': fileType,
    'fileSize': fileSize,
    'downloadCount': downloadCount,
    'favoriteCount': favoriteCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    courseName: json['courseName'] as String,
    categoryId: json['categoryId'] as String,
    university: json['university'] as String? ?? '',
    tags: (json['tags'] as List).cast<String>(),
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    fileName: json['fileName'] as String,
    storagePath: json['storagePath'] as String,
    fileType: json['fileType'] as String,
    fileSize: json['fileSize'] as int,
    downloadCount: json['downloadCount'] as int,
    favoriteCount: json['favoriteCount'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
  NoteModel changed(Map<String, dynamic> changes) =>
      NoteModel.fromJson({...toJson(), ...changes});
}

enum NoteSort { newest, downloads, popular }

class NoteQuery {
  const NoteQuery({
    this.search = '',
    this.categoryId,
    this.tag = '',
    this.userId,
    this.sort = NoteSort.newest,
    this.limit = 10,
    this.cursor,
  });
  final String search, tag;
  final String? categoryId, userId, cursor;
  final NoteSort sort;
  final int limit;
}

class NotePage {
  const NotePage(this.items, this.nextCursor);
  final List<NoteModel> items;
  final String? nextCursor;
}

class NoteDraft {
  const NoteDraft({
    required this.title,
    required this.description,
    required this.courseName,
    required this.categoryId,
    this.university = '',
    this.tags = const [],
  });
  final String title, description, courseName, categoryId, university;
  final List<String> tags;
}
