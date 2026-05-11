import '../../../core/app_export.dart';

class StudentScoreChartWidget extends StatelessWidget {
  final bool isLoading;

  const StudentScoreChartWidget({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return const LoadingSkeletonWidget(
        width: double.infinity,
        height: 160,
        borderRadius: 12,
      );
    }

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.studentAnalyticsScreen),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Performance Analytics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'View',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to see score trends & subject insights',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AnalyticsPreviewItem(
                  icon: Icons.trending_up_rounded,
                  label: 'Score Trend',
                  color: AppTheme.primary,
                ),
                _AnalyticsPreviewItem(
                  icon: Icons.pie_chart_rounded,
                  label: 'Subject-wise',
                  color: AppTheme.secondary,
                ),
                _AnalyticsPreviewItem(
                  icon: Icons.history_rounded,
                  label: 'Test History',
                  color: AppTheme.accent,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsPreviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _AnalyticsPreviewItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
