import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_navigation.dart';

class StudentTestsScreen extends StatefulWidget {
  const StudentTestsScreen({super.key});

  @override
  State<StudentTestsScreen> createState() => _StudentTestsScreenState();
}

class _StudentTestsScreenState extends State<StudentTestsScreen> {
  bool _isLoading = true;
  String? _error;
  List<UpcomingTestItem> _tests = [];
  bool _hasMore = true;
  bool _loadingMore = false;
  int _page = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadTests(reset: true);
  }

  Future<void> _loadTests({bool reset = false}) async {
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
      final items = await SupabaseService.instance.fetchUpcomingTests(
        page: page,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _tests = items;
          } else {
            _tests = [..._tests, ...items];
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

  void _startTest(UpcomingTestItem test) {
    Navigator.pushNamed(
      context,
      AppRoutes.testEngineScreen,
      arguments: {'testId': test.id},
    );
  }

  String _formatSchedule(UpcomingTestItem test) {
    if (test.scheduledAt == null) return 'Available now';
    final now = DateTime.now();
    final diff = test.scheduledAt!.difference(now);
    if (diff.isNegative) return 'Available now';
    if (diff.inDays > 0) {
      return 'In ${diff.inDays}d ${diff.inHours.remainder(24)}h';
    }
    if (diff.inHours > 0) {
      return 'In ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return 'In ${diff.inMinutes}m';
  }

  bool _isAvailable(UpcomingTestItem test) {
    if (test.scheduledAt == null) return true;
    return !test.scheduledAt!.isAfter(DateTime.now());
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
        Navigator.pushReplacementNamed(context, AppRoutes.studentCoursesScreen);
        break;
      case 2:
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
          'Tests',
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
            onPressed: () => _loadTests(reset: true),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                StudentNavigationRail(
                  currentIndex: 2,
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
              currentIndex: 2,
              onDestinationSelected: _onNavDestination,
            ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
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
                'Failed to load tests',
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
                onPressed: () => _loadTests(reset: true),
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

    if (_tests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 72,
                color: AppTheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No tests available',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Published tests assigned to your batch will appear here.',
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
      onRefresh: () => _loadTests(reset: true),
      color: AppTheme.primary,
      child: ListView.builder(
        padding: context.adaptivePagePadding(bottom: context.isWide ? 32 : 96),
        itemCount: _tests.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _tests.length) {
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
                        onPressed: () => _loadTests(),
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
          final test = _tests[index];
          final available = _isAvailable(test);
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxReading,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TestCard(
                  test: test,
                  scheduleLabel: _formatSchedule(test),
                  isAvailable: available,
                  onTap: available ? () => _startTest(test) : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final UpcomingTestItem test;
  final String scheduleLabel;
  final bool isAvailable;
  final VoidCallback? onTap;

  const _TestCard({
    required this.test,
    required this.scheduleLabel,
    required this.isAvailable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                color: isAvailable
                    ? AppTheme.primaryContainer
                    : AppTheme.outlineVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.assignment_rounded,
                size: 24,
                color: isAvailable ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${test.durationMins} min',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppTheme.primaryContainer
                        : AppTheme.outlineVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    scheduleLabel,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isAvailable
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
                if (isAvailable) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Start →',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
