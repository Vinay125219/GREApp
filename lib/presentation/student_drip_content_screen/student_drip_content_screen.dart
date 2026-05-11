import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class StudentDripContentScreen extends StatefulWidget {
  const StudentDripContentScreen({super.key});

  @override
  State<StudentDripContentScreen> createState() =>
      _StudentDripContentScreenState();
}

class _StudentDripContentScreenState extends State<StudentDripContentScreen> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _batches = [];
  Map<String, dynamic>? _selectedCourse;
  Map<String, dynamic>? _selectedBatch;

  List<DripContentItem> _timeline = [];
  bool _timelineLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uid = SupabaseService.instance.currentUserId;
      if (uid == null) {
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final results = await Future.wait([
        SupabaseService.instance.client
            .from('course_enrollments')
            .select('course_id, courses(id, title)')
            .eq('student_id', uid),
        SupabaseService.instance.client
            .from('batch_enrollments')
            .select('batch_id, batches(id, name)')
            .eq('student_id', uid)
            .eq('is_active', true),
      ]);

      final courseEnrollments = results[0] as List<dynamic>;
      final batchEnrollments = results[1] as List<dynamic>;

      final courses = courseEnrollments
          .map((e) {
            final c = e['courses'] as Map<String, dynamic>?;
            if (c == null) return null;
            return {'id': c['id'], 'title': c['title']};
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      final batches = batchEnrollments
          .map((e) {
            final b = e['batches'] as Map<String, dynamic>?;
            if (b == null) return null;
            return {'id': b['id'], 'name': b['name']};
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      if (mounted) {
        setState(() {
          _courses = courses;
          _batches = batches;
          _isLoading = false;
          if (courses.isNotEmpty) _selectedCourse = courses.first;
          if (batches.isNotEmpty) _selectedBatch = batches.first;
        });
        _loadTimeline();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load enrollments';
        });
      }
    }
  }

  Future<void> _loadTimeline() async {
    setState(() => _timelineLoading = true);
    try {
      final items = await SupabaseService.instance.fetchStudentDripTimeline(
        courseId: _selectedCourse?['id'] as String?,
        batchId: _selectedBatch?['id'] as String?,
      );
      if (mounted) {
        setState(() {
          _timeline = items;
          _timelineLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _timelineLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _error != null
                  ? _buildError()
                  : _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Path',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your scheduled content timeline',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: _loadTimeline,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      children: [
        if (_courses.isNotEmpty || _batches.isNotEmpty) _buildFilters(theme),
        Expanded(
          child: _timelineLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _timeline.isEmpty
              ? _buildEmptyState()
              : _buildTimeline(theme),
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          if (_courses.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCourse?['id'] as String?,
                      isExpanded: true,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      hint: const Text('Select course'),
                      items: _courses.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id'] as String,
                          child: Text(
                            c['title'] as String? ?? 'Untitled',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedCourse = _courses.firstWhere(
                            (c) => c['id'] == val,
                          );
                        });
                        _loadTimeline();
                      },
                    ),
                  ),
                ),
              ],
            ),
          if (_batches.isNotEmpty)
            Row(
              children: [
                const Icon(
                  Icons.groups_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBatch?['id'] as String?,
                      isExpanded: true,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      hint: const Text('Select batch'),
                      items: _batches.map((b) {
                        return DropdownMenuItem<String>(
                          value: b['id'] as String,
                          child: Text(
                            b['name'] as String? ?? 'Untitled',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedBatch = _batches.firstWhere(
                            (b) => b['id'] == val,
                          );
                        });
                        _loadTimeline();
                      },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(ThemeData theme) {
    final released = _timeline.where((i) => i.isReleased).toList();
    final upcoming = _timeline.where((i) => i.isUpcoming).toList();

    return RefreshIndicator(
      onRefresh: _loadTimeline,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (released.isNotEmpty) ...[
            _SectionHeader(
              title: 'Available Now',
              count: released.length,
              color: AppTheme.success,
              icon: Icons.lock_open_rounded,
            ),
            const SizedBox(height: 8),
            ...released.asMap().entries.map(
              (entry) => _DripTimelineItem(
                item: entry.value,
                isLast: entry.key == released.length - 1 && upcoming.isEmpty,
                onTap: entry.value.isReleased && !entry.value.isCompleted
                    ? () => _navigateToContent(entry.value)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(
              title: 'Upcoming',
              count: upcoming.length,
              color: AppTheme.warning,
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 8),
            ...upcoming.asMap().entries.map(
              (entry) => _DripTimelineItem(
                item: entry.value,
                isLast: entry.key == upcoming.length - 1,
                onTap: null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToContent(DripContentItem item) {
    if (item.type == DripContentType.lesson) {
      Navigator.pushNamed(
        context,
        AppRoutes.courseLessonScreen,
        arguments: {'lessonId': item.id},
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.testEngineScreen,
        arguments: {'testId': item.id},
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                size: 36,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No content scheduled yet',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your learning path will appear here once your instructor schedules lessons and tests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadEnrollments,
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _DripTimelineItem extends StatelessWidget {
  final DripContentItem item;
  final bool isLast;
  final VoidCallback? onTap;

  const _DripTimelineItem({
    required this.item,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTest = item.type == DripContentType.test;
    final isLocked = !item.isReleased;

    Color accentColor;
    IconData contentIcon;
    if (isTest) {
      accentColor = AppTheme.primary;
      contentIcon = Icons.assignment_rounded;
    } else {
      switch (item.contentType) {
        case 'video':
          accentColor = AppTheme.accent;
          contentIcon = Icons.play_circle_outline_rounded;
          break;
        case 'pdf':
          accentColor = AppTheme.error;
          contentIcon = Icons.picture_as_pdf_outlined;
          break;
        case 'quiz':
          accentColor = AppTheme.warning;
          contentIcon = Icons.quiz_outlined;
          break;
        default:
          accentColor = AppTheme.secondary;
          contentIcon = Icons.article_outlined;
      }
    }

    if (isLocked) {
      accentColor = AppTheme.textMuted;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: item.isCompleted
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : isLocked
                        ? AppTheme.outlineVariant
                        : accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isCompleted
                          ? AppTheme.success
                          : isLocked
                          ? AppTheme.textMuted
                          : accentColor,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    item.isCompleted
                        ? Icons.check_rounded
                        : isLocked
                        ? Icons.lock_rounded
                        : contentIcon,
                    size: 14,
                    color: item.isCompleted
                        ? AppTheme.success
                        : isLocked
                        ? AppTheme.textMuted
                        : accentColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariant,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLocked ? AppTheme.surfaceVariant : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isCompleted
                        ? AppTheme.success.withValues(alpha: 0.3)
                        : isLocked
                        ? AppTheme.outlineVariant
                        : accentColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isTest
                                      ? 'TEST'
                                      : item.contentType.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'IBM Plex Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (item.isCompleted) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'DONE',
                                    style: TextStyle(
                                      fontFamily: 'IBM Plex Sans',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.success,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isLocked
                                  ? AppTheme.textMuted
                                  : AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          if (item.scheduledAt != null)
                            Row(
                              children: [
                                Icon(
                                  isLocked
                                      ? Icons.schedule_rounded
                                      : Icons.event_available_rounded,
                                  size: 11,
                                  color: isLocked
                                      ? AppTheme.warning
                                      : AppTheme.success,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    isLocked
                                        ? 'Unlocks ${DateFormat('MMM d, y · h:mm a').format(item.scheduledAt!)}'
                                        : 'Released ${DateFormat('MMM d, y').format(item.scheduledAt!)}',
                                    style: TextStyle(
                                      fontFamily: 'IBM Plex Sans',
                                      fontSize: 11,
                                      color: isLocked
                                          ? AppTheme.warning
                                          : AppTheme.success,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          else
                            const Text(
                              'Always available',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          if (item.durationMins != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${item.durationMins} mins',
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isLocked && !item.isCompleted)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
