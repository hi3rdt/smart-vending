// VND formatting per the brand book: no decimals, '.' thousands separator,
// symbol after a non-breaking space -> "25.000 ₫".
//
// Money is always carried as an int number of dong. Never use double for
// prices/balances: 0.1 + 0.2 style drift breaks totals and server comparison.

const String _nbsp = ' ';
const String _minus = '−'; // true minus sign, not hyphen
const String _dong = '₫';

/// Groups digits of a non-negative integer with '.' every three digits.
String _groupThousands(int value) {
  assert(value >= 0);
  final String digits = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    final int remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

/// 25000 -> "25.000 ₫", -5000 -> "−5.000 ₫"; [signed] adds '+' to positives.
String formatVnd(int amount, {bool signed = false}) {
  final String sign = amount < 0 ? _minus : (signed && amount > 0 ? '+' : '');
  return '$sign${_groupThousands(amount.abs())}$_nbsp$_dong';
}

/// Stock deltas: 3 -> "+3", -2 -> "−2", 0 -> "0".
String formatDelta(int n) {
  if (n > 0) return '+$n';
  if (n < 0) return '$_minus${n.abs()}';
  return '0';
}
