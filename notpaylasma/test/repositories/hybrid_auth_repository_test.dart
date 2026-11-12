import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notpaylas/core/services/app_dependencies.dart';
import 'package:notpaylas/core/services/json_file_system_io.dart';
import 'package:notpaylas/core/services/local_json_dependencies.dart';
import 'package:notpaylas/models/note_model.dart';
import 'package:notpaylas/models/selected_file.dart';
import 'package:notpaylas/models/user_model.dart';
import 'package:notpaylas/repositories/auth_repository.dart';
import 'package:notpaylas/repositories/firebase/hybrid_auth_repository.dart';
import 'package:notpaylas/repositories/local/local_json_store.dart';

class TestRemoteAuth implements AuthRepository {
  final events = StreamController<UserModel?>.broadcast();
  UserModel? user;
  String? lastPhoto;
  @override
  bool get usesEmailPasswordReset => true;
  @override
  UserModel? get currentUser => user;
  @override
  Stream<UserModel?> get changes => events.stream;
  @override
  Future<void> register(
    String first,
    String last,
    String email,
    String password,
  ) async {
    final now = DateTime.now().toUtc();
    user = UserModel(
      uid: 'firebase-user',
      firstName: first,
      lastName: last,
      email: email,
      createdAt: now,
      updatedAt: now,
    );
    events.add(user);
  }

  @override
  Future<void> signIn(String email, String password) =>
      register('Firebase', 'Kullanıcısı', email, password);
  @override
  Future<void> signOut() async {
    user = null;
    events.add(null);
  }

  @override
  Future<void> updateProfile(
    String first,
    String last, {
    String? photoUrl,
  }) async {
    lastPhoto = photoUrl;
    user = user!.copyWith(firstName: first, lastName: last);
    events.add(user);
  }

  @override
  Future<PasswordResetRequest> requestPasswordReset(String email) async =>
      const PasswordResetRequest(id: 'remote-email');
  @override
  Future<void> confirmPasswordReset(
    String id,
    String code,
    String password,
  ) async {}
  Future<void> close() => events.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Yerel disk yazılamasa da Firebase kaydı ve oturum açma tamamlanır',
    () async {
      final localStore = LocalJsonStore(externalUsers: true);
      final auth = TestRemoteAuth();
      final directory = await Directory.systemTemp.createTemp('auth-cache-');
      final hybrid = HybridAuthRepository(
        auth,
        localStore,
        DiskJsonFileSystem(directory),
      );
      await hybrid.ready;
      localStore.persist = (_) async =>
          throw const FileSystemException('Disk yazmaya kapalı');
      try {
        await hybrid.register(
          'Çağla',
          'Şahin',
          'test@example.com',
          'OnlyRemote123!',
        );
        expect(hybrid.currentUser!.firstName, 'Çağla');
        expect(localStore.toJson().containsKey('users'), isFalse);
        await hybrid.signOut();
        await hybrid.signIn('test@example.com', 'OnlyRemote123!');
        expect(hybrid.currentUser!.uid, auth.currentUser!.uid);
      } finally {
        await hybrid.close();
        await auth.close();
        localStore.close();
        await directory.delete(recursive: true);
      }
    },
  );
  late Directory directory;
  late DiskJsonFileSystem fs;
  late TestRemoteAuth remote;
  late HybridAuthRepository hybrid;
  Future<AppDependencies> open() => createLocalJsonDependencies(
    fileSystem: fs,
    migrateLegacy: false,
    externalUsers: true,
    authFactory: (store, fileSystem) async {
      remote = TestRemoteAuth();
      hybrid = HybridAuthRepository(
        remote,
        store,
        fileSystem,
        closeRemote: remote.close,
      );
      await hybrid.ready;
      return hybrid;
    },
    closeAuth: () => hybrid.close(),
  );
  Future<Map<String, dynamic>> saved() async => Map<String, dynamic>.from(
    (jsonDecode(await File('${directory.path}/data.json').readAsString())
            as Map)['data']
        as Map,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hybrid-account-');
    fs = DiskJsonFileSystem(directory);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'Kullanıcı ve parola JSON’a yazılmaz; not ve avatar yerelde kalır',
    () async {
      final deps = await open();
      await deps.auth.register(
        'Gerçek',
        'Profil',
        'profil@example.com',
        'OnlyRemotePassword123!',
      );
      final data = await rootBundle.load('assets/data/files/ornek.png');
      final image = SelectedFile(
        'avatar.png',
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      await deps.files.put('avatars/firebase-user/photo', image);
      await deps.auth.updateProfile(
        'Yeni',
        'Profil',
        photoUrl: 'avatars/firebase-user/photo',
      );
      final note = await deps.notes.save(
        const NoteDraft(
          title: 'Yerel PNG notu',
          description: 'Kullanıcısı Firebase, dosyası yerel olan not.',
          courseName: 'Mobil',
          categoryId: 'yazilim',
        ),
        file: image,
      );
      final state = await saved();
      expect(state['schemaVersion'], 2);
      for (final key in ['users', 'credentials', 'currentUid']) {
        expect(state.containsKey(key), isFalse);
      }
      expect(state['localAvatars'], {
        'firebase-user': 'avatars/firebase-user/photo',
      });
      expect(remote.lastPhoto, isNull);
      expect(deps.auth.currentUser!.photoUrl, 'avatars/firebase-user/photo');
      expect((await deps.files.read(note.storagePath)).bytes, image.bytes);
      expect(
        await File('${directory.path}/data.json').readAsString(),
        isNot(contains('OnlyRemotePassword123!')),
      );
      await deps.auth.signOut();
      expect(deps.auth.currentUser, isNull);
      await deps.auth.signIn('profil@example.com', 'OnlyRemotePassword123!');
      expect(await deps.notes.getById(note.id), isNotNull);
      expect(deps.auth.currentUser!.photoUrl, 'avatars/firebase-user/photo');
      await deps.close();
    },
  );
  test(
    'Yerel hesap açık aktarımda not sahipliği, favori ve fotoğrafı korur',
    () async {
      final local = await createLocalJsonDependencies(
        fileSystem: fs,
        migrateLegacy: false,
      );
      await local.auth.signIn('ayse@example.com', 'NotPaylas123!');
      await local.favorites.setFavorite('demo-note-000', true);
      final png = await rootBundle.load('assets/data/files/ornek.png');
      await local.files.put(
        'avatars/demo-ayse/photo',
        SelectedFile(
          'photo.png',
          png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
        ),
      );
      await local.auth.updateProfile(
        'Ayşe',
        'Yılmaz',
        photoUrl: 'avatars/demo-ayse/photo',
      );
      await local.close();
      final deps = await open();
      expect(await fs.read('legacy-accounts.json'), isNotNull);
      expect(deps.auth.currentUser, isNull);
      await hybrid.migrateLegacyAccount('ayse@example.com', 'NotPaylas123!');
      expect(deps.auth.currentUser!.uid, 'firebase-user');
      expect(
        (await deps.notes.getById('demo-note-000'))!.userId,
        'firebase-user',
      );
      expect(
        await deps.favorites.getForCurrentUser(),
        contains('demo-note-000'),
      );
      expect(deps.auth.currentUser!.photoUrl, 'avatars/demo-ayse/photo');
      expect((await saved()).containsKey('users'), isFalse);
      final pending = jsonDecode(
        utf8.decode((await fs.read('legacy-accounts.json'))!),
      ) as Map;
      expect(
        (pending['users'] as List).any((u) => u['uid'] == 'demo-ayse'),
        isFalse,
      );
      await deps.close();
    },
  );
  test('Hatalı yerel parola Firebase aktarımını başlatmaz', () async {
    final deps = await open();
    await expectLater(
      hybrid.migrateLegacyAccount('ayse@example.com', 'hatalı'),
      throwsException,
    );
    expect(remote.currentUser, isNull);
    expect(await fs.read('legacy-accounts.json'), isNotNull);
    await deps.close();
  });
}
