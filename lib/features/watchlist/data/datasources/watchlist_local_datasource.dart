import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../movies/data/models/movie_model.dart';
import '../../../movies/domain/entities/movie.dart';

/// Persists the watchlist locally using [SharedPreferences].
///
/// Movies are stored as a JSON array of compact movie payloads, which is small
/// enough for preferences storage and fully renderable without a network call.
class WatchlistLocalDataSource {
  const WatchlistLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'watchlist_movies';

  List<Movie> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(MovieModel.fromJson)
          .where((m) => m.id != 0)
          .toList();
    } on FormatException {
      // Corrupt storage should not crash the app; start from an empty list.
      return [];
    }
  }

  Future<void> writeAll(List<Movie> movies) async {
    final encoded = jsonEncode(movies.map(MovieModel.toJson).toList());
    final success = await _prefs.setString(_key, encoded);
    if (!success) {
      throw const UnexpectedFailure('Could not update your watchlist.');
    }
  }
}
