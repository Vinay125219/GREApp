import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class StudentUpcomingTestWidget extends StatelessWidget {
  final bool isLoading;
  final UpcomingTestItem? upcomingTest;

  const StudentUpcomingTestWidget({
    super.key,
    required this.isLoading,
    this.upcomingTest,
  });

  String _formatCountdown(Duration d) {
    if (d.isNegative) return 'Starting soon';
    if (d.inDays > 0) return 'In ${d.inDays}d ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) return 'In ${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return 'In ${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const LoadingSkeletonWidget(
        width: double.infinity,
        height: 100,
        borderRadius: 12,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: upcomingTest != null
                  ? AppTheme.primaryContainer
                  : AppTheme.outlineVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 22,
              color: upcomingTest != null
                  ? AppTheme.primary
                  : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Test',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                upcomingTest == null
                    ? Text(
                        'No upcoming tests scheduled',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upcomingTest!.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${upcomingTest!.durationMins} min',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          if (upcomingTest?.timeUntil != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatCountdown(upcomingTest!.timeUntil!),
                style: const TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
