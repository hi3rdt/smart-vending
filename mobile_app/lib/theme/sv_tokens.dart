// Smart Vending design tokens.
// Source of truth: the "Smart Vending" design system tokens.json.
// Keep values in sync with that file; do not hand-tune them here.

import 'package:flutter/material.dart';

/// Color tokens as a [ThemeExtension], so widgets can read tokens that
/// Material's [ColorScheme] has no slot for (success, accent text, sunken surface...).
///
/// Usage: `final c = SvColors.of(context);`
@immutable
class SvColors extends ThemeExtension<SvColors> {
  const SvColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.lineStrong,
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.accent,
    required this.onAccent,
    required this.warm,
    required this.onWarm,
    required this.success,
    required this.onSuccess,
    required this.danger,
    required this.onDanger,
    required this.focus,
  });

  /// App background behind every screen.
  final Color surface;

  /// Cards, sheets, list rows, the live cart panel.
  final Color surfaceRaised;

  /// Inputs, wells, empty thumbnails.
  final Color surfaceSunken;

  /// Primary text/icons on all three surfaces.
  final Color ink;

  /// Secondary text (SKU, timestamps, helper text).
  final Color inkMuted;

  /// Decorative dividers only - never the sole boundary of a control.
  final Color line;

  /// Control borders (>= 3:1 on every surface).
  final Color lineStrong;

  /// Primary action, active tab, done steps, scan button.
  /// Logo navy in light, logo mint in dark (the two inks swap roles).
  final Color brand;
  final Color onBrand;

  /// Mint tint: current step, quantity bubbles, "Đã thanh toán", shelf slot just picked.
  final Color brandSoft;

  /// Logo mint as a FILL ONLY (cart badge, scanner frame, success check).
  /// Never text on light surfaces; pair with [onAccent] (navy).
  final Color accent;
  final Color onAccent;

  /// Warm (amber), non-alarming heads-ups: low balance, door left open,
  /// payment not taken, low stock.
  final Color warm;
  final Color onWarm;

  /// Server-confirmed outcomes only (Paid, Completed, Refunded, stock-in).
  final Color success;
  final Color onSuccess;

  /// Payment failed, offline, blocked, destructive actions.
  final Color danger;
  final Color onDanger;

  /// 2px focus ring (deep amber; never blue/indigo).
  final Color focus;

  static const SvColors light = SvColors(
    surface: Color(0xFFF4F8F8),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE7EEF0),
    ink: Color(0xFF0E1B3D), // logo navy
    inkMuted: Color(0xFF4A5872),
    line: Color(0xFFDCE4EA),
    lineStrong: Color(0xFF76829A),
    brand: Color(0xFF0E1B3D), // logo navy
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFD6F7EB),
    accent: Color(0xFF2EE6A8), // logo mint
    onAccent: Color(0xFF0E1B3D),
    warm: Color(0xFFFFE8B8),
    onWarm: Color(0xFF5A3A00),
    success: Color(0xFF0B6AA2),
    onSuccess: Color(0xFFFFFFFF),
    danger: Color(0xFFC4321F),
    onDanger: Color(0xFFFFFFFF),
    focus: Color(0xFFA35A00),
  );

  static const SvColors dark = SvColors(
    surface: Color(0xFF0A1122), // navy night
    surfaceRaised: Color(0xFF121B30),
    surfaceSunken: Color(0xFF070C18),
    ink: Color(0xFFEEF3F9),
    inkMuted: Color(0xFFA7B3C7),
    line: Color(0xFF223049),
    lineStrong: Color(0xFF62728F),
    brand: Color(0xFF2EE6A8), // logo mint takes the lead in dark
    onBrand: Color(0xFF0E1B3D),
    brandSoft: Color(0xFF123A3A),
    accent: Color(0xFF2EE6A8),
    onAccent: Color(0xFF0E1B3D),
    warm: Color(0xFF4A3410),
    onWarm: Color(0xFFFFD98A),
    success: Color(0xFF62B6EC),
    onSuccess: Color(0xFF04243A),
    danger: Color(0xFFFF8A73),
    onDanger: Color(0xFF3A0B03),
    focus: Color(0xFFF5B53D),
  );

  /// Reads the tokens of the current theme. Falls back to [light] so a widget
  /// used outside [SvTheme] still renders (and fails loudly in debug).
  static SvColors of(BuildContext context) {
    final SvColors? ext = Theme.of(context).extension<SvColors>();
    assert(ext != null, 'SvColors missing: build the app with SvTheme.light()/dark().');
    return ext ?? light;
  }

  @override
  SvColors copyWith({
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? lineStrong,
    Color? brand,
    Color? onBrand,
    Color? brandSoft,
    Color? accent,
    Color? onAccent,
    Color? warm,
    Color? onWarm,
    Color? success,
    Color? onSuccess,
    Color? danger,
    Color? onDanger,
    Color? focus,
  }) {
    return SvColors(
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandSoft: brandSoft ?? this.brandSoft,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      warm: warm ?? this.warm,
      onWarm: onWarm ?? this.onWarm,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      focus: focus ?? this.focus,
    );
  }

  /// Interpolates every token so ThemeMode switches animate smoothly.
  @override
  SvColors lerp(covariant ThemeExtension<SvColors>? other, double t) {
    if (other is! SvColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SvColors(
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      line: l(line, other.line),
      lineStrong: l(lineStrong, other.lineStrong),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandSoft: l(brandSoft, other.brandSoft),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      warm: l(warm, other.warm),
      onWarm: l(onWarm, other.onWarm),
      success: l(success, other.success),
      onSuccess: l(onSuccess, other.onSuccess),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      focus: l(focus, other.focus),
    );
  }
}

/// Spacing scale (tokens.json `spacing`). Use these instead of literals.
abstract final class SvSpace {
  static const double s1 = 4; // icon-to-label gap
  static const double s2 = 8; // related lines inside a row
  static const double s3 = 12; // list row vertical padding
  static const double s4 = 16; // screen gutter, card padding
  static const double s6 = 24; // between screen sections
  static const double s8 = 32; // above a status headline
}

/// Radius scale (tokens.json `radius`).
abstract final class SvRadius {
  static const double sm = 8; // inputs, thumbnails
  static const double md = 16; // buttons, notes, small cards
  static const double lg = 20; // cards, wallet, scanner frame, sheets
  static const double xl = 32; // onboarding tiles, big friendly shapes
  static const double pill = 999; // pills, chips, badges, step pills

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Minimum touch target from the brand book.
const double kSvMinTouchTarget = 48;

/// Height of primary/secondary buttons (friendlier than the 48px minimum).
const double kSvButtonHeight = 52;

/// "Chữ lớn" setting: multiply the system text scale by this.
const double kSvLargeTextScale = 1.14;

/// The three logo arrangements from the design system (asset group
/// `icon_smartvending`).
enum SvLogoKind {
  /// The Open Cabinet mark alone: app bar, splash, small headers (24px+).
  icon,

  /// Mark + "Smart Vending" on one line: login, about, admin header (120px+ wide).
  horizontal,

  /// Mark above the name and tagline: onboarding, empty states.
  stacked,
}

/// Logo file paths. Each arrangement has a light-ground file and a reversed
/// `_dark` twin (navy swapped for #EEF3F9, mint door unchanged). Never show
/// the navy files on a dark ground - the wordmark disappears.
abstract final class SvLogo {
  static const String _dir = 'assets/logo/';

  static String path(SvLogoKind kind, Brightness brightness) {
    final String base = switch (kind) {
      SvLogoKind.icon => 'A-open-cabinet_icon',
      SvLogoKind.horizontal => 'A-open-cabinet_lockup-horizontal',
      SvLogoKind.stacked => 'A-open-cabinet_lockup-stacked',
    };
    final String suffix = brightness == Brightness.dark ? '_dark' : '';
    return '$_dir$base$suffix.svg';
  }

  /// Every logo file, e.g. for precaching at startup.
  static List<String> get all => <String>[
        for (final SvLogoKind k in SvLogoKind.values)
          for (final Brightness b in Brightness.values) path(k, b),
      ];
}
