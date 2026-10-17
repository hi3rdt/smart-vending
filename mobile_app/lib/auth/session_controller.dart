// Holds the signed-in session and refreshes the access token automatically
// shortly before it expires ("automatic session refresh" in the product brief).
//
// Persisting the refresh token (flutter_secure_storage) is left to the app
// shell; call [restore] with the stored token at startup.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'auth_repository.dart';

/// How long before expiry to refresh. Never schedules in the past.
Duration refreshDelay({
  required DateTime expiresAt,
  required DateTime now,
  Duration lead = const Duration(seconds: 60),
}) {
  final Duration d = expiresAt.toUtc().difference(now.toUtc()) - lead;
  return d.isNegative ? Duration.zero : d;
}

class SessionController extends ChangeNotifier {
  SessionController(this._repo, {DateTime Function()? now, this.refreshLead = const Duration(seconds: 60)})
      : _now = now ?? DateTime.now;

  final AuthRepository _repo;
  final DateTime Function() _now;
  final Duration refreshLead;

  AuthSession? _session;
  Timer? _timer;
  bool _busy = false;

  /// Set when the session ends on its own (refresh failed); shown on the login screen.
  String? lastSignOutReason;

  AuthSession? get session => _session;
  AppUser? get user => _session?.user;
  bool get isSignedIn => _session != null;
  bool get busy => _busy;

  Future<void> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<void> signUp({required String name, required String email, required String password, String? inviteCode}) =>
      _run(() => _repo.signUp(name: name, email: email, password: password, inviteCode: inviteCode));

  Future<void> restore(String refreshToken) => _run(() => _repo.refresh(refreshToken));

  Future<void> requestPasswordReset(String email) async {
    _setBusy(true);
    try {
      await _repo.requestPasswordReset(email);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    final AuthSession? s = _session;
    _clear();
    notifyListeners();
    if (s != null) {
      try {
        await _repo.signOut(s.refreshToken);
      } on Object catch (_) {
        // Best effort: the local session is already gone.
      }
    }
  }

  /// Runs an auth call; rethrows [AuthException] for the screen to show.
  Future<void> _run(Future<AuthSession> Function() call) async {
    _setBusy(true);
    try {
      _adopt(await call());
      lastSignOutReason = null;
    } finally {
      _setBusy(false);
    }
  }

  void _adopt(AuthSession s) {
    _session = s;
    _timer?.cancel();
    _timer = Timer(
      refreshDelay(expiresAt: s.expiresAt, now: _now(), lead: refreshLead),
      _refreshNow,
    );
    notifyListeners();
  }

  Future<void> _refreshNow() async {
    final AuthSession? s = _session;
    if (s == null) return;
    try {
      _adopt(await _repo.refresh(s.refreshToken));
    } on AuthException catch (e) {
      lastSignOutReason = e.message;
      _clear();
      notifyListeners();
    }
    // Network errors other than AuthException propagate to the zone; a real
    // client should retry with backoff before giving up.
  }

  void _clear() {
    _timer?.cancel();
    _timer = null;
    _session = null;
  }

  void _setBusy(bool v) {
    if (_busy == v) return;
    _busy = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
