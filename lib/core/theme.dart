import 'package:flutter/material.dart';

/// Design tokens for Date Dawn.
///
/// Ported from the web app's Tailwind theme (`src/styles.css`): a near-black
/// canvas, a warm cream foreground and a single teal accent that carries every
/// live/active state. Two accents would read as two products, so there is one.
class AppColors {
  const AppColors._();

  static const canvas = Color(0xFF0E1113);
  static const surface = Color(0xFF161A1D);
  static const surface2 = Color(0xFF1D2226);
  static const border = Color(0xFF262C31);
  static const borderStrong = Color(0xFF39424A);

  static const fg = Color(0xFFF0F1EE);
  static const muted = Color(0xFF9BA3AB);
  static const subtle = Color(0xFF6C757D);

  static const accent = Color(0xFF4FD1C5);
  static const accentSoft = Color(0xFF16302F);
  static const accentFg = Color(0xFF05201E);

  static const danger = Color(0xFFE5716E);
  static const success = Color(0xFF6FCF7F);
  static const warning = Color(0xFFE0B44C);

  // Celebration hues — accent plus fixed party colours, so confetti reads as
  // confetti rather than a second product accent.
  static const party = <Color>[
    accent,
    Color(0xFFE8B64C),
    Color(0xFFE0709A),
    Color(0xFF7CC4E8),
    Color(0xFFF0F1EE),
  ];
}

/// The same palette, re-tuned for light mode. The accent shifts a shade darker
/// so it keeps contrast against a white canvas.
class AppColorsLight {
  const AppColorsLight._();

  static const canvas = Color(0xFFF7F8F6);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEFF1EE);
  static const border = Color(0xFFE0E3DE);
  static const borderStrong = Color(0xFFC4CAC3);

  static const fg = Color(0xFF14181A);
  static const muted = Color(0xFF5A636B);
  static const subtle = Color(0xFF8A939B);

  static const accent = Color(0xFF14807A);
  static const accentSoft = Color(0xFFDDF3F0);
  static const accentFg = Color(0xFFFFFFFF);

  static const danger = Color(0xFFC0392B);
  static const success = Color(0xFF2F7D48);
  static const warning = Color(0xFF9A6B12);
}

/// Everything a widget needs to paint, reachable through `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderStrong,
    required this.fg,
    required this.muted,
    required this.subtle,
    required this.accent,
    required this.accentSoft,
    required this.accentFg,
    required this.danger,
    required this.success,
    required this.warning,
  });

  final Color canvas;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color borderStrong;
  final Color fg;
  final Color muted;
  final Color subtle;
  final Color accent;
  final Color accentSoft;
  final Color accentFg;
  final Color danger;

  /// Status colours, used for exactly one thing: telling an answered invitation
  /// from an unanswered one. Kept beside `danger` rather than invented per
  /// widget so "accepted" is the same green everywhere in the app.
  final Color success;
  final Color warning;

  static const dark = AppPalette(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surface2: AppColors.surface2,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    fg: AppColors.fg,
    muted: AppColors.muted,
    subtle: AppColors.subtle,
    accent: AppColors.accent,
    accentSoft: AppColors.accentSoft,
    accentFg: AppColors.accentFg,
    danger: AppColors.danger,
    success: AppColors.success,
    warning: AppColors.warning,
  );

  static const light = AppPalette(
    canvas: AppColorsLight.canvas,
    surface: AppColorsLight.surface,
    surface2: AppColorsLight.surface2,
    border: AppColorsLight.border,
    borderStrong: AppColorsLight.borderStrong,
    fg: AppColorsLight.fg,
    muted: AppColorsLight.muted,
    subtle: AppColorsLight.subtle,
    accent: AppColorsLight.accent,
    accentSoft: AppColorsLight.accentSoft,
    accentFg: AppColorsLight.accentFg,
    danger: AppColorsLight.danger,
    success: AppColorsLight.success,
    warning: AppColorsLight.warning,
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? borderStrong,
    Color? fg,
    Color? muted,
    Color? subtle,
    Color? accent,
    Color? accentSoft,
    Color? accentFg,
    Color? danger,
    Color? success,
    Color? warning,
  }) =>
      AppPalette(
        canvas: canvas ?? this.canvas,
        surface: surface ?? this.surface,
        surface2: surface2 ?? this.surface2,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        fg: fg ?? this.fg,
        muted: muted ?? this.muted,
        subtle: subtle ?? this.subtle,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        accentFg: accentFg ?? this.accentFg,
        danger: danger ?? this.danger,
        success: success ?? this.success,
        warning: warning ?? this.warning,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      subtle: Color.lerp(subtle, other.subtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentFg: Color.lerp(accentFg, other.accentFg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

/// Sugar so widgets read `context.colors.accent` instead of digging through the
/// theme extension by hand.
extension AppPaletteX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

class AppTheme {
  const AppTheme._();

  /// System font stack on mobile, with the web build falling back through the
  /// same list the site uses. Display text is tight and slightly condensed.
  static ThemeData build({required Brightness brightness}) {
    final palette =
        brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
    ).copyWith(
      surface: palette.canvas,
      onSurface: palette.fg,
      primary: palette.accent,
      onPrimary: palette.accentFg,
      error: palette.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      extensions: <ThemeExtension<dynamic>>[palette],
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: palette.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.fg,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(base.textTheme, palette),
      dividerTheme:
          DividerThemeData(color: palette.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: TextStyle(color: palette.subtle, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _inputBorder(palette.border),
        enabledBorder: _inputBorder(palette.border),
        focusedBorder: _inputBorder(palette.accent, width: 1.5),
        errorBorder: _inputBorder(palette.danger),
        focusedErrorBorder: _inputBorder(palette.danger, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.accentFg,
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.fg,
          side: BorderSide(color: palette.borderStrong),
          minimumSize: const Size.fromHeight(50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: palette.muted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface2,
        contentTextStyle: TextStyle(color: palette.fg, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accentFg
              : palette.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.accent
              : palette.surface2,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _textTheme(TextTheme base, AppPalette palette) =>
      base.apply(bodyColor: palette.fg, displayColor: palette.fg).copyWith(
            // The hero numeral on the countdown tiles — tight tracking, tabular so
            // digits don't jitter as the seconds tick over.
            displayLarge: base.displayLarge?.copyWith(
              fontSize: 44,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.2,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: palette.fg,
            ),
            headlineLarge: base.headlineLarge?.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              height: 1.15,
            ),
            headlineMedium: base.headlineMedium?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
            titleMedium: base.titleMedium
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
            bodyMedium: base.bodyMedium
                ?.copyWith(fontSize: 14, height: 1.45, color: palette.muted),
            bodySmall:
                base.bodySmall?.copyWith(fontSize: 12.5, color: palette.subtle),
            labelSmall: base.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: palette.subtle,
            ),
          );
}
