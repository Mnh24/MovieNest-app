import 'package:flutter_test/flutter_test.dart';
import 'package:movie_app/features/movies/data/models/movie_details_model.dart';
import 'package:movie_app/features/movies/data/models/movie_model.dart';

void main() {
  group('MovieModel.fromJson', () {
    test('parses a complete payload', () {
      final movie = MovieModel.fromJson(const {
        'id': 42,
        'title': 'Interstellar',
        'poster_path': '/poster.jpg',
        'backdrop_path': '/backdrop.jpg',
        'release_date': '2014-11-05',
        'vote_average': 8.4,
        'overview': 'A team travels through a wormhole.',
      });

      expect(movie.id, 42);
      expect(movie.title, 'Interstellar');
      expect(movie.releaseYear, '2014');
      expect(movie.formattedRating, '8.4');
    });

    test('handles missing and null fields without throwing', () {
      final movie = MovieModel.fromJson(const {'id': 7});

      expect(movie.id, 7);
      expect(movie.title, 'Untitled');
      expect(movie.posterPath, isNull);
      expect(movie.releaseDate, isNull);
      expect(movie.releaseYear, isNull);
      expect(movie.formattedRating, isNull);
    });

    test('treats a zero rating as unrated', () {
      final movie = MovieModel.fromJson(const {
        'id': 1,
        'title': 'Unrated',
        'vote_average': 0,
      });

      expect(movie.formattedRating, isNull);
    });

    test('coerces numeric fields provided as strings', () {
      final movie = MovieModel.fromJson(const {
        'id': '99',
        'title': 'Coerced',
        'vote_average': '7.6',
      });

      expect(movie.id, 99);
      expect(movie.formattedRating, '7.6');
    });

    test('round-trips through toJson', () {
      const json = {
        'id': 5,
        'title': 'Dune',
        'poster_path': '/dune.jpg',
        'backdrop_path': null,
        'release_date': '2021-10-22',
        'vote_average': 8.0,
        'overview': 'Paul Atreides.',
      };

      final restored = MovieModel.fromJson(
        MovieModel.toJson(MovieModel.fromJson(json)),
      );

      expect(restored.id, 5);
      expect(restored.title, 'Dune');
      expect(restored.releaseYear, '2021');
    });
  });

  group('MovieDetailsModel.fromJson', () {
    test('parses genres and runtime', () {
      final details = MovieDetailsModel.fromJson(const {
        'id': 1,
        'title': 'Movie',
        'runtime': 134,
        'tagline': 'A tagline',
        'status': 'Released',
        'genres': [
          {'id': 1, 'name': 'Action'},
          {'id': 2, 'name': 'Drama'},
        ],
      });

      expect(details.formattedRuntime, '2h 14m');
      expect(details.genres.map((g) => g.name), ['Action', 'Drama']);
      expect(details.tagline, 'A tagline');
    });

    test('drops malformed genre entries and handles null runtime', () {
      final details = MovieDetailsModel.fromJson(const {
        'id': 1,
        'title': 'Movie',
        'genres': [
          {'id': 1, 'name': 'Action'},
          {'id': 2},
        ],
      });

      expect(details.formattedRuntime, isNull);
      expect(details.genres.length, 1);
    });
  });
}
