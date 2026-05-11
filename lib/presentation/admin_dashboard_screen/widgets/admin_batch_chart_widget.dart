import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class AdminBatchChartWidget extends StatefulWidget {
  const AdminBatchChartWidget({super.key});

  @override
  State<AdminBatchChartWidget> createState() => _AdminBatchChartWidgetState();
}

class _AdminBatchChartWidgetState extends State<AdminBatchChartWidget> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final batches = await SupabaseService.instance
          .fetchBatchEnrollmentStats();
      if (mounted) {
        setState(() {
          _batches = batches;
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

    if (_isLoading) {
      return const LoadingSkeletonWidget(
        width: double.infinity,
        height: 160,
        borderRadius: 12,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Enrollment',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text('Students per active batch', style: theme.textTheme.labelSmall),
          const SizedBox(height: 16),
          if (_batches.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 48,
                      color: AppTheme.outlineVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No batch data available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create batches and enroll students to see data',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _batches.map((batch) {
                final name = batch['name'] as String? ?? 'Batch';
                final enrollments = batch['batch_enrollments'];
                int count = 0;
                if (enrollments is List) {
                  count = enrollments.length;
                } else if (enrollments is Map)
                  count = (enrollments['count'] as int?) ?? 0;

                final maxCount = _batches.fold<int>(1, (max, b) {
                  final e = b['batch_enrollments'];
                  int c = 0;
                  if (e is List) {
                    c = e.length;
                  } else if (e is Map)
                    c = (e['count'] as int?) ?? 0;
                  return c > max ? c : max;
                });

                final ratio = maxCount > 0 ? count / maxCount : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio.toDouble(),
                            backgroundColor: AppTheme.outlineVariant,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
