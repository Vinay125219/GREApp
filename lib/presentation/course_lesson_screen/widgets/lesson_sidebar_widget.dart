import '../../../core/app_export.dart';
import '../course_lesson_screen.dart';

class LessonSidebarWidget extends StatelessWidget {
  final List<LessonItem> lessons;
  final int selectedIndex;
  final ValueChanged<int> onSelectLesson;
  final VoidCallback? onClose;

  const LessonSidebarWidget({
    super.key,
    required this.lessons,
    required this.selectedIndex,
    required this.onSelectLesson,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = lessons.where((l) => l.isCompleted).length;

    return Container(
      color: AppTheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course Lessons',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Module 4 · $completedCount/${lessons.length} completed',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: completedCount / lessons.length,
                          minHeight: 4,
                          backgroundColor: AppTheme.outlineVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
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
          // Lesson list
          Expanded(
            child: ListView.builder(
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                final isSelected = index == selectedIndex;
                return _LessonListItem(
                  lesson: lesson,
                  index: index,
                  isSelected: isSelected,
                  onTap: () => onSelectLesson(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonListItem extends StatelessWidget {
  final LessonItem lesson;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _LessonListItem({
    required this.lesson,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color iconColor;
    IconData typeIcon;
    switch (lesson.type) {
      case 'video':
        typeIcon = Icons.play_circle_outline_rounded;
        iconColor = AppTheme.primary;
        break;
      case 'pdf':
        typeIcon = Icons.picture_as_pdf_rounded;
        iconColor = AppTheme.error;
        break;
      case 'notes':
        typeIcon = Icons.notes_rounded;
        iconColor = AppTheme.secondary;
        break;
      default:
        typeIcon = Icons.article_outlined;
        iconColor = AppTheme.textMuted;
    }

    return InkWell(
      onTap: lesson.isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: AppTheme.primary, width: 3),
                )
              : const Border(
                  left: BorderSide(color: Colors.transparent, width: 3),
                ),
        ),
        child: Row(
          children: [
            // Completion indicator
            SizedBox(
              width: 24,
              height: 24,
              child: lesson.isLocked
                  ? const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    )
                  : lesson.isCompleted
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: AppTheme.secondary,
                    )
                  : Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Container(
                              margin: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
            ),
            const SizedBox(width: 10),
            Icon(
              typeIcon,
              size: 16,
              color: lesson.isLocked ? AppTheme.textMuted : iconColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: lesson.isLocked
                          ? AppTheme.textMuted
                          : AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(lesson.duration, style: theme.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
