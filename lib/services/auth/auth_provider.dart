import 'package:mynotes/services/auth/auth_user.dart';

abstract class AuthProvider {
  Future<void> initializer();

  AuthUser? get currentUser;
  Future<AuthUser> logIn({
    required String email,
    required String password,
  });
  Future<AuthUser> CreateUser({
    required String email,
    required String password,
  });
  Future<void> logOut();
  Future<void> sendEmailVerification();
}
