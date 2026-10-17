// Auth contract between the app and the backend, plus an in-memory fake used
// by the demo and tests. Swap FakeAuthRepository for an HTTP implementation
// (e.g. POST /auth/login, /auth/register, /auth/refresh, /auth/forgot).

import 'package:flutter/foundation.dart';

import 'auth_validators.dart';

enum UserRole { customer, operator, admin }

@immutable
class AppUser {
  const AppUser({required this.id, required this.name, required this.email, required this.role});

  final String id;
  final String name;
  final String email;
  final UserRole role;

  /// Last word of a Vietnamese full name: "Từ Đức Hiệp" -> "Hiệp".
  String get firstName {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.last.isEmpty ? 'bạn' : parts.last;
  }

  bool get canAdmin => role == UserRole.admin;
}

@immutable
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;

  /// Access-token expiry (UTC).
  final DateTime expiresAt;
}

enum AuthErrorCode { invalidCredentials, emailTaken, invalidInvite, sessionExpired, network }

class AuthException implements Exception {
  const AuthException(this.code);

  final AuthErrorCode code;

  /// Customer-facing message, calm and actionable (brand book).
  String get message => switch (code) {
        AuthErrorCode.invalidCredentials =>
          'Email hoặc mật khẩu chưa đúng. Thử lại hoặc bấm "Quên mật khẩu?" nhé.',
        AuthErrorCode.emailTaken => 'Email này đã có tài khoản. Đăng nhập nhé.',
        AuthErrorCode.invalidInvite => 'Mã mời không còn hiệu lực. Hỏi quản trị viên mã mới nhé.',
        AuthErrorCode.sessionExpired => 'Phiên đăng nhập đã hết hạn. Đăng nhập lại nhé.',
        AuthErrorCode.network => 'Chưa kết nối được máy chủ. Kiểm tra mạng rồi thử lại nhé.',
      };

  @override
  String toString() => 'AuthException($code)';
}

abstract class AuthRepository {
  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
    String? inviteCode,
  });

  /// Exchanges a refresh token for a new session (rotated refresh token).
  Future<AuthSession> refresh(String refreshToken);

  /// Always completes normally for unknown emails too (no account enumeration).
  Future<void> requestPasswordReset(String email);

  Future<void> signOut(String refreshToken);
}

/// In-memory backend for demos and tests. NOT for production: passwords are
/// kept in plain text here only because nothing leaves the device.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.latency = const Duration(milliseconds: 600),
    this.tokenLifetime = const Duration(minutes: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _accounts['demo@smartvending.vn'] =
        _Account(const AppUser(id: 'u1', name: 'Từ Đức Hiệp', email: 'demo@smartvending.vn', role: UserRole.customer), '123456');
    _accounts['admin@smartvending.vn'] =
        _Account(const AppUser(id: 'u2', name: 'Lê Minh Quân', email: 'admin@smartvending.vn', role: UserRole.admin), 'admin123');
  }

  final Duration latency;
  final Duration tokenLifetime;
  final DateTime Function() _now;

  final Map<String, _Account> _accounts = <String, _Account>{};
  final Map<String, String> _refreshToEmail = <String, String>{};
  final Set<String> _validInvites = <String>{'SV-A03-7K2Q'};
  int _seq = 0;

  Future<void> _wait() => latency == Duration.zero ? Future<void>.value() : Future<void>.delayed(latency);

  AuthSession _issue(AppUser user) {
    _seq++;
    final String refresh = 'rt-${user.id}-$_seq';
    _refreshToEmail[refresh] = user.email;
    return AuthSession(
      user: user,
      accessToken: 'at-${user.id}-$_seq',
      refreshToken: refresh,
      expiresAt: _now().toUtc().add(tokenLifetime),
    );
  }

  @override
  Future<AuthSession> signIn({required String email, required String password}) async {
    await _wait();
    final _Account? acc = _accounts[normalizeEmail(email)];
    if (acc == null || acc.password != password) {
      throw const AuthException(AuthErrorCode.invalidCredentials);
    }
    return _issue(acc.user);
  }

  @override
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
    String? inviteCode,
  }) async {
    await _wait();
    final String key = normalizeEmail(email);
    if (_accounts.containsKey(key)) throw const AuthException(AuthErrorCode.emailTaken);
    if (inviteCode != null && inviteCode.isNotEmpty && !_validInvites.contains(normalizeInviteCode(inviteCode))) {
      throw const AuthException(AuthErrorCode.invalidInvite);
    }
    final AppUser user = AppUser(id: 'u${_accounts.length + 1}', name: name.trim(), email: key, role: UserRole.customer);
    _accounts[key] = _Account(user, password);
    return _issue(user);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    await _wait();
    // Rotation: a refresh token works once.
    final String? email = _refreshToEmail.remove(refreshToken);
    final _Account? acc = email == null ? null : _accounts[email];
    if (acc == null) throw const AuthException(AuthErrorCode.sessionExpired);
    return _issue(acc.user);
  }

  @override
  Future<void> requestPasswordReset(String email) => _wait();

  @override
  Future<void> signOut(String refreshToken) async {
    _refreshToEmail.remove(refreshToken);
  }
}

class _Account {
  _Account(this.user, this.password);

  final AppUser user;
  final String password;
}
