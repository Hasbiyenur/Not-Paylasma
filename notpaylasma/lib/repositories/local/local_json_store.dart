import 'dart:async';

import '../../models/category_model.dart';
import '../../models/note_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/app_exception.dart';

class LocalJsonStore {
  LocalJsonStore({this.externalUsers = false});
  final bool externalUsers;
  Future<void> Function(Map<String, dynamic>)? persist;
  String theme = 'system';
  Future<void> _pending = Future<void>.value();

  Future<void> get settled => persist == null ? Future<void>.value() : _pending;

  /// Sadece kısa metadata değişiklikleri sıraya alınır; dosya yüklemesi dışarıdadır.
  Future<T> write<T>(T Function() action) {
    // Bellek adapter'ının senkron değişikliği için disk kuyruğu gerekmez.
    if (persist == null) return Future<T>.sync(action);
    final result = _pending.then((_) async {
      final before = _json(memorySnapshot: true);
      final revision = sessionRevision;
      try {
        final value = action();
        await persist?.call(toJson());
        return value;
      } catch (_) {
        _restore(before);
        sessionRevision = revision;
        rethrow;
      }
    });
    _pending = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Map<String, dynamic> toJson() => _json();
  Map<String, dynamic> _json({bool memorySnapshot = false}) => {
    'schemaVersion': externalUsers ? 2 : 1,
    if (!externalUsers || memorySnapshot)
      'users': users.values.map((u) => u.toJson()).toList(),
    if (!externalUsers || memorySnapshot)
      'credentials': credentials.map(
        (id, secret) =>
            MapEntry(id, {'salt': secret.salt, 'hash': secret.hash}),
      ),
    'notes': notes.values.map((n) => n.toJson()).toList(),
    'favorites': favorites.map((id, values) => MapEntry(id, values.toList())),
    if (!externalUsers || memorySnapshot) 'currentUid': currentUid,
    'localAvatars': Map<String, String>.from(localAvatars),
    'theme': theme,
    'categories': categories.map((c) => c.toJson()).toList(),
  };

  void _restore(Map<String, dynamic> json) {
    categories = (json['categories'] as List)
        .map(
          (value) =>
              CategoryModel.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    users.clear();
    for (final value in json['users'] as List? ?? const []) {
      final user = UserModel.fromJson(Map<String, dynamic>.from(value as Map));
      users[user.uid] = user;
    }
    credentials.clear();
    (json['credentials'] as Map? ?? const {}).forEach((id, value) {
      credentials[id as String] = (
        salt: value['salt'] as String,
        hash: value['hash'] as String,
      );
    });
    localAvatars.clear();
    localAvatars.addAll(
      Map<String, String>.from(json['localAvatars'] as Map? ?? const {}),
    );
    for (final user in users.values) {
      if (user.photoUrl != null) {
        if (json['schemaVersion'] == 1) {
          localAvatars[user.uid] = user.photoUrl!;
        } else {
          localAvatars.putIfAbsent(user.uid, () => user.photoUrl!);
        }
      }
    }
    notes.clear();
    for (final value in json['notes'] as List) {
      final note = NoteModel.fromJson(Map<String, dynamic>.from(value as Map));
      notes[note.id] = note;
    }
    favorites.clear();
    (json['favorites'] as Map).forEach((id, values) {
      favorites[id as String] = (values as List).cast<String>().toSet();
    });
    currentUid = json['currentUid'] as String?;
    theme = json['theme'] as String;
  }

  void restore(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 &&
        !(externalUsers && json['schemaVersion'] == 2)) {
      throw const AppException(
        'Yerel veri sürümü desteklenmiyor. Kayıtlar değiştirilmedi.',
      );
    }
    try {
      _restore(json);
      if ((!externalUsers &&
              (users.isEmpty ||
                  users.length != (json['users'] as List).length ||
                  credentials.length != users.length ||
                  users.values.map((u) => u.email).toSet().length !=
                      users.length)) ||
          notes.length != (json['notes'] as List).length ||
          !['system', 'light', 'dark'].contains(theme) ||
          (currentUid != null && !users.containsKey(currentUid)) ||
          localAvatars.entries.any(
            (entry) => entry.key.isEmpty || !entry.value.startsWith('avatars/'),
          )) {
        throw const FormatException();
      }
      for (final user in users.values) {
        if (externalUsers) continue;
        final secret = credentials[user.uid];
        if (secret == null ||
            secret.salt.isEmpty ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(secret.hash) ||
            user.uid.isEmpty ||
            user.firstName.isEmpty ||
            user.lastName.isEmpty ||
            !user.email.contains('@')) {
          throw const FormatException();
        }
      }
      for (final entry in favorites.entries) {
        if ((!externalUsers && !users.containsKey(entry.key)) ||
            entry.key.isEmpty ||
            entry.value.any((id) => !notes.containsKey(id))) {
          throw const FormatException();
        }
      }
      for (final note in notes.values) {
        final count = favorites.values
            .where((ids) => ids.contains(note.id))
            .length;
        if ((!externalUsers && !users.containsKey(note.userId)) ||
            note.userId.isEmpty ||
            !categories.any((c) => c.id == note.categoryId) ||
            note.fileSize <= 0 ||
            note.fileSize > 20 * 1024 * 1024 ||
            note.downloadCount < 0 ||
            note.favoriteCount != count ||
            note.storagePath.isEmpty ||
            note.id.isEmpty ||
            !['pdf', 'docx', 'jpg', 'jpeg', 'png'].contains(note.fileType)) {
          throw const FormatException();
        }
      }
    } catch (_) {
      throw const AppException(
        'Yerel kayıt bozuk veya eksik. Kayıtlar silinmedi; yedeğinizi kontrol edin.',
      );
    }
  }

  Set<String> get referencedFiles => {
    ...notes.values.map((n) => n.storagePath),
    ...users.values.map((u) => u.photoUrl).whereType<String>(),
    ...localAvatars.values,
  };

  final Map<String, UserModel> users = {};
  final Map<String, ({String salt, String hash})> credentials = {};
  final Map<String, NoteModel> notes = {};
  final Map<String, Set<String>> favorites = {};
  final Map<String, String> localAvatars = {};
  List<CategoryModel> categories = [];
  String? currentUid;
  int sessionRevision = 0;
  final authEvents = StreamController<UserModel?>.broadcast();
  final noteEvents = StreamController<void>.broadcast();
  final favoriteEvents = StreamController<void>.broadcast();
  UserModel get requireUser =>
      users[currentUid] ??
      (throw const AppException('Devam etmek için giriş yapın.'));
  void dataChanged() {
    noteEvents.add(null);
    favoriteEvents.add(null);
  }

  void close() {
    authEvents.close();
    noteEvents.close();
    favoriteEvents.close();
  }
}
