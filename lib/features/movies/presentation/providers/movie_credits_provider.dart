import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/entities/cast_member.dart';

/// Loads the cast for a single movie, keyed by movie id.
final movieCreditsProvider = FutureProvider.autoDispose
    .family<List<CastMember>, int>((ref, id) {
      return ref.watch(movieRepositoryProvider).getCredits(id);
    });
