import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class StudentKpiRowWidget extends StatelessWidget {
  final bool isLoading;
  final StudentKpiData? kpiData;

  const StudentKpiRowWidget({super.key, required this.isLoading, this.kpiData});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 520 ? 2 : 4;

    if (isLoading) {
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: crossAxisCount == 2 ? 1.55 : 1.15,
        children: List.generate(
          4,
          (_) => const LoadingSkeletonWidget(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 12,
          ),
        ),
      );
    }

    final streak = kpiData?.studyStreakDays ?? 0;
    final tests = kpiData?.testsTaken ?? 0;
    final accuracy = kpiData?.accuracy ?? 0.0;
    final doubts = kpiData?.openDoubts ?? 0;

    final kpis = [
      _KpiData(
        label: 'Study Streak',
        value: streak.toString(),
        unit: 'days',
        icon: Icons.local_fire_department_rounded,
        iconColor: const Color(0xFFB45309),
        bgColor: const Color(0xFFFEF3C7),
      ),
      _KpiData(
        label: 'Tests Taken',
        value: tests.toString(),
        unit: 'total',
        icon: Icons.assignment_turned_in_rounded,
        iconColor: AppTheme.primary,
        bgColor: AppTheme.primaryContainer,
      ),
      _KpiData(
        label: 'Accuracy',
        value: accuracy > 0 ? accuracy.toStringAsFixed(0) : '—',
        unit: '%',
        icon: Icons.gps_fixed_rounded,
        iconColor: AppTheme.secondary,
        bgColor: AppTheme.secondaryContainer,
      ),
      _KpiData(
        label: 'Doubts',
        value: doubts.toString(),
        unit: 'open',
        icon: Icons.help_outline_rounded,
        iconColor: AppTheme.error,
        bgColor: AppTheme.errorContainer,
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: crossAxisCount == 2 ? 1.55 : 1.15,
      children: kpis.map((kpi) => _KpiCard(data: kpi)).toList(),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _KpiData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: data.bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, size: 16, color: data.iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            data.unit,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
