import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';

class AuthServices implements AuthProvider {
  final AuthProvider provider;

  const AuthServices({required this.provider});

  @override
  Future<AuthUser> CreateUser({
    required String email,
    required String password,
  }) =>
      provider.CreateUser(
        email: email,
        password: password,
      );

  @override
  AuthUser? get currentUser => provider.currentUser;

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) =>
      provider.logIn(
        email: email,
        password: password,
      );

  @override
  Future<void> logOut() => provider.logOut();
  @override
  Future<void> sendVerificartion() => provider.sendVerificartion();
}
