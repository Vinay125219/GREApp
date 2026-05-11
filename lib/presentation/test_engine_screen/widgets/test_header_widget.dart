import '../../../core/app_export.dart';

class TestHeaderWidget extends StatelessWidget {
  final String sectionName;
  final int currentIndex;
  final int totalQuestions;
  final int markedCount;
  final int answeredCount;
  final bool isMarked;
  final int remainingSeconds;
  final VoidCallback onToggleMark;
  final VoidCallback? onOpenPalette;
  final VoidCallback onSubmit;

  const TestHeaderWidget({
    super.key,
    required this.sectionName,
    required this.currentIndex,
    required this.totalQuestions,
    required this.markedCount,
    required this.answeredCount,
    required this.isMarked,
    required this.remainingSeconds,
    required this.onToggleMark,
    required this.onOpenPalette,
    required this.onSubmit,
  });

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isTimeCritical => remainingSeconds <= 300;
  bool get _isTimeWarning => remainingSeconds <= 900;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Section info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      'Q ${currentIndex + 1} of $totalQuestions  ·  $answeredCount answered',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              // Timer
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isTimeCritical
                      ? AppTheme.errorContainer
                      : _isTimeWarning
                      ? AppTheme.warningContainer
                      : AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 14,
                      color: _isTimeCritical
                          ? AppTheme.error
                          : _isTimeWarning
                          ? AppTheme.warning
                          : AppTheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _formatTime(remainingSeconds),
                      style: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _isTimeCritical
                            ? AppTheme.error
                            : _isTimeWarning
                            ? AppTheme.warning
                            : AppTheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Actions
              InkWell(
                onTap: onToggleMark,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isMarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 22,
                    color: isMarked ? AppTheme.warning : AppTheme.textMuted,
                  ),
                ),
              ),
              if (onOpenPalette != null) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: onOpenPalette,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 22,
                          color: AppTheme.textSecondary,
                        ),
                        if (markedCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.warning,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'End Test',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (currentIndex + 1) / totalQuestions,
              minHeight: 3,
              backgroundColor: AppTheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _isTimeCritical ? AppTheme.error : AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
