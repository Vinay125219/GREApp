import '../../../core/app_export.dart';

class TestBottomBarWidget extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final bool hasAnswer;
  final bool hasSubmitted;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onSubmitQuestion;

  const TestBottomBarWidget({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.hasAnswer,
    required this.hasSubmitted,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmitQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Prev'),
              style: OutlinedButton.styleFrom(
                foregroundColor: onPrevious != null
                    ? AppTheme.primary
                    : AppTheme.textMuted,
                side: BorderSide(
                  color: onPrevious != null
                      ? AppTheme.primary
                      : AppTheme.outline,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Save & Check answer
          if (!hasSubmitted)
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: hasAnswer ? onSubmitQuestion : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: hasAnswer
                        ? AppTheme.secondary
                        : AppTheme.outline,
                    disabledBackgroundColor: AppTheme.outline,
                    textStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Save & Check'),
                ),
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppTheme.success,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Next
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Text('Next'),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
              style: FilledButton.styleFrom(
                backgroundColor: onNext != null
                    ? AppTheme.primary
                    : AppTheme.outline,
                disabledBackgroundColor: AppTheme.outline,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }
}
