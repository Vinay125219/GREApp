import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class StudentCourseProgressWidget extends StatelessWidget {
  final bool isLoading;
  final List<CourseProgressItem> courses;
  final bool hasMore;
  final bool loadingMore;
  final String? error;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRefresh;

  const StudentCourseProgressWidget({
    super.key,
    required this.isLoading,
    this.courses = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
    this.onLoadMore,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My Courses',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.studentCoursesScreen),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isLoading)
          Column(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: const SkeletonCard(),
              ),
            ),
          )
        else if (error != null)
          _buildErrorState(theme)
        else if (courses.isEmpty)
          _buildEmptyState(theme)
        else
          Column(
            children: [
              ...courses.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CourseProgressCard(course: c),
                ),
              ),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: loadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: onLoadMore,
                          child: const Text(
                            'Load more',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: AppTheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No courses assigned yet',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your enrolled courses will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load courses',
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.error),
            ),
          ),
          if (onRefresh != null)
            TextButton(
              onPressed: onRefresh,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  final CourseProgressItem course;

  const _CourseProgressCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = course.progressPercent;
    final pctInt = (pct * 100).round();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.courseLessonScreen,
        arguments: {'courseId': course.id, 'courseTitle': course.title},
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${course.lessonsCompleted} / ${course.totalLessons} lessons',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pctInt%',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: pct >= 1.0 ? AppTheme.secondary : AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppTheme.outlineVariant.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 1.0 ? AppTheme.secondary : AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
