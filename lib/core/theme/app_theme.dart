import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Central definition of the app's light and dark Material 3 themes.
///
/// Both themes are intentionally designed around a shared seed colour so that
/// component styling (cards, inputs, app bars) stays consistent while each
/// mode keeps appropriate contrast and surface tones.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF7C5CFC);
  // Near-black "glass" tones for dark mode: a neutral, slightly cool black for
  // the canvas and a faintly lighter charcoal for glass surfaces/cards.
  static const Color _darkBackground = Color(0xFF09090B);
  static const Color _darkSurface = Color(0xFF17171B);
  static const Color _lightSurface = Color(0xFFF3EEFF);

  /// A rich, non-flat backdrop gradient shown behind every screen.
  ///
  /// Kept separate from [ThemeData.scaffoldBackgroundColor] (which only
  /// accepts a solid colour) so screens can paint it via [AppBackground].
  static const List<Color> darkBackgroundGradient = [
    Color(0xFF121214),
    Color(0xFF0A0A0C),
    Color(0xFF050506),
  ];

  static const List<Color> lightBackgroundGradient = [
    Color(0xFFFDFCFF),
    Color(0xFFF4F1FB),
    Color(0xFFEDE8F7),
  ];

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    if (brightness == Brightness.dark) {
      colorScheme = colorScheme.copyWith(
        surface: _darkBackground,
        surfaceContainerHighest: _darkSurface,
        surfaceContainerHigh: _darkSurface,
      );
    } else {
      // A genuine light theme: near-white canvas with dark text (the default
      // light ColorScheme's onSurface), and soft lavender-tinted surfaces for
      // cards and glass panels so they read as light, modern and airy.
      colorScheme = colorScheme.copyWith(
        surfaceContainerHighest: _lightSurface,
        surfaceContainerHigh: _lightSurface,
      );
    }

    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.transparent,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
    );
  }

  static List<Color> gradientFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? darkBackgroundGradient
      : lightBackgroundGradient;
}

/// Paints the app's signature gradient behind a screen's content.
///
/// Since [ThemeData.scaffoldBackgroundColor] only supports a solid colour,
/// screens wrap their [Scaffold] body in this widget (with the Scaffold left
/// transparent) to get a consistent, non-flat backdrop in both theme modes.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Soft ambient colour "orbs" bleeding in from the corners give the black
    // canvas a frosted-glass depth (light diffusing behind glass) instead of a
    // flat fill. Kept low-opacity so content stays the focus.
    final glowA = isDark
        ? const Color(0xFF7C5CFC).withValues(alpha: 0.16)
        : const Color(0xFF7C5CFC).withValues(alpha: 0.14);
    final glowB = isDark
        ? const Color(0xFF3F6BFF).withValues(alpha: 0.14)
        : const Color(0xFF63C7FF).withValues(alpha: 0.12);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.gradientFor(brightness),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            left: -110,
            child: _AmbientOrb(color: glowA, size: 380),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: _AmbientOrb(color: glowB, size: 420),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// A soft radial glow disc used as ambient light behind the frosted-glass
/// canvas. Fades from [color] at its centre to transparent at the edge.
class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0), Colors.transparent],
            stops: const [0, 0.7, 1],
          ),
        ),
      ),
    );
  }
}
