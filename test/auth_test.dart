import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', () {
    final provider = MockAuthProvide();
    test('Should not be initialized to begin with', () {
      expect(provider.isInitialized, false);
    });

    test("can't log out if not initialized", () {
      expect(provider.logOut(),
          throwsA(const TypeMatcher<NotInitializedAuthException>()));
    });
    test('should be able to initiazed', () async {
      await provider.initializer();
      expect(provider.isInitialized, true);
    });

    test('user shoud be null after initialization', () {
      expect(provider.currentUser, null);
    });
    test(
      'should be able to initialized in less than 2 secons',
      () async {
        await provider.initializer();
        expect(provider.isInitialized, true);
      },
      timeout: Timeout(Duration(seconds: 2)),
    );
    test('Create user should delegate to logIn function', () async {
      final badEmailUser = provider.CreateUser(
        email: 'foo@bar.com',
        password: 'any',
      );
      expect(badEmailUser,
          throwsA(const TypeMatcher<UserNotFoundAuthException>()));
      final badPasswordUser = provider.CreateUser(
        email: 'someone@bar.com',
        password: 'foobar',
      );
      expect(badPasswordUser,
          throwsA(const TypeMatcher<WrongPasswordAuthException>()));
      final user = await provider.CreateUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
      expect(user.isEmailVerified, true);
    });
    test('login user should be email verified', () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
    });
  });
}

class NotInitializedAuthException implements Exception {}

class MockAuthProvide implements AuthProvider {
  AuthUser? _user;

  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> CreateUser({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) throw NotInitializedAuthException();
    await Future.delayed(
      const Duration(milliseconds: 1),
    );
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initializer() async {
    await Future.delayed(
      const Duration(milliseconds: 1),
    );
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NotInitializedAuthException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    const user = AuthUser(
      isEmailVerified: false,
      email: 'foo@bar.com',
    );
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedAuthException();
    if (_user == null) throw UserNotLoggedInAuthException();
    await Future.delayed(
      const Duration(milliseconds: 1),
    );
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NotInitializedAuthException();
    final user = _user;
    if (user == null) throw UserNotLoggedInAuthException();
    const newUser = AuthUser(isEmailVerified: true, email: 'foo@bar.com');
    _user = newUser;
  }
}
