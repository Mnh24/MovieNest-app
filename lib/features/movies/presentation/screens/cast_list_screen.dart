import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/tmdb_images.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../domain/entities/cast_member.dart';

/// Shows the complete cast for a movie, reached via the details screen's
/// "See all" link.
class CastListScreen extends StatelessWidget {
  const CastListScreen({
    super.key,
    required this.movieTitle,
    required this.cast,
  });

  final String movieTitle;
  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cast · $movieTitle')),
      body: SafeArea(
        top: false,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: cast.length,
          itemBuilder: (context, index) {
            final member = cast[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _CastRow(member: member),
            );
          },
        ),
      ),
    );
  }
}

class _CastRow extends StatelessWidget {
  const _CastRow({required this.member});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileUrl = TmdbImages.profile(member.profilePath);

    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 52,
            height: 52,
            child: profileUrl == null
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : PosterImage(url: profileUrl),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (member.character != null)
                Text(
                  member.character!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
