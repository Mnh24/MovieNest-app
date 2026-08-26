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
  static const Color _darkBackground = Color(0xFF0C0C10);
  static const Color _darkSurface = Color(0xFF23242B);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  /// A rich, non-flat backdrop gradient shown behind every screen.
  ///
  /// Kept separate from [ThemeData.scaffoldBackgroundColor] (which only
  /// accepts a solid colour) so screens can paint it via [AppBackground].
  // Neutral, softly-graded "studio backdrop" tones — a charcoal glass canvas
  // in dark mode and a soft light-grey one in light mode. Soft light-leak orbs
  // (see [AppBackground]) sit over these to create the frosted, cloudy depth.
  static const List<Color> darkBackgroundGradient = [
    Color(0xFF1B1C22),
    Color(0xFF131318),
    Color(0xFF0B0B0F),
  ];

  static const List<Color> lightBackgroundGradient = [
    Color(0xFFF1F2F6),
    Color(0xFFE7E8EE),
    Color(0xFFDBDCE4),
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

    // Soft neutral light-leak "orbs" over a diagonally-graded canvas create the
    // cloudy, frosted-glass studio backdrop: a bright white highlight and a
    // gentle shadow in light mode; two soft grey light diffusions in dark mode.
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.85);
    final lowlight = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFC7CAD6).withValues(alpha: 0.6);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientFor(brightness),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -170,
            left: -130,
            child: _AmbientOrb(color: highlight, size: 480),
          ),
          Positioned(
            bottom: -190,
            right: -140,
            child: _AmbientOrb(color: lowlight, size: 460),
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
    // Cached as its own layer so it isn't repainted while content scrolls.
    return RepaintBoundary(
      child: IgnorePointer(
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
      ),
    );
  }
}
