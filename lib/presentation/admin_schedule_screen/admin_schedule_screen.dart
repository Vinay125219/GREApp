import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AdminScheduleScreen extends StatefulWidget {
  const AdminScheduleScreen({super.key});

  @override
  State<AdminScheduleScreen> createState() => _AdminScheduleScreenState();
}

class _AdminScheduleScreenState extends State<AdminScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _loadError;

  List<Map<String, dynamic>> _courses = [];
  Map<String, dynamic>? _selectedCourse;
  List<Map<String, dynamic>> _lessons = [];
  bool _lessonsLoading = false;
  String? _lessonsError;

  List<Map<String, dynamic>> _tests = [];
  bool _testsLoading = false;
  String? _testsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        SupabaseService.instance.fetchCoursesForSchedule(),
        SupabaseService.instance.fetchTestsWithSchedule(),
      ]);
      if (mounted) {
        setState(() {
          _courses = results[0];
          _tests = results[1];
          _isLoading = false;
          if (_courses.isNotEmpty) {
            _selectedCourse = _courses.first;
            _loadLessons(_courses.first['id'] as String);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = (e as Exception).toString().replaceAll(
            'Exception: ',
            '',
          );
        });
      }
    }
  }

  Future<void> _loadLessons(String courseId) async {
    setState(() {
      _lessonsLoading = true;
      _lessonsError = null;
    });
    try {
      final lessons = await SupabaseService.instance.fetchLessonsWithSchedule(
        courseId,
      );
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _lessonsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lessonsLoading = false;
          _lessonsError = (e as Exception).toString().replaceAll(
            'Exception: ',
            '',
          );
        });
      }
    }
  }

  Future<void> _reloadTests() async {
    setState(() {
      _testsLoading = true;
      _testsError = null;
    });
    try {
      final tests = await SupabaseService.instance.fetchTestsWithSchedule();
      if (mounted) {
        setState(() {
          _tests = tests;
          _testsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testsLoading = false;
          _testsError = (e as Exception).toString().replaceAll(
            'Exception: ',
            '',
          );
        });
      }
    }
  }

  Future<void> _pickDateForLesson(Map<String, dynamic> lesson) async {
    final current = lesson['scheduled_at'] != null
        ? DateTime.tryParse(lesson['scheduled_at'] as String)
        : null;

    final picked = await showDateTimePicker(context, initial: current);
    if (picked == null) return;

    try {
      await SupabaseService.instance.scheduleLessonRelease(
        lessonId: lesson['id'] as String,
        scheduledAt: picked,
      );
      if (_selectedCourse != null) {
        _loadLessons(_selectedCourse!['id'] as String);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lesson scheduled for ${DateFormat('MMM d, y · h:mm a').format(picked)}',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update schedule'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearLessonSchedule(Map<String, dynamic> lesson) async {
    final lessonTitle = lesson['title'] as String? ?? 'this lesson';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Clear Schedule?',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        children: [
                          const TextSpan(
                            text: '1 lesson schedule will be cleared:\n',
                          ),
                          TextSpan(
                            text: '"$lessonTitle"',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The lesson will become immediately available to all students. This action cannot be undone.',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear Schedule'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.instance.scheduleLessonRelease(
        lessonId: lesson['id'] as String,
        scheduledAt: null,
      );
      if (_selectedCourse != null) {
        _loadLessons(_selectedCourse!['id'] as String);
      }
    } catch (_) {}
  }

  Future<void> _pickDateForTest(Map<String, dynamic> test) async {
    final current = test['scheduled_at'] != null
        ? DateTime.tryParse(test['scheduled_at'] as String)
        : null;

    final picked = await showDateTimePicker(context, initial: current);
    if (picked == null) return;

    try {
      await SupabaseService.instance.scheduleTestRelease(
        testId: test['id'] as String,
        scheduledAt: picked,
        status: 'published',
      );
      _reloadTests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test scheduled for ${DateFormat('MMM d, y · h:mm a').format(picked)}',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update schedule'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearTestSchedule(Map<String, dynamic> test) async {
    final testTitle = test['title'] as String? ?? 'this test';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Clear Schedule?',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_rounded,
                    color: AppTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        children: [
                          const TextSpan(
                            text: '1 test schedule will be cleared:\n',
                          ),
                          TextSpan(
                            text: '"$testTitle"',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The test will become immediately available to all students. This action cannot be undone.',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Clear Schedule'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.instance.scheduleTestRelease(
        testId: test['id'] as String,
        scheduledAt: null,
      );
      _reloadTests();
    } catch (_) {}
  }

  Future<DateTime?> showDateTimePicker(
    BuildContext context, {
    DateTime? initial,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (date == null || !context.mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
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
                                'Drip Content Schedule',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Set release dates for lessons & tests',
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
                          onPressed: _loadInitialData,
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: AppTheme.textMuted,
                    indicatorColor: AppTheme.primary,
                    labelStyle: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Lessons'),
                      Tab(text: 'Tests'),
                    ],
                  ),
                ],
              ),
            ),
            // Error banner
            if (_loadError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: AppTheme.errorContainer,
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load: $_loadError',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadInitialData,
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 12, color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLessonsTab(theme),
                        _buildTestsTab(theme),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsTab(ThemeData theme) {
    return Column(
      children: [
        if (_courses.isNotEmpty)
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCourse?['id'] as String?,
                      isExpanded: true,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                        final course = _courses.firstWhere(
                          (c) => c['id'] == val,
                        );
                        setState(() => _selectedCourse = course);
                        _loadLessons(val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_lessonsError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.errorContainer,
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppTheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _lessonsError!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.error),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _lessonsLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _courses.isEmpty
              ? _emptyState(
                  'No courses found',
                  'Create a course first to schedule its lessons',
                  Icons.menu_book_outlined,
                )
              : _lessons.isEmpty
              ? _emptyState(
                  'No lessons in this course',
                  'Add lessons to this course to set their release schedule',
                  Icons.video_library_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lessons.length,
                  itemBuilder: (ctx, i) => _LessonScheduleCard(
                    lesson: _lessons[i],
                    onSchedule: () => _pickDateForLesson(_lessons[i]),
                    onClear: () => _clearLessonSchedule(_lessons[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTestsTab(ThemeData theme) {
    if (_testsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                _testsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _reloadTests,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _testsLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          )
        : _tests.isEmpty
        ? _emptyState(
            'No tests found',
            'Create and publish tests to schedule them',
            Icons.assignment_outlined,
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tests.length,
            itemBuilder: (ctx, i) => _TestScheduleCard(
              test: _tests[i],
              onSchedule: () => _pickDateForTest(_tests[i]),
              onClear: () => _clearTestSchedule(_tests[i]),
            ),
          );
  }

  Widget _emptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
}

class _LessonScheduleCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onSchedule;
  final VoidCallback onClear;

  const _LessonScheduleCard({
    required this.lesson,
    required this.onSchedule,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledAt = lesson['scheduled_at'] != null
        ? DateTime.tryParse(lesson['scheduled_at'] as String)
        : null;
    final now = DateTime.now();
    final isReleased = scheduledAt == null || scheduledAt.isBefore(now);
    final lessonType = lesson['lesson_type'] as String? ?? 'text';

    Color typeColor;
    IconData typeIcon;
    switch (lessonType) {
      case 'video':
        typeColor = AppTheme.accent;
        typeIcon = Icons.play_circle_outline_rounded;
        break;
      case 'pdf':
        typeColor = AppTheme.error;
        typeIcon = Icons.picture_as_pdf_outlined;
        break;
      case 'quiz':
        typeColor = AppTheme.warning;
        typeIcon = Icons.quiz_outlined;
        break;
      default:
        typeColor = AppTheme.secondary;
        typeIcon = Icons.article_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheduledAt != null && !isReleased
              ? AppTheme.warning.withValues(alpha: 0.4)
              : AppTheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(typeIcon, size: 18, color: typeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson['title'] as String? ?? 'Untitled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  scheduledAt != null
                      ? Row(
                          children: [
                            Icon(
                              isReleased
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.schedule_rounded,
                              size: 12,
                              color: isReleased
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isReleased
                                    ? 'Released ${DateFormat('MMM d, y').format(scheduledAt)}'
                                    : 'Releases ${DateFormat('MMM d, y · h:mm a').format(scheduledAt)}',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isReleased
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'No schedule — always available',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (scheduledAt != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.clear_rounded,
                        size: 14,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onSchedule,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scheduledAt != null ? 'Edit' : 'Set',
                          style: const TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TestScheduleCard extends StatelessWidget {
  final Map<String, dynamic> test;
  final VoidCallback onSchedule;
  final VoidCallback onClear;

  const _TestScheduleCard({
    required this.test,
    required this.onSchedule,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduledAt = test['scheduled_at'] != null
        ? DateTime.tryParse(test['scheduled_at'] as String)
        : null;
    final now = DateTime.now();
    final isReleased = scheduledAt == null || scheduledAt.isBefore(now);
    final status = test['status'] as String? ?? 'draft';
    final batch = test['batches'] as Map<String, dynamic>?;

    Color statusColor = status == 'published'
        ? AppTheme.success
        : status == 'archived'
        ? AppTheme.textMuted
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheduledAt != null && !isReleased
              ? AppTheme.warning.withValues(alpha: 0.4)
              : AppTheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test['title'] as String? ?? 'Untitled Test',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (batch != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            batch['name'] as String? ?? '',
                            style: const TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  scheduledAt != null
                      ? Row(
                          children: [
                            Icon(
                              isReleased
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.schedule_rounded,
                              size: 12,
                              color: isReleased
                                  ? AppTheme.success
                                  : AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isReleased
                                    ? 'Released ${DateFormat('MMM d, y').format(scheduledAt)}'
                                    : 'Releases ${DateFormat('MMM d, y · h:mm a').format(scheduledAt)}',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isReleased
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'No schedule set',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (scheduledAt != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.clear_rounded,
                        size: 14,
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onSchedule,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scheduledAt != null ? 'Edit' : 'Set',
                          style: const TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
