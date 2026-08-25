/// Centralized spacing scale used across the app.
///
/// A consistent 4/8/12/16/20/24/32 rhythm keeps layouts aligned and avoids
/// arbitrary magic numbers scattered through widgets.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Consistent corner radii for cards, images and inputs.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}
