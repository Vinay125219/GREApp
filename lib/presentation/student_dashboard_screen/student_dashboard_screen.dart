import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_navigation.dart';
import './widgets/student_course_progress_widget.dart';
import './widgets/student_greeting_widget.dart';
import './widgets/student_kpi_row_widget.dart';
import './widgets/student_score_chart_widget.dart';
import './widgets/student_upcoming_test_widget.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentNavIndex = 0;

  // Live data state
  bool _kpiLoading = true;
  bool _coursesLoading = true;
  bool _testLoading = true;

  StudentKpiData? _kpiData;
  List<CourseProgressItem> _courses = [];
  UpcomingTestItem? _upcomingTest;
  String? _kpiError;
  String? _coursesError;

  // Pagination
  int _coursePage = 0;
  static const int _coursePageSize = 10;
  bool _hasMoreCourses = true;
  bool _loadingMoreCourses = false;

  // User profile
  String _userName = '';
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _loadUserProfile();
    _loadKpi();
    _loadCourses(reset: true);
    _loadUpcomingTest();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await SupabaseService.instance.fetchCurrentUserProfile();
      if (profile != null && mounted) {
        final name = (profile['full_name'] as String?) ?? '';
        final initials = name.trim().isEmpty
            ? '?'
            : name
                  .trim()
                  .split(' ')
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join();
        setState(() {
          _userName = name;
          _userInitials = initials;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadKpi() async {
    if (!mounted) return;
    setState(() {
      _kpiLoading = true;
      _kpiError = null;
    });
    try {
      final data = await SupabaseService.instance.fetchStudentKpi();
      if (mounted) {
        setState(() {
          _kpiData = data;
          _kpiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kpiError = e.toString();
          _kpiLoading = false;
        });
      }
    }
  }

  Future<void> _loadCourses({bool reset = false}) async {
    if (!mounted) return;
    if (reset) {
      setState(() {
        _coursesLoading = true;
        _coursesError = null;
        _coursePage = 0;
        _hasMoreCourses = true;
      });
    } else {
      if (!_hasMoreCourses || _loadingMoreCourses) return;
      setState(() => _loadingMoreCourses = true);
    }
    try {
      final page = reset ? 0 : _coursePage;
      final items = await SupabaseService.instance.fetchCourseProgress(
        page: page,
        pageSize: _coursePageSize,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _courses = items;
          } else {
            _courses = [..._courses, ...items];
          }
          _coursePage = page + 1;
          _hasMoreCourses = items.length == _coursePageSize;
          _coursesLoading = false;
          _loadingMoreCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _coursesError = e.toString();
          _coursesLoading = false;
          _loadingMoreCourses = false;
        });
      }
    }
  }

  Future<void> _loadUpcomingTest() async {
    if (!mounted) return;
    setState(() => _testLoading = true);
    try {
      final test = await SupabaseService.instance.fetchNextUpcomingTest();
      if (mounted) {
        setState(() {
          _upcomingTest = test;
          _testLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _testLoading = false);
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.studentCoursesScreen);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.studentTestsScreen);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.studentDoubtsScreen);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.studentProfileScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWide;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: isWide ? _buildTabletLayout(theme) : _buildPhoneLayout(theme),
      ),
      bottomNavigationBar: isWide
          ? null
          : StudentBottomNavigation(
              currentIndex: _currentNavIndex,
              onDestinationSelected: _onNavTap,
            ),
    );
  }

  Widget _buildPhoneLayout(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          floating: true,
          snap: true,
          toolbarHeight: 60,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'GREApp',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.notificationsScreen,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryContainer,
                child: Text(
                  _userInitials.isEmpty ? '?' : _userInitials,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StudentGreetingWidget(userName: _userName),
                const SizedBox(height: 20),
                StudentKpiRowWidget(isLoading: _kpiLoading, kpiData: _kpiData),
                const SizedBox(height: 20),
                StudentUpcomingTestWidget(
                  isLoading: _testLoading,
                  upcomingTest: _upcomingTest,
                ),
                const SizedBox(height: 20),
                _buildScoreTrendSection(theme),
                const SizedBox(height: 20),
                StudentCourseProgressWidget(
                  isLoading: _coursesLoading,
                  courses: _courses,
                  hasMore: _hasMoreCourses,
                  loadingMore: _loadingMoreCourses,
                  error: _coursesError,
                  onLoadMore: () => _loadCourses(),
                  onRefresh: () => _loadCourses(reset: true),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(ThemeData theme) {
    final useTwoPane = context.screenWidth >= 1100;
    return Row(
      children: [
        SafeArea(
          right: false,
          bottom: false,
          child: StudentNavigationRail(
            currentIndex: _currentNavIndex,
            onDestinationSelected: _onNavTap,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AdaptivePageBody(
                  padding: context.adaptivePagePadding(
                    bottom: MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StudentGreetingWidget(userName: _userName),
                      const SizedBox(height: 20),
                      if (useTwoPane)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildStudentMainColumn()),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: StudentUpcomingTestWidget(
                                isLoading: _testLoading,
                                upcomingTest: _upcomingTest,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildStudentMainColumn(),
                        const SizedBox(height: 20),
                        StudentUpcomingTestWidget(
                          isLoading: _testLoading,
                          upcomingTest: _upcomingTest,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentMainColumn() {
    return Column(
      children: [
        StudentKpiRowWidget(isLoading: _kpiLoading, kpiData: _kpiData),
        const SizedBox(height: 20),
        StudentScoreChartWidget(isLoading: _kpiLoading),
        const SizedBox(height: 12),
        _buildLearningPathCard(),
        const SizedBox(height: 20),
        StudentCourseProgressWidget(
          isLoading: _coursesLoading,
          courses: _courses,
          hasMore: _hasMoreCourses,
          loadingMore: _loadingMoreCourses,
          error: _coursesError,
          onLoadMore: () => _loadCourses(),
          onRefresh: () => _loadCourses(reset: true),
        ),
      ],
    );
  }

  Widget _buildScoreTrendSection(ThemeData theme) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.studentAnalyticsScreen),
      child: StudentScoreChartWidget(isLoading: _kpiLoading),
    );
  }

  Widget _buildLearningPathCard() {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.studentDripContentScreen),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.timeline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Path',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'View scheduled lessons & tests',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
