import 'package:universal_html/html.dart' as html;

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../course_lesson_screen.dart';

// ignore: avoid_web_libraries_in_flutter

class LessonContentWidget extends StatelessWidget {
  final LessonItem lesson;
  final double videoProgress;
  final ValueChanged<double> onVideoProgressChanged;

  const LessonContentWidget({
    super.key,
    required this.lesson,
    required this.videoProgress,
    required this.onVideoProgressChanged,
  });

  @override
  Widget build(BuildContext context) {
    switch (lesson.type) {
      case 'video':
        return _VideoContentWidget(
          lesson: lesson,
          progress: videoProgress,
          onProgressChanged: onVideoProgressChanged,
        );
      case 'pdf':
        return _PdfContentWidget(lesson: lesson);
      case 'notes':
        return _NotesContentWidget(lesson: lesson);
      default:
        return _VideoContentWidget(
          lesson: lesson,
          progress: videoProgress,
          onProgressChanged: onVideoProgressChanged,
        );
    }
  }
}

class _VideoContentWidget extends StatefulWidget {
  final LessonItem lesson;
  final double progress;
  final ValueChanged<double> onProgressChanged;

  const _VideoContentWidget({
    required this.lesson,
    required this.progress,
    required this.onProgressChanged,
  });

  @override
  State<_VideoContentWidget> createState() => _VideoContentWidgetState();
}

class _VideoContentWidgetState extends State<_VideoContentWidget> {
  bool _isPlaying = false;

  void _openVideo() {
    final url = widget.lesson.contentUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No video URL available for this lesson.'),
        ),
      );
      return;
    }
    html.window.open(url, '_blank');
    setState(() => _isPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl =
        widget.lesson.contentUrl != null &&
        widget.lesson.contentUrl!.isNotEmpty;
    final videoHeight =
        (MediaQuery.sizeOf(context).width * (context.isWide ? 0.38 : 0.56))
            .clamp(210.0, 420.0)
            .toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video player card
        Container(
          width: double.infinity,
          height: videoHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImageWidget(
                  imageUrl:
                      'https://images.pexels.com/photos/5212345/pexels-photo-5212345.jpeg',
                  width: double.infinity,
                  height: videoHeight,
                  fit: BoxFit.cover,
                  semanticLabel:
                      'GRE Verbal lesson video thumbnail showing study materials on desk',
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
              // Play button — opens video URL in new tab
              GestureDetector(
                onTap: _openVideo,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: hasUrl
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 32,
                    color: hasUrl ? AppTheme.primary : Colors.white54,
                  ),
                ),
              ),
              // Duration badge
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.lesson.duration,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Video badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.smart_display_rounded,
                        size: 13,
                        color: Color(0xFFFF0000),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasUrl
                            ? (_isPlaying ? 'Opened' : 'Tap to Play')
                            : 'No Video',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Open Video button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: hasUrl ? _openVideo : null,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open Video in Browser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(
                color: hasUrl ? AppTheme.primary : AppTheme.outlineVariant,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Watch Progress',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(widget.progress * 100).toInt()}% watched',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppTheme.primary,
                inactiveTrackColor: AppTheme.outlineVariant,
                thumbColor: AppTheme.primary,
              ),
              child: Slider(
                value: widget.progress,
                onChanged: widget.onProgressChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Lesson description
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About This Lesson',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'In this lesson, you will master strategies for tackling Double and Triple Blank Text Completion questions in GRE Verbal Reasoning. Learn how to identify logical relationships between blanks, use elimination strategies, and avoid common traps that test-takers fall into.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    [
                      'Double Blanks',
                      'Triple Blanks',
                      'Elimination Strategy',
                      'Logic Mapping',
                    ].map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PdfContentWidget extends StatelessWidget {
  final LessonItem lesson;
  const _PdfContentWidget({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPdf = lesson.contentUrl != null && lesson.contentUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PDF preview card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary.withValues(alpha: 0.08),
                AppTheme.secondary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 40,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lesson.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                hasPdf
                    ? 'PDF document • Tap to open in reader'
                    : 'PDF not yet available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              if (lesson.durationMins != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${lesson.durationMins} min read',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: hasPdf
                      ? () => Navigator.pushNamed(
                          context,
                          '/pdf-viewer-screen',
                          arguments: {
                            'pdfUrl': lesson.contentUrl,
                            'title': lesson.title,
                            'lessonId': lesson.id,
                          },
                        )
                      : null,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(
                    hasPdf ? 'Open PDF Reader' : 'PDF Not Available',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasPdf
                        ? AppTheme.primary
                        : AppTheme.outlineVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Info chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.picture_as_pdf_rounded,
              label: 'PDF Document',
              color: AppTheme.error,
            ),
            _InfoChip(
              icon: Icons.zoom_in_rounded,
              label: 'Pinch to Zoom',
              color: AppTheme.primary,
            ),
            _InfoChip(
              icon: Icons.bookmark_rounded,
              label: 'Page Navigation',
              color: AppTheme.secondary,
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesContentWidget extends StatelessWidget {
  final LessonItem lesson;

  const _NotesContentWidget({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final notes = [
      _NoteSection(
        heading: 'Key Strategy: Logical Bridge',
        content:
            'Every blank in a Text Completion question is connected to the rest of the sentence through a logical relationship. Identify whether the blank continues the same idea (same-direction) or contrasts it (opposite-direction).',
        highlight: true,
      ),
      _NoteSection(
        heading: 'Signal Words — Same Direction',
        content:
            'and, also, moreover, furthermore, in addition, similarly, likewise, consequently, therefore, thus, hence, so, as a result',
        highlight: false,
      ),
      _NoteSection(
        heading: 'Signal Words — Opposite Direction',
        content:
            'but, however, although, despite, in spite of, yet, while, whereas, on the other hand, nevertheless, nonetheless',
        highlight: false,
      ),
      _NoteSection(
        heading: '⚠️ Common Trap',
        content:
            'For triple-blank questions, never evaluate each blank independently. The three blanks are semantically linked — an incorrect choice in blank (i) will cascade errors into blanks (ii) and (iii).',
        highlight: true,
        isWarning: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notes_rounded,
                size: 16,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Study Notes · ${lesson.title}',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...notes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NoteCard(note: note),
          ),
        ),
      ],
    );
  }
}

class _NoteSection {
  final String heading;
  final String content;
  final bool highlight;
  final bool isWarning;

  const _NoteSection({
    required this.heading,
    required this.content,
    this.highlight = false,
    this.isWarning = false,
  });
}

class _NoteCard extends StatelessWidget {
  final _NoteSection note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color borderColor = note.isWarning
        ? AppTheme.warning
        : note.highlight
        ? AppTheme.primary
        : AppTheme.outlineVariant;
    Color bgColor = note.isWarning
        ? AppTheme.warningContainer
        : note.highlight
        ? AppTheme.primaryContainer.withValues(alpha: 0.4)
        : AppTheme.surface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.heading,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: note.isWarning ? AppTheme.warning : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note.content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
