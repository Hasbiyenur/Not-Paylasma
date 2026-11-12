import '../models/user_model.dart';

class PasswordResetRequest {
  const PasswordResetRequest({required this.id, this.demoCode});
  final String id;
  final String? demoCode;
}

abstract class AuthRepository {
  bool get usesEmailPasswordReset => false;
  UserModel? get currentUser;
  Stream<UserModel?> get changes;
  Future<void> signIn(String email, String password);
  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  );
  Future<void> signOut();
  Future<PasswordResetRequest> requestPasswordReset(String email);
  Future<void> confirmPasswordReset(String id, String code, String password);
  Future<void> updateProfile(
    String firstName,
    String lastName, {
    String? photoUrl,
  });
}
