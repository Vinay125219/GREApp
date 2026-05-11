import '../../../core/app_export.dart';

class LessonActionBarWidget extends StatelessWidget {
  final int currentIndex;
  final int totalLessons;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onMarkComplete;
  final bool isCompleted;

  const LessonActionBarWidget({
    super.key,
    required this.currentIndex,
    required this.totalLessons,
    required this.onPrevious,
    required this.onNext,
    required this.onMarkComplete,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Lesson ${currentIndex + 1} of $totalLessons',
                style: theme.textTheme.labelSmall,
              ),
              const Spacer(),
              if (!isCompleted)
                FilledButton.icon(
                  onPressed: onMarkComplete,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Mark Complete'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppTheme.success,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onPrevious != null
                        ? AppTheme.primary
                        : AppTheme.textMuted,
                    side: BorderSide(
                      color: onPrevious != null
                          ? AppTheme.primary
                          : AppTheme.outline,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: const Text('Next'),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16),
                  style: FilledButton.styleFrom(
                    backgroundColor: onNext != null
                        ? AppTheme.primary
                        : AppTheme.outline,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
