import 'package:fl_chart/fl_chart.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _testHistory = [];
  List<Map<String, dynamic>> _subjectPerformance = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final history = await _fetchTestHistory();
      final subjectPerf = await _fetchSubjectPerformance();
      if (mounted) {
        setState(() {
          _testHistory = history;
          _subjectPerformance = subjectPerf;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTestHistory() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return [];
    final resp = await SupabaseService.instance.client
        .from('test_attempts')
        .select('id, score, total_marks, submitted_at, tests(title)')
        .eq('student_id', uid)
        .inFilter('status', ['submitted', 'graded'])
        .order('submitted_at', ascending: true);
    return (resp as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> _fetchSubjectPerformance() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return [];
    final attemptsResp = await SupabaseService.instance.client
        .from('test_attempts')
        .select('id')
        .eq('student_id', uid)
        .inFilter('status', ['submitted', 'graded']);
    final attemptIds = (attemptsResp as List<dynamic>)
        .map((e) => e['id'] as String)
        .toList();
    if (attemptIds.isEmpty) return [];
    final answersResp = await SupabaseService.instance.client
        .from('questions')
        .select('subject, id');
    final questionsResp = await SupabaseService.instance.client
        .from('test_attempts')
        .select('answers_json')
        .eq('student_id', uid)
        .inFilter('status', ['submitted', 'graded']);
    // Aggregate subject performance from questions
    final Map<String, Map<String, int>> subjectMap = {};
    for (final attempt in (questionsResp as List<dynamic>)) {
      final answers = attempt['answers_json'] as Map<String, dynamic>? ?? {};
      for (final qRaw in (answersResp as List<dynamic>)) {
        final q = qRaw as Map<String, dynamic>;
        final qId = q['id'] as String? ?? '';
        if (!answers.containsKey(qId)) continue;
        final subject = q['subject'] as String? ?? 'General';
        subjectMap.putIfAbsent(subject, () => {'correct': 0, 'total': 0});
        subjectMap[subject]!['total'] = subjectMap[subject]!['total']! + 1;
      }
    }
    // Fetch correct answers
    final allAttemptAnswers = await SupabaseService.instance.client
        .from('test_attempts')
        .select('answers_json, tests(questions(id, subject, correct_option))')
        .eq('student_id', uid)
        .inFilter('status', ['submitted', 'graded']);
    final Map<String, Map<String, int>> subjectStats = {};
    for (final attempt in (allAttemptAnswers as List<dynamic>)) {
      final answers = attempt['answers_json'] as Map<String, dynamic>? ?? {};
      final tests = attempt['tests'] as Map<String, dynamic>?;
      final questions = tests?['questions'] as List<dynamic>? ?? [];
      for (final qRaw in questions) {
        final q = qRaw as Map<String, dynamic>;
        final qId = q['id'] as String? ?? '';
        final subject = q['subject'] as String? ?? 'General';
        final correctOption = q['correct_option'] as int?;
        subjectStats.putIfAbsent(subject, () => {'correct': 0, 'total': 0});
        if (answers.containsKey(qId)) {
          subjectStats[subject]!['total'] =
              subjectStats[subject]!['total']! + 1;
          final selected = answers[qId];
          if (selected != null && selected == correctOption) {
            subjectStats[subject]!['correct'] =
                subjectStats[subject]!['correct']! + 1;
          }
        }
      }
    }
    return subjectStats.entries.map((e) {
      final correct = e.value['correct'] ?? 0;
      final total = e.value['total'] ?? 0;
      final accuracy = total > 0 ? (correct / total) * 100.0 : 0.0;
      return {
        'subject': e.key,
        'correct': correct,
        'total': total,
        'accuracy': accuracy,
      };
    }).toList();
  }

  double _getPercentage(Map<String, dynamic> attempt) {
    final score = (attempt['score'] as num?)?.toDouble() ?? 0;
    final total = (attempt['total_marks'] as num?)?.toDouble() ?? 0;
    return total > 0 ? (score / total) * 100 : 0;
  }

  double get _avgScore {
    if (_testHistory.isEmpty) return 0;
    final sum = _testHistory.fold<double>(0, (s, a) => s + _getPercentage(a));
    return sum / _testHistory.length;
  }

  double get _bestScore {
    if (_testHistory.isEmpty) return 0;
    return _testHistory.fold<double>(0, (best, a) {
      final pct = _getPercentage(a);
      return pct > best ? pct : best;
    });
  }

  Color _scoreColor(double pct) {
    if (pct >= 75) return AppTheme.success;
    if (pct >= 50) return AppTheme.warning;
    return AppTheme.error;
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
                        Text(
                          'My Performance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: _loadData,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Score Trend'),
                      Tab(text: 'Subject-wise'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _error != null
                  ? Center(
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
                            'Failed to load analytics',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildScoreTrendTab(theme),
                        _buildSubjectTab(theme),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTrendTab(ThemeData theme) {
    if (_testHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: AppTheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No test attempts yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete tests to see your score trend',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.adaptivePagePadding(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary KPI row
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Tests Taken',
                    value: '${_testHistory.length}',
                    icon: Icons.assignment_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    label: 'Avg Score',
                    value: '${_avgScore.toStringAsFixed(1)}%',
                    icon: Icons.trending_up_rounded,
                    color: _scoreColor(_avgScore),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    label: 'Best Score',
                    value: '${_bestScore.toStringAsFixed(1)}%',
                    icon: Icons.emoji_events_rounded,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Line chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score Trend',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your performance over time',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppTheme.outlineVariant,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: 25,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= _testHistory.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'T${idx + 1}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _testHistory.asMap().entries.map((e) {
                              return FlSpot(
                                e.key.toDouble(),
                                _getPercentage(e.value),
                              );
                            }).toList(),
                            isCurved: true,
                            color: AppTheme.primary,
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 4,
                                    color: AppTheme.primary,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primary.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Test history list
            Text(
              'Test History',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._testHistory.reversed.map((attempt) {
              final pct = _getPercentage(attempt);
              final testTitle =
                  (attempt['tests'] as Map<String, dynamic>?)?['title']
                      as String? ??
                  'Test';
              final submittedAt = attempt['submitted_at'] != null
                  ? DateTime.tryParse(attempt['submitted_at'] as String)
                  : null;
              final score = (attempt['score'] as num?)?.toDouble() ?? 0;
              final total = (attempt['total_marks'] as num?)?.toDouble() ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _scoreColor(pct).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _scoreColor(pct),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testTitle,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${score.toStringAsFixed(1)} / ${total.toStringAsFixed(0)} marks',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    if (submittedAt != null)
                      Text(
                        '${submittedAt.day}/${submittedAt.month}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectTab(ThemeData theme) {
    if (_subjectPerformance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 64,
              color: AppTheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No subject data yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete tests with subject-tagged questions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      AppTheme.warning,
      AppTheme.error,
      AppTheme.info,
    ];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: context.adaptivePagePadding(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pie chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject Distribution',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _subjectPerformance.asMap().entries.map((e) {
                          final color = colors[e.key % colors.length];
                          final total = (e.value['total'] as int?) ?? 1;
                          return PieChartSectionData(
                            color: color,
                            value: total.toDouble(),
                            title: '${e.value['subject']}',
                            radius: 70,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Bar chart for accuracy
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accuracy by Subject',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Correct answers percentage per subject',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barGroups: _subjectPerformance.asMap().entries.map((e) {
                          final accuracy =
                              (e.value['accuracy'] as num?)?.toDouble() ?? 0;
                          final color = colors[e.key % colors.length];
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: accuracy,
                                color: color,
                                width: 20,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppTheme.outlineVariant,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: 25,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 ||
                                    idx >= _subjectPerformance.length) {
                                  return const SizedBox.shrink();
                                }
                                final subject =
                                    _subjectPerformance[idx]['subject']
                                        as String? ??
                                    '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    subject.length > 6
                                        ? subject.substring(0, 6)
                                        : subject,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Subject breakdown list
            Text(
              'Subject Breakdown',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ..._subjectPerformance.asMap().entries.map((e) {
              final subject = e.value['subject'] as String? ?? 'General';
              final correct = e.value['correct'] as int? ?? 0;
              final total = e.value['total'] as int? ?? 0;
              final accuracy = (e.value['accuracy'] as num?)?.toDouble() ?? 0;
              final color = colors[e.key % colors.length];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subject,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${accuracy.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _scoreColor(accuracy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy / 100,
                        backgroundColor: AppTheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$correct correct out of $total questions',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
