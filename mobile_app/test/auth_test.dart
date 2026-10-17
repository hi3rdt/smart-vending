import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_vending_ui/auth/auth_repository.dart';
import 'package:smart_vending_ui/auth/auth_validators.dart';
import 'package:smart_vending_ui/auth/session_controller.dart';
import 'package:smart_vending_ui/screens/auth/login_screen.dart';
import 'package:smart_vending_ui/screens/auth/register_screen.dart';
import 'package:smart_vending_ui/theme/sv_theme.dart';

FakeAuthRepository _fastRepo() => FakeAuthRepository(latency: Duration.zero);

void main() {
  group('validators', () {
    test('email', () {
      expect(validateEmail(''), 'Nhập email của bạn nhé');
      expect(validateEmail('abc'), startsWith('Email chưa đúng định dạng'));
      expect(validateEmail(' an@ptit.edu.vn '), isNull);
    });
    test('passwords', () {
      expect(validateSignInPassword(''), isNotNull);
      expect(validateSignInPassword('1'), isNull); // sign-in never leaks the rule
      expect(validateNewPassword('12345'), 'Mật khẩu cần ít nhất 6 ký tự');
      expect(validateNewPassword('123456'), isNull);
      expect(validateConfirmPassword('a', 'b'), 'Hai mật khẩu chưa khớp');
      expect(validateConfirmPassword('abc123', 'abc123'), isNull);
    });
    test('name and invite code', () {
      expect(validateName(' A '), isNotNull);
      expect(validateName('An'), isNull);
      expect(validateInviteCode(''), isNull); // optional for email sign-up
      expect(validateInviteCode('', required: true), isNotNull);
      expect(validateInviteCode('sv-a03-7k2q'), isNull); // normalized
      expect(validateInviteCode('SV-A3-7K2Q'), 'Mã mời có dạng SV-A03-7K2Q');
    });
    test('invite code from QR payload', () {
      expect(inviteCodeFromQr('SV-A03-7K2Q'), 'SV-A03-7K2Q');
      expect(inviteCodeFromQr('https://smartvending.vn/join?code=sv-a03-7k2q'), 'SV-A03-7K2Q');
      expect(inviteCodeFromQr('https://example.com/menu'), isNull);
      expect(inviteCodeFromQr('hello'), isNull);
    });
  });

  group('FakeAuthRepository', () {
    test('signs in demo accounts and rejects wrong passwords', () async {
      final FakeAuthRepository repo = _fastRepo();
      final AuthSession s = await repo.signIn(email: 'Demo@SmartVending.vn ', password: '123456');
      expect(s.user.firstName, 'Hiệp');
      expect(s.user.canAdmin, isFalse);
      expect((await repo.signIn(email: 'admin@smartvending.vn', password: 'admin123')).user.canAdmin, isTrue);
      expect(
        () => repo.signIn(email: 'demo@smartvending.vn', password: 'nope'),
        throwsA(isA<AuthException>().having((AuthException e) => e.code, 'code', AuthErrorCode.invalidCredentials)),
      );
    });

    test('sign-up rejects taken emails and unknown invites', () async {
      final FakeAuthRepository repo = _fastRepo();
      expect(
        () => repo.signUp(name: 'X Y', email: 'demo@smartvending.vn', password: '123456'),
        throwsA(isA<AuthException>().having((AuthException e) => e.code, 'code', AuthErrorCode.emailTaken)),
      );
      expect(
        () => repo.signUp(name: 'X Y', email: 'x@y.vn', password: '123456', inviteCode: 'SV-ZZZ-0000'),
        throwsA(isA<AuthException>().having((AuthException e) => e.code, 'code', AuthErrorCode.invalidInvite)),
      );
      final AuthSession s = await repo.signUp(name: 'Nguyễn Văn An', email: 'an@ptit.edu.vn', password: '123456', inviteCode: 'sv-a03-7k2q');
      expect(s.user.firstName, 'An');
    });

    test('refresh tokens rotate (single use)', () async {
      final FakeAuthRepository repo = _fastRepo();
      final AuthSession s1 = await repo.signIn(email: 'demo@smartvending.vn', password: '123456');
      final AuthSession s2 = await repo.refresh(s1.refreshToken);
      expect(s2.refreshToken, isNot(s1.refreshToken));
      expect(() => repo.refresh(s1.refreshToken), throwsA(isA<AuthException>()));
    });
  });

  group('session refresh', () {
    test('refreshDelay fires one lead before expiry and never in the past', () {
      final DateTime now = DateTime.utc(2026, 10, 17, 12);
      expect(refreshDelay(expiresAt: now.add(const Duration(minutes: 15)), now: now), const Duration(minutes: 14));
      expect(refreshDelay(expiresAt: now.add(const Duration(seconds: 30)), now: now), Duration.zero);
    });

    test('controller refreshes automatically and keeps the user signed in', () async {
      final FakeAuthRepository repo = FakeAuthRepository(latency: Duration.zero, tokenLifetime: const Duration(milliseconds: 80));
      final SessionController c = SessionController(repo, refreshLead: const Duration(milliseconds: 40));
      await c.signIn('demo@smartvending.vn', '123456');
      final String firstToken = c.session!.accessToken;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(c.isSignedIn, isTrue);
      expect(c.session!.accessToken, isNot(firstToken));
      await c.signOut();
      expect(c.isSignedIn, isFalse);
      c.dispose();
    });
  });

  group('LoginScreen', () {
    Widget host(SessionController c) => MaterialApp(theme: SvTheme.light(googleFonts: false), home: LoginScreen(session: c));

    testWidgets('shows inline errors on empty submit', (WidgetTester tester) async {
      final SessionController c = SessionController(_fastRepo());
      await tester.pumpWidget(host(c));
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pump();
      expect(find.text('Nhập email của bạn nhé'), findsOneWidget);
      expect(find.text('Nhập mật khẩu nhé'), findsOneWidget);
      expect(c.isSignedIn, isFalse);
    });

    testWidgets('wrong password shows the warm note, right one signs in', (WidgetTester tester) async {
      final SessionController c = SessionController(_fastRepo());
      await tester.pumpWidget(host(c));
      await tester.enterText(find.byType(TextFormField).at(0), 'demo@smartvending.vn');
      await tester.enterText(find.byType(TextFormField).at(1), 'sai-mat-khau');
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pumpAndSettle();
      expect(find.text('Chưa đăng nhập được'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('Đăng nhập').last);
      await tester.pumpAndSettle();
      expect(c.isSignedIn, isTrue);
      await c.signOut();
      c.dispose();
    });
  });
}
