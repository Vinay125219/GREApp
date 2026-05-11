import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  AdminKpiData? _kpi;
  List<Map<String, dynamic>> _batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.fetchAdminKpi(),
        SupabaseService.instance.fetchBatchEnrollmentStats(),
      ]);
      if (mounted) {
        setState(() {
          _kpi = results[0] as AdminKpiData;
          _batches = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              scrolledUnderElevation: 1,
              floating: true,
              snap: true,
              toolbarHeight: 56,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Analytics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: _load,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : AdaptivePageBody(
                      maxWidth: AppBreakpoints.maxReading,
                      padding: context.adaptivePagePadding(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overview',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: context.isWide ? 4 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: context.isWide ? 1.35 : 1.5,
                            children: [
                              _MetricCard(
                                label: 'Total Students',
                                value: '${_kpi?.totalStudents ?? 0}',
                                icon: Icons.people_rounded,
                                color: AppTheme.primary,
                              ),
                              _MetricCard(
                                label: 'Active Batches',
                                value: '${_kpi?.activeBatches ?? 0}',
                                icon: Icons.groups_rounded,
                                color: AppTheme.secondary,
                              ),
                              _MetricCard(
                                label: 'Tests Published',
                                value: '${_kpi?.testsPublished ?? 0}',
                                icon: Icons.assignment_rounded,
                                color: AppTheme.warning,
                              ),
                              _MetricCard(
                                label: 'Pending Doubts',
                                value: '${_kpi?.pendingDoubts ?? 0}',
                                icon: Icons.help_rounded,
                                color: AppTheme.error,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Batch Enrollment',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_batches.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No batch data available',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: _batches.map((batch) {
                                  final name =
                                      batch['name'] as String? ?? 'Batch';
                                  final enrollments =
                                      batch['batch_enrollments'];
                                  int count = 0;
                                  if (enrollments is List) {
                                    count = enrollments.length;
                                  } else if (enrollments is Map)
                                    count = (enrollments['count'] as int?) ?? 0;

                                  final maxCount = _batches.fold<int>(1, (
                                    max,
                                    b,
                                  ) {
                                    final e = b['batch_enrollments'];
                                    int c = 0;
                                    if (e is List) {
                                      c = e.length;
                                    } else if (e is Map)
                                      c = (e['count'] as int?) ?? 0;
                                    return c > max ? c : max;
                                  });
                                  final ratio = maxCount > 0
                                      ? count / maxCount
                                      : 0.0;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              name,
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            Text(
                                              '$count students',
                                              style: const TextStyle(
                                                fontFamily: 'IBM Plex Mono',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: ratio.toDouble(),
                                            backgroundColor:
                                                AppTheme.outlineVariant,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(AppTheme.primary),
                                            minHeight: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            'Content Summary',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Total Courses',
                            value: '${_kpi?.totalCourses ?? 0}',
                            icon: Icons.library_books_rounded,
                            color: AppTheme.info,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Total Lessons',
                            value: '${_kpi?.totalLessons ?? 0}',
                            icon: Icons.play_lesson_rounded,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: 'Tests Published',
                            value: '${_kpi?.testsPublished ?? 0}',
                            icon: Icons.assignment_turned_in_rounded,
                            color: AppTheme.success,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
