import 'package:dio/dio.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/error_mapper.dart';
import '../../domain/entities/cast_member.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';
import '../models/cast_member_model.dart';
import '../models/movie_details_model.dart';
import '../models/movie_model.dart';

/// Talks to the TMDB REST API. This is the single place HTTP requests to TMDB
/// are constructed, keeping URL/endpoint knowledge out of the rest of the app.
class TmdbRemoteDataSource {
  const TmdbRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Movie>> getTrending() async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/trending/movie/week',
      );
      return _parseMovieList(response.data);
    });
  }

  Future<List<Movie>> getPopular() => _list('/movie/popular');

  Future<List<Movie>> getTopRated() => _list('/movie/top_rated');

  Future<List<Movie>> getNowPlaying() => _list('/movie/now_playing');

  /// Fetches and parses a paginated movie list endpoint (popular, top rated,
  /// now playing) that all share TMDB's `{ results: [...] }` shape.
  Future<List<Movie>> _list(String path) {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return _parseMovieList(response.data);
    });
  }

  Future<List<Movie>> searchMovies(String query, {CancelToken? cancelToken}) {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search/movie',
        queryParameters: {'query': query, 'include_adult': false},
        cancelToken: cancelToken,
      );
      return _parseMovieList(response.data);
    });
  }

  Future<MovieDetails> getMovieDetails(int id) async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>('/movie/$id');
      final data = response.data;
      if (data == null) throw const ParsingFailure();
      return MovieDetailsModel.fromJson(data);
    });
  }

  Future<List<CastMember>> getCredits(int id) async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/movie/$id/credits',
      );
      final cast = response.data?['cast'];
      if (cast is! List) throw const ParsingFailure();
      return cast
          .whereType<Map<String, dynamic>>()
          .map(CastMemberModel.fromJson)
          .where((c) => c.id != 0)
          .toList();
    });
  }

  List<Movie> _parseMovieList(Map<String, dynamic>? data) {
    final results = data?['results'];
    if (results is! List) throw const ParsingFailure();
    return results
        .whereType<Map<String, dynamic>>()
        .map(MovieModel.fromJson)
        .where((m) => m.id != 0)
        .toList();
  }

  /// Runs [action], translating any low-level error into a domain [Failure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw mapError(error);
    }
  }
}
