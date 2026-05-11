import '../../../core/app_export.dart';
import '../test_engine_screen.dart';

class TestPaletteWidget extends StatelessWidget {
  final List<TestQuestion> questions;
  final int currentIndex;
  final Map<int, int?> selectedAnswers;
  final Set<int> markedForReview;
  final ValueChanged<int> onSelectQuestion;
  final VoidCallback? onClose;
  final VoidCallback onSubmit;

  const TestPaletteWidget({
    super.key,
    required this.questions,
    required this.currentIndex,
    required this.selectedAnswers,
    required this.markedForReview,
    required this.onSelectQuestion,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answeredCount = selectedAnswers.length;
    final markedCount = markedForReview.length;
    final unansweredCount = questions.length - answeredCount;

    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Question Palette',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    _LegendItem(
                      color: AppTheme.primary,
                      label: 'Current',
                      isCurrent: true,
                    ),
                    const SizedBox(width: 12),
                    _LegendItem(color: AppTheme.secondary, label: 'Answered'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _LegendItem(color: AppTheme.warning, label: 'Marked'),
                    const SizedBox(width: 12),
                    _LegendItem(
                      color: AppTheme.outlineVariant,
                      label: 'Not Visited',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatChip(
                  value: answeredCount,
                  label: 'Answered',
                  color: AppTheme.secondary,
                ),
                const SizedBox(width: 6),
                _StatChip(
                  value: unansweredCount,
                  label: 'Pending',
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                _StatChip(
                  value: markedCount,
                  label: 'Marked',
                  color: AppTheme.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1.0,
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final isCurrent = index == currentIndex;
                  final isAnswered = selectedAnswers.containsKey(index);
                  final isMarked = markedForReview.contains(index);

                  Color bgColor;
                  Color textColor;
                  if (isCurrent) {
                    bgColor = AppTheme.primary;
                    textColor = Colors.white;
                  } else if (isMarked) {
                    bgColor = AppTheme.warningContainer;
                    textColor = AppTheme.warning;
                  } else if (isAnswered) {
                    bgColor = AppTheme.successContainer;
                    textColor = AppTheme.success;
                  } else {
                    bgColor = AppTheme.surfaceVariant;
                    textColor = AppTheme.textMuted;
                  }

                  return InkWell(
                    onTap: () => onSelectQuestion(index),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrent
                            ? Border.all(color: AppTheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Submit button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Submit Test'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCurrent;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isCurrent ? color : color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: isCurrent ? Border.all(color: color, width: 2) : null,
          ),
          child: isCurrent
              ? null
              : Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
