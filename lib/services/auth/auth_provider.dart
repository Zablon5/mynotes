import 'package:mynotes/services/auth/auth_user.dart';

abstract class AuthProvider {
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
  Future<void> sendVerificartion();
}
