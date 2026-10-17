// Form validators for sign-in / sign-up. Pure functions: return null when the
// value is valid, otherwise a Vietnamese message written as the fix
// (brand book: "Nhập email của bạn nhé", not "Invalid input").

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Invite codes printed in the registration QR: SV-<cabinet 3>-<4>, e.g. SV-A03-7K2Q.
final RegExp _invite = RegExp(r'^SV-[A-Z0-9]{3}-[A-Z0-9]{4}$');

const int kMinPasswordLength = 6;

String? validateEmail(String? value) {
  final String v = (value ?? '').trim();
  if (v.isEmpty) return 'Nhập email của bạn nhé';
  if (!_email.hasMatch(v)) return 'Email chưa đúng định dạng, ví dụ ban@example.com';
  return null;
}

/// Sign-in only checks presence: the server decides whether it is correct,
/// and we never reveal password rules for an existing account.
String? validateSignInPassword(String? value) =>
    (value == null || value.isEmpty) ? 'Nhập mật khẩu nhé' : null;

String? validateNewPassword(String? value) {
  final String v = value ?? '';
  if (v.isEmpty) return 'Nhập mật khẩu nhé';
  if (v.length < kMinPasswordLength) return 'Mật khẩu cần ít nhất $kMinPasswordLength ký tự';
  return null;
}

String? validateConfirmPassword(String? value, String password) =>
    (value ?? '') == password ? null : 'Hai mật khẩu chưa khớp';

String? validateName(String? value) =>
    (value ?? '').trim().length < 2 ? 'Nhập họ tên của bạn' : null;

/// Upper-cases and trims what was typed or scanned.
String normalizeInviteCode(String raw) => raw.trim().toUpperCase();

/// Empty is allowed (invite is optional for email sign-up); when present it
/// must match the printed format.
String? validateInviteCode(String? value, {bool required = false}) {
  final String v = normalizeInviteCode(value ?? '');
  if (v.isEmpty) return required ? 'Nhập mã mời in trên QR' : null;
  if (!_invite.hasMatch(v)) return 'Mã mời có dạng SV-A03-7K2Q';
  return null;
}

/// Normalizes an email for lookups (servers should do the same).
String normalizeEmail(String raw) => raw.trim().toLowerCase();
