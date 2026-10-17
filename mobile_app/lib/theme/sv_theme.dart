// Smart Vending ThemeData builders (light + dark), wired to SvColors tokens.
//
// MaterialApp(
//   theme: SvTheme.light(),
//   darkTheme: SvTheme.dark(),
//   themeMode: ThemeMode.system,
// )

import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sv_tokens.dart';

/// Tabular figures so prices and totals don't jitter as the live cart updates.
const List<FontFeature> kSvTabular = <FontFeature>[FontFeature.tabularFigures()];

abstract final class SvTheme {
  /// [googleFonts] = false skips Be Vietnam Pro (widget tests, offline builds);
  /// text then falls back to the platform font with the same scale.
  static ThemeData light({bool googleFonts = true}) => _build(SvColors.light, Brightness.light, googleFonts);
  static ThemeData dark({bool googleFonts = true}) => _build(SvColors.dark, Brightness.dark, googleFonts);

  /// Type scale from tokens.json. `height` = lineHeight / fontSize.
  ///  display 32/40 w700 · title 22/28 w700 · heading 18/24 w700
  ///  body 16/24 w400 · body-strong 16/24 w600 · caption 13/18 · label 12/16 w600 (sentence case)
  static TextTheme _textTheme(SvColors c) {
    TextStyle s(double size, double lh, FontWeight w, {Color? color, double ls = 0, bool tabular = false}) {
      return TextStyle(
        fontSize: size,
        height: lh / size,
        fontWeight: w,
        letterSpacing: ls,
        color: color ?? c.ink,
        fontFeatures: tabular ? kSvTabular : null,
      );
    }

    return TextTheme(
      // `display` - wallet balance, order total.
      displaySmall: s(32, 40, FontWeight.w700, ls: -0.32, tabular: true),
      // `title` - screen titles, session headline.
      titleLarge: s(22, 28, FontWeight.w700),
      // `heading` - card titles, product names.
      titleMedium: s(18, 24, FontWeight.w700),
      titleSmall: s(15, 22, FontWeight.w600),
      // `body`
      bodyLarge: s(16, 24, FontWeight.w400),
      bodyMedium: s(16, 24, FontWeight.w400),
      // `caption` - SKU, timestamps, helper text.
      bodySmall: s(13, 18, FontWeight.w400, color: c.inkMuted),
      // `body-strong` - also Material's button label slot.
      labelLarge: s(16, 24, FontWeight.w600, tabular: true),
      labelMedium: s(13, 18, FontWeight.w600),
      // `label` - badges and step pills. Never uppercase Vietnamese.
      labelSmall: s(12, 16, FontWeight.w600),
    );
  }

  static ThemeData _build(SvColors c, Brightness brightness, bool googleFonts) {
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      secondary: c.accent,
      onSecondary: c.onAccent,
      tertiary: c.success,
      onTertiary: c.onSuccess,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surfaceRaised,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceSunken,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.lineStrong,
      outlineVariant: c.line,
      // No tinted elevation: layers are separated by surface steps + lines.
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
    );

    final TextTheme base = _textTheme(c);
    final TextTheme text = googleFonts ? GoogleFonts.beVietnamProTextTheme(base) : base;

    // 2px focus ring for keyboard / switch-access focus.
    BorderSide? focusSide(Set<WidgetState> states, {BorderSide? otherwise}) =>
        states.contains(WidgetState.focused) ? BorderSide(color: c.focus, width: 2) : otherwise;

    const Size minButton = Size(kSvMinTouchTarget, kSvButtonHeight);
    const OutlinedBorder buttonShape = RoundedRectangleBorder(borderRadius: SvRadius.mdAll);
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: SvSpace.s6);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: SvRadius.smAll,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[c],
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      textTheme: text,
      focusColor: c.focus.withAlpha(31), // ~12% overlay; works on Flutter 3.24+
      splashFactory: InkRipple.splashFactory, // portable across iOS/Android/web
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.ink, size: 24),

      // Primary action: brand fill, once per screen.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(minButton),
          padding: const WidgetStatePropertyAll<EdgeInsets>(buttonPadding),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(buttonShape),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
          elevation: const WidgetStatePropertyAll<double>(0),
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? c.surfaceSunken : c.brand),
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? c.inkMuted : c.onBrand),
          side: WidgetStateProperty.resolveWith(focusSide),
        ),
      ),

      // Secondary: raised surface + line-strong border.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(minButton),
          padding: const WidgetStatePropertyAll<EdgeInsets>(buttonPadding),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(buttonShape),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? c.surfaceSunken : c.surfaceRaised),
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? c.inkMuted : c.ink),
          side: WidgetStateProperty.resolveWith((Set<WidgetState> s) => focusSide(s,
              otherwise: s.contains(WidgetState.disabled)
                  ? BorderSide.none
                  : BorderSide(color: c.lineStrong, width: 1.5))),
        ),
      ),

      // Ghost: brand-text action.
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(minButton),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(buttonShape),
          textStyle: WidgetStatePropertyAll<TextStyle?>(text.labelLarge),
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
              s.contains(WidgetState.disabled) ? c.inkMuted : c.brand),
          side: WidgetStateProperty.resolveWith(focusSide),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceSunken,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: SvSpace.s3, vertical: 13),
        hintStyle: text.bodyLarge?.copyWith(color: c.inkMuted),
        labelStyle: text.labelMedium?.copyWith(color: c.ink),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.danger),
        enabledBorder: inputBorder(c.lineStrong),
        focusedBorder: inputBorder(c.focus, 2),
        errorBorder: inputBorder(c.danger, 2),
        focusedErrorBorder: inputBorder(c.danger, 2),
        disabledBorder: inputBorder(Colors.transparent),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceRaised,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> s) => text.labelSmall?.copyWith(
              letterSpacing: 0,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
              color: s.contains(WidgetState.selected) ? c.brand : c.inkMuted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            IconThemeData(color: s.contains(WidgetState.selected) ? c.brand : c.inkMuted, size: 24)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: text.bodyLarge?.copyWith(color: c.surface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: SvRadius.mdAll),
      ),
    );
  }
}
