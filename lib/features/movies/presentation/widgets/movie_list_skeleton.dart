import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/skeleton.dart';

/// Skeleton placeholder that mirrors the movie list layout while loading.
class MovieListSkeleton extends StatelessWidget {
  const MovieListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const Row(
        children: [
          SkeletonBox(width: 64, height: 96, radius: AppRadius.md),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 120, height: 14),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 80, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
