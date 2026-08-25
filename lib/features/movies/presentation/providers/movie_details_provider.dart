import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/entities/movie_details.dart';

/// Loads full details for a single movie, keyed by movie id.
final movieDetailsProvider = FutureProvider.autoDispose
    .family<MovieDetails, int>((ref, id) {
      return ref.watch(movieRepositoryProvider).getMovieDetails(id);
    });
