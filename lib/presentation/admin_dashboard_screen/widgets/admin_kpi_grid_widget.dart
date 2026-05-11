import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class AdminKpiGridWidget extends StatefulWidget {
  const AdminKpiGridWidget({super.key});

  @override
  State<AdminKpiGridWidget> createState() => _AdminKpiGridWidgetState();
}

class _AdminKpiGridWidgetState extends State<AdminKpiGridWidget> {
  bool _isLoading = true;
  AdminKpiData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.instance.fetchAdminKpiCached();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= AppBreakpoints.desktop
        ? 6
        : width >= AppBreakpoints.wide
        ? 3
        : 2;
    final aspectRatio = crossAxisCount == 6
        ? 1.25
        : crossAxisCount == 3
        ? 1.65
        : 1.45;

    if (_isLoading) {
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: aspectRatio,
        children: List.generate(
          6,
          (_) => const LoadingSkeletonWidget(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 12,
          ),
        ),
      );
    }

    final d = _data;
    final kpis = [
      _AdminKpi(
        label: 'Total Students',
        value: '${d?.totalStudents ?? 0}',
        icon: Icons.people_rounded,
        iconColor: AppTheme.primary,
        iconBg: AppTheme.primaryContainer,
        subLabel: 'Registered students',
      ),
      _AdminKpi(
        label: 'Active Batches',
        value: '${d?.activeBatches ?? 0}',
        icon: Icons.groups_rounded,
        iconColor: AppTheme.secondary,
        iconBg: AppTheme.secondaryContainer,
        subLabel: 'Running batches',
      ),
      _AdminKpi(
        label: 'Pending Doubts',
        value: '${d?.pendingDoubts ?? 0}',
        icon: Icons.help_rounded,
        iconColor: AppTheme.error,
        iconBg: AppTheme.errorContainer,
        subLabel: 'Awaiting reply',
      ),
      _AdminKpi(
        label: 'Courses',
        value: '${d?.totalCourses ?? 0}',
        icon: Icons.library_books_rounded,
        iconColor: AppTheme.info,
        iconBg: AppTheme.infoContainer,
        subLabel: 'Total courses',
      ),
      _AdminKpi(
        label: 'Tests Published',
        value: '${d?.testsPublished ?? 0}',
        icon: Icons.assignment_rounded,
        iconColor: AppTheme.warning,
        iconBg: AppTheme.warningContainer,
        subLabel: 'Live tests',
      ),
      _AdminKpi(
        label: 'Total Lessons',
        value: '${d?.totalLessons ?? 0}',
        icon: Icons.play_lesson_rounded,
        iconColor: AppTheme.accent,
        iconBg: AppTheme.accentContainer,
        subLabel: 'Content items',
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: aspectRatio,
      children: kpis.map((kpi) => _AdminKpiCard(kpi: kpi)).toList(),
    );
  }
}

class _AdminKpi {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _AdminKpi({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class _AdminKpiCard extends StatelessWidget {
  final _AdminKpi kpi;
  const _AdminKpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kpi.iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(kpi.icon, size: 18, color: kpi.iconColor),
          ),
          const Spacer(),
          Text(
            kpi.value,
            style: const TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            kpi.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi.subLabel,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
