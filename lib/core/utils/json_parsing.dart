/// Small helpers for safely reading loosely-typed JSON values.
///
/// TMDB fields are frequently null or occasionally arrive in an unexpected
/// numeric/string form. These helpers keep model parsing null-safe and avoid
/// runtime crashes without scattering casts across the codebase.
library;

int? asIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDoubleOrNull(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? asStringOrNull(Object? value) {
  if (value is String) return value.isEmpty ? null : value;
  return null;
}
