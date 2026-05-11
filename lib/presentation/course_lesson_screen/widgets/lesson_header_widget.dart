import '../../../core/app_export.dart';
import '../course_lesson_screen.dart';

class LessonHeaderWidget extends StatelessWidget {
  final LessonItem lesson;
  final bool isBookmarked;
  final VoidCallback onBookmark;
  final VoidCallback? onOpenSidebar;
  final VoidCallback onBack;

  const LessonHeaderWidget({
    super.key,
    required this.lesson,
    required this.isBookmarked,
    required this.onBookmark,
    required this.onOpenSidebar,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    _TypeChip(type: lesson.type),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 11,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(lesson.duration, style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              color: isBookmarked ? AppTheme.primary : AppTheme.textMuted,
            ),
            onPressed: onBookmark,
          ),
          if (onOpenSidebar != null)
            IconButton(
              icon: const Icon(
                Icons.format_list_bulleted_rounded,
                color: AppTheme.textSecondary,
              ),
              onPressed: onOpenSidebar,
            ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case 'video':
        color = AppTheme.primary;
        icon = Icons.play_circle_outline_rounded;
        label = 'Video';
        break;
      case 'pdf':
        color = AppTheme.error;
        icon = Icons.picture_as_pdf_rounded;
        label = 'PDF';
        break;
      case 'notes':
        color = AppTheme.secondary;
        icon = Icons.notes_rounded;
        label = 'Notes';
        break;
      default:
        color = AppTheme.textMuted;
        icon = Icons.article_outlined;
        label = type;
    }

    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
