import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_navigation.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  bool _isLoading = true;
  String? _error;
  List<CourseProgressItem> _courses = [];
  bool _hasMore = true;
  bool _loadingMore = false;
  int _page = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadCourses(reset: true);
  }

  Future<void> _loadCourses({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 0;
        _hasMore = true;
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final page = reset ? 0 : _page;
      final items = await SupabaseService.instance.fetchCourseProgress(
        page: page,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _courses = items;
          } else {
            _courses = [..._courses, ...items];
          }
          _page = page + 1;
          _hasMore = items.length == _pageSize;
          _isLoading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _openCourse(CourseProgressItem course) {
    Navigator.pushNamed(
      context,
      AppRoutes.courseLessonScreen,
      arguments: {'courseId': course.id, 'courseTitle': course.title},
    );
  }

  void _onNavDestination(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentDashboardScreen,
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.studentTestsScreen);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.studentDoubtsScreen);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.studentProfileScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = context.isWide;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: Text(
          'My Courses',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => _loadCourses(reset: true),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                StudentNavigationRail(
                  currentIndex: 1,
                  onDestinationSelected: _onNavDestination,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildBody(theme)),
              ],
            )
          : _buildBody(theme),
      bottomNavigationBar: isWide
          ? null
          : StudentBottomNavigation(
              currentIndex: 1,
              onDestinationSelected: _onNavDestination,
            ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load courses',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _loadCourses(reset: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
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

    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 72,
                color: AppTheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No courses available',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Published courses assigned to your batch will appear here.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCourses(reset: true),
      color: AppTheme.primary,
      child: ListView.builder(
        padding: context.adaptivePagePadding(bottom: context.isWide ? 32 : 96),
        itemCount: _courses.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _courses.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _loadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : Center(
                      child: TextButton(
                        onPressed: () => _loadCourses(),
                        child: const Text(
                          'Load more',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontFamily: 'IBM Plex Sans',
                          ),
                        ),
                      ),
                    ),
            );
          }
          final course = _courses[index];
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReading,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CourseCard(
                  course: course,
                  onTap: () => _openCourse(course),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseProgressItem course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = course.progressPercent;
    final pctInt = (pct * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 24,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.lessonsCompleted} / ${course.totalLessons} lessons',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppTheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$pctInt%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
