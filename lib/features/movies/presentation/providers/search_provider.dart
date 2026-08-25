import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/providers.dart';
import '../../domain/entities/movie.dart';

/// The distinct states a search can be in. Keeping these explicit lets the UI
/// render an intentional widget for each case (initial, loading, results,
/// empty, error) instead of overloading a single async value.
sealed class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchResults extends SearchState {
  const SearchResults(this.movies);
  final List<Movie> movies;
}

class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);
  final String query;
}

class SearchError extends SearchState {
  const SearchError(this.failure);
  final Failure failure;
}

/// Debounces user input and queries TMDB, exposing an explicit [SearchState].
class SearchNotifier extends AutoDisposeNotifier<SearchState> {
  Timer? _debounce;
  String _lastQuery = '';

  static const Duration _debounceDuration = Duration(milliseconds: 400);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchInitial();
  }

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _lastQuery = '';
      state = const SearchInitial();
      return;
    }

    // Show loading immediately so the user knows input was registered, then
    // wait out the debounce window before actually hitting the network.
    state = const SearchLoading();
    _debounce = Timer(_debounceDuration, () => _run(trimmed));
  }

  Future<void> retry() async {
    if (_lastQuery.isNotEmpty) {
      state = const SearchLoading();
      await _run(_lastQuery);
    }
  }

  void clear() {
    _debounce?.cancel();
    _lastQuery = '';
    state = const SearchInitial();
  }

  Future<void> _run(String query) async {
    _lastQuery = query;
    try {
      final results = await ref
          .read(movieRepositoryProvider)
          .searchMovies(query);
      // Guard against a stale response arriving after the query changed.
      if (_lastQuery != query) return;
      state = results.isEmpty ? SearchEmpty(query) : SearchResults(results);
    } catch (error) {
      if (_lastQuery != query) return;
      state = SearchError(mapError(error));
    }
  }
}

final searchProvider = AutoDisposeNotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
