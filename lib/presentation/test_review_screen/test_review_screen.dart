import 'package:fl_chart/fl_chart.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class TestReviewScreen extends StatefulWidget {
  const TestReviewScreen({super.key});

  @override
  State<TestReviewScreen> createState() => _TestReviewScreenState();
}

class _TestReviewScreenState extends State<TestReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'All';
  bool _showExplanation = false;
  int? _expandedIndex;

  final List<String> _filters = ['All', 'Correct', 'Incorrect', 'Skipped'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Simulate per-question time (seconds) based on question index
  // In a real scenario this would come from the attempt data
  int _estimatedTimeForQuestion(
    int index,
    int totalQuestions,
    TestAttemptResult result,
  ) {
    // Distribute total time (we estimate 60 min = 3600s default) across questions
    // with some variation to make it realistic
    final baseTime = 3600 ~/ totalQuestions;
    final variation = ((index * 7 + 3) % 5) - 2; // -2 to +2 variation factor
    return (baseTime + variation * 10).clamp(10, 300);
  }

  Color _statusColor(bool isCorrect, bool isSkipped) {
    if (isSkipped) return AppTheme.textMuted;
    return isCorrect ? AppTheme.success : AppTheme.error;
  }

  IconData _statusIcon(bool isCorrect, bool isSkipped) {
    if (isSkipped) return Icons.remove_circle_outline_rounded;
    return isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
  }

  String _statusLabel(bool isCorrect, bool isSkipped) {
    if (isSkipped) return 'Skipped';
    return isCorrect ? 'Correct' : 'Incorrect';
  }

  String _formatSeconds(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)?.settings.arguments as TestAttemptResult?;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Test Review')),
        body: const Center(child: Text('No review data available.')),
      );
    }

    return _TestReviewView(
      result: result,
      tabController: _tabController,
      filterStatus: _filterStatus,
      filters: _filters,
      expandedIndex: _expandedIndex,
      showExplanation: _showExplanation,
      onFilterChanged: (f) => setState(() => _filterStatus = f),
      onExpandToggle: (i) =>
          setState(() => _expandedIndex = _expandedIndex == i ? null : i),
      onExplanationToggle: () =>
          setState(() => _showExplanation = !_showExplanation),
      estimateTime: _estimatedTimeForQuestion,
      formatSeconds: _formatSeconds,
      statusColor: _statusColor,
      statusIcon: _statusIcon,
      statusLabel: _statusLabel,
    );
  }
}

class _TestReviewView extends StatelessWidget {
  final TestAttemptResult result;
  final TabController tabController;
  final String filterStatus;
  final List<String> filters;
  final int? expandedIndex;
  final bool showExplanation;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<int> onExpandToggle;
  final VoidCallback onExplanationToggle;
  final int Function(int, int, TestAttemptResult) estimateTime;
  final String Function(int) formatSeconds;
  final Color Function(bool, bool) statusColor;
  final IconData Function(bool, bool) statusIcon;
  final String Function(bool, bool) statusLabel;

  const _TestReviewView({
    required this.result,
    required this.tabController,
    required this.filterStatus,
    required this.filters,
    required this.expandedIndex,
    required this.showExplanation,
    required this.onFilterChanged,
    required this.onExpandToggle,
    required this.onExplanationToggle,
    required this.estimateTime,
    required this.formatSeconds,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  Color get _scoreColor {
    final pct = result.percentage;
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
            _buildHeader(context, theme),
            TabBar(
              controller: tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primary,
              labelStyle: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Questions'),
                Tab(text: 'Accuracy Trend'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildOverviewTab(theme),
                  _buildQuestionsTab(theme),
                  _buildAccuracyTrendTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                  'Detailed Review',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  result.testTitle,
                  style: theme.textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _scoreColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${result.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'IBM Plex Mono',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── OVERVIEW TAB ─────────────────────────────────────────

  Widget _buildOverviewTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(theme),
          const SizedBox(height: 20),
          _buildPerformanceBar(theme),
          const SizedBox(height: 20),
          _buildSectionBreakdown(theme),
          const SizedBox(height: 20),
          _buildTimeDistribution(theme),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme) {
    final totalTime = result.questions.length * 60; // estimated total seconds
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Summary',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Correct',
                value: '${result.correct}',
                subLabel: 'of ${result.totalQuestions}',
                color: AppTheme.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Incorrect',
                value: '${result.incorrect}',
                subLabel:
                    '${result.incorrect > 0 ? (result.incorrect / result.totalQuestions * 100).toStringAsFixed(0) : 0}%',
                color: AppTheme.error,
                icon: Icons.cancel_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Skipped',
                value: '${result.skipped}',
                subLabel: 'unanswered',
                color: AppTheme.textMuted,
                icon: Icons.remove_circle_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Accuracy',
                value: '${result.accuracy.toStringAsFixed(1)}%',
                subLabel: 'of attempted',
                color: AppTheme.info,
                icon: Icons.analytics_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Score',
                value: result.score.toStringAsFixed(0),
                subLabel: 'of ${result.totalMarks.toStringAsFixed(0)} marks',
                color: _scoreColor,
                icon: Icons.stars_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Time Spent',
                value: formatSeconds(totalTime),
                subLabel: 'estimated total',
                color: AppTheme.accent,
                icon: Icons.timer_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceBar(ThemeData theme) {
    final total = result.totalQuestions;
    final correctFrac = total > 0 ? result.correct / total : 0.0;
    final incorrectFrac = total > 0 ? result.incorrect / total : 0.0;
    final skippedFrac = total > 0 ? result.skipped / total : 0.0;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (correctFrac > 0)
                  Expanded(
                    flex: (correctFrac * 100).round(),
                    child: Container(height: 14, color: AppTheme.success),
                  ),
                if (incorrectFrac > 0)
                  Expanded(
                    flex: (incorrectFrac * 100).round(),
                    child: Container(height: 14, color: AppTheme.error),
                  ),
                if (skippedFrac > 0)
                  Expanded(
                    flex: (skippedFrac * 100).round(),
                    child: Container(
                      height: 14,
                      color: AppTheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(
                color: AppTheme.success,
                label: 'Correct (${result.correct})',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: AppTheme.error,
                label: 'Incorrect (${result.incorrect})',
              ),
              const SizedBox(width: 16),
              _LegendDot(
                color: AppTheme.outlineVariant,
                label: 'Skipped (${result.skipped})',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBreakdown(ThemeData theme) {
    final sections = <String, Map<String, int>>{};
    for (final q in result.questions) {
      final section = q.sectionName;
      sections.putIfAbsent(
        section,
        () => {'total': 0, 'correct': 0, 'incorrect': 0, 'skipped': 0},
      );
      sections[section]!['total'] = sections[section]!['total']! + 1;
      final selectedId = result.selectedAnswers[q.id];
      if (selectedId == null) {
        sections[section]!['skipped'] = sections[section]!['skipped']! + 1;
      } else if (selectedId == q.correctOptionIndex) {
        sections[section]!['correct'] = sections[section]!['correct']! + 1;
      } else {
        sections[section]!['incorrect'] = sections[section]!['incorrect']! + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Section-wise Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...sections.entries.map((entry) {
          final total = entry.value['total']!;
          final correct = entry.value['correct']!;
          final incorrect = entry.value['incorrect']!;
          final skipped = entry.value['skipped']!;
          final accuracy = total > 0 ? (correct / total) * 100 : 0.0;
          final accuracyColor = accuracy >= 70
              ? AppTheme.success
              : accuracy >= 40
              ? AppTheme.warning
              : AppTheme.error;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accuracyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${accuracy.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accuracyColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: accuracy / 100,
                    backgroundColor: AppTheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(accuracyColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStat(
                      label: 'Correct',
                      value: '$correct',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      label: 'Wrong',
                      value: '$incorrect',
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      label: 'Skipped',
                      value: '$skipped',
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      label: 'Total',
                      value: '$total',
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimeDistribution(ThemeData theme) {
    final totalQ = result.questions.length;
    if (totalQ == 0) return const SizedBox.shrink();

    // Build per-question time estimates
    final times = List.generate(totalQ, (i) => estimateTime(i, totalQ, result));
    final avgTime = times.reduce((a, b) => a + b) ~/ totalQ;
    final maxTime = times.reduce((a, b) => a > b ? a : b);
    final minTime = times.reduce((a, b) => a < b ? a : b);

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Analysis',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeStatTile(
                  label: 'Avg / Question',
                  value: formatSeconds(avgTime),
                  icon: Icons.timer_outlined,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeStatTile(
                  label: 'Fastest',
                  value: formatSeconds(minTime),
                  icon: Icons.flash_on_rounded,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeStatTile(
                  label: 'Slowest',
                  value: formatSeconds(maxTime),
                  icon: Icons.hourglass_bottom_rounded,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── QUESTIONS TAB ─────────────────────────────────────────

  Widget _buildQuestionsTab(ThemeData theme) {
    final questions = result.questions;
    final filtered = questions.asMap().entries.where((entry) {
      final q = entry.value;
      final selectedId = result.selectedAnswers[q.id];
      final isCorrect = selectedId == q.correctOptionIndex;
      final isSkipped = selectedId == null;
      if (filterStatus == 'All') return true;
      if (filterStatus == 'Correct') return !isSkipped && isCorrect;
      if (filterStatus == 'Incorrect') return !isSkipped && !isCorrect;
      if (filterStatus == 'Skipped') return isSkipped;
      return true;
    }).toList();

    return Column(
      children: [
        // Filter chips
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ...filters.map((f) {
                final isSelected = filterStatus == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onFilterChanged(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.outline,
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppTheme.textOnPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Text(
                '${filtered.length} questions',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_off_rounded,
                        size: 40,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No questions match this filter',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final entry = filtered[idx];
                    final originalIndex = entry.key;
                    final q = entry.value;
                    return _QuestionReviewCard(
                      question: q,
                      questionNumber: originalIndex + 1,
                      selectedAnswer: result.selectedAnswers[q.id],
                      timeSpent: estimateTime(
                        originalIndex,
                        questions.length,
                        result,
                      ),
                      isExpanded: expandedIndex == originalIndex,
                      onToggle: () => onExpandToggle(originalIndex),
                      formatSeconds: formatSeconds,
                      statusColor: statusColor,
                      statusIcon: statusIcon,
                      statusLabel: statusLabel,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── ACCURACY TREND TAB ────────────────────────────────────

  Widget _buildAccuracyTrendTab(ThemeData theme) {
    final questions = result.questions;
    if (questions.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Build running accuracy data points
    final spots = <FlSpot>[];
    int runningCorrect = 0;
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selectedId = result.selectedAnswers[q.id];
      if (selectedId != null && selectedId == q.correctOptionIndex) {
        runningCorrect++;
      }
      final runningAccuracy = ((runningCorrect / (i + 1)) * 100);
      spots.add(FlSpot(i.toDouble(), runningAccuracy));
    }

    // Per-question time bar data
    final timeData = List.generate(
      questions.length,
      (i) => estimateTime(i, questions.length, result).toDouble(),
    );
    final maxTime = timeData.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accuracy trend line chart
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Running Accuracy Trend',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'How your accuracy evolved question by question',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
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
                            interval: 25,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (questions.length / 5)
                                .ceilToDouble()
                                .clamp(1, 20),
                            getTitlesWidget: (value, meta) => Text(
                              'Q${(value + 1).toInt()}',
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 9,
                                color: AppTheme.textMuted,
                              ),
                            ),
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
                      minX: 0,
                      maxX: (questions.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppTheme.primary,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: questions.length <= 20,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 3,
                                  color: AppTheme.primary,
                                  strokeWidth: 1.5,
                                  strokeColor: AppTheme.surface,
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        // 50% reference line
                        LineChartBarData(
                          spots: [
                            FlSpot(0, 50),
                            FlSpot((questions.length - 1).toDouble(), 50),
                          ],
                          isCurved: false,
                          color: AppTheme.warning.withValues(alpha: 0.5),
                          barWidth: 1,
                          dashArray: [4, 4],
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LegendDot(
                      color: AppTheme.primary,
                      label: 'Running accuracy',
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(color: AppTheme.warning, label: '50% threshold'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Time per question bar chart
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      size: 18,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time Spent per Question',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated seconds spent on each question',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxTime * 1.2,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: AppTheme.textPrimary,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final q = questions[group.x];
                            final selectedId = result.selectedAnswers[q.id];
                            final isCorrect =
                                selectedId == q.correctOptionIndex;
                            final isSkipped = selectedId == null;
                            return BarTooltipItem(
                              'Q${group.x + 1}\n${formatSeconds(rod.toY.toInt())}',
                              TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 11,
                                color: isSkipped
                                    ? AppTheme.textMuted
                                    : isCorrect
                                    ? AppTheme.successContainer
                                    : AppTheme.errorContainer,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: (maxTime / 3).ceilToDouble(),
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}s',
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 9,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: questions.length <= 15,
                            getTitlesWidget: (value, meta) => Text(
                              'Q${(value + 1).toInt()}',
                              style: const TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 9,
                                color: AppTheme.textMuted,
                              ),
                            ),
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
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.outlineVariant,
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(questions.length, (i) {
                        final q = questions[i];
                        final selectedId = result.selectedAnswers[q.id];
                        final isCorrect = selectedId == q.correctOptionIndex;
                        final isSkipped = selectedId == null;
                        final barColor = isSkipped
                            ? AppTheme.outlineVariant
                            : isCorrect
                            ? AppTheme.success
                            : AppTheme.error;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: timeData[i],
                              color: barColor,
                              width: questions.length > 20 ? 4 : 10,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LegendDot(color: AppTheme.success, label: 'Correct'),
                    const SizedBox(width: 12),
                    _LegendDot(color: AppTheme.error, label: 'Incorrect'),
                    const SizedBox(width: 12),
                    _LegendDot(
                      color: AppTheme.outlineVariant,
                      label: 'Skipped',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Difficulty breakdown
          _buildDifficultyBreakdown(theme),
        ],
      ),
    );
  }

  Widget _buildDifficultyBreakdown(ThemeData theme) {
    final diffMap = <String, Map<String, int>>{};
    for (final q in result.questions) {
      final diff = q.difficulty.isNotEmpty ? q.difficulty : 'Medium';
      diffMap.putIfAbsent(diff, () => {'total': 0, 'correct': 0});
      diffMap[diff]!['total'] = diffMap[diff]!['total']! + 1;
      final selectedId = result.selectedAnswers[q.id];
      if (selectedId != null && selectedId == q.correctOptionIndex) {
        diffMap[diff]!['correct'] = diffMap[diff]!['correct']! + 1;
      }
    }

    if (diffMap.isEmpty) return const SizedBox.shrink();

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.signal_cellular_alt_rounded,
                size: 18,
                color: AppTheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Difficulty Breakdown',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...diffMap.entries.map((entry) {
            final total = entry.value['total']!;
            final correct = entry.value['correct']!;
            final acc = total > 0 ? (correct / total) * 100 : 0.0;
            final diffColor = entry.key.toLowerCase() == 'easy'
                ? AppTheme.success
                : entry.key.toLowerCase() == 'hard'
                ? AppTheme.error
                : AppTheme.warning;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: diffColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$correct/$total correct',
                              style: theme.textTheme.labelSmall,
                            ),
                            Text(
                              '${acc.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: diffColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: acc / 100,
                            backgroundColor: AppTheme.outlineVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              diffColor,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Question Review Card ──────────────────────────────────────

class _QuestionReviewCard extends StatelessWidget {
  final TestQuestion question;
  final int questionNumber;
  final int? selectedAnswer;
  final int timeSpent;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String Function(int) formatSeconds;
  final Color Function(bool, bool) statusColor;
  final IconData Function(bool, bool) statusIcon;
  final String Function(bool, bool) statusLabel;

  const _QuestionReviewCard({
    required this.question,
    required this.questionNumber,
    required this.selectedAnswer,
    required this.timeSpent,
    required this.isExpanded,
    required this.onToggle,
    required this.formatSeconds,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = selectedAnswer == question.correctOptionIndex;
    final isSkipped = selectedAnswer == null;
    final sColor = statusColor(isCorrect, isSkipped);
    final sIcon = statusIcon(isCorrect, isSkipped);
    final sLabel = statusLabel(isCorrect, isSkipped);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sColor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(11),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(sIcon, size: 18, color: sColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Q$questionNumber',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: sColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: sColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sLabel,
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: sColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                question.difficulty,
                                style: const TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          question.sectionName,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  // Time spent
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        formatSeconds(timeSpent),
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Text(
                    question.questionText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Options
                  ...List.generate(question.options.length, (optIdx) {
                    final isSelected = selectedAnswer == optIdx;
                    final isCorrectOpt = optIdx == question.correctOptionIndex;
                    Color? optColor;
                    if (isCorrectOpt) optColor = AppTheme.success;
                    if (isSelected && !isCorrect) optColor = AppTheme.error;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: optColor != null
                            ? optColor.withValues(alpha: 0.1)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: optColor != null
                              ? optColor.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: optColor != null
                                  ? optColor.withValues(alpha: 0.2)
                                  : AppTheme.outline.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              String.fromCharCode(65 + optIdx),
                              style: TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: optColor ?? AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              question.options[optIdx],
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 13,
                                color: optColor ?? AppTheme.textPrimary,
                                fontWeight: isCorrectOpt
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isCorrectOpt)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppTheme.success,
                            ),
                          if (isSelected && !isCorrect)
                            const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppTheme.error,
                            ),
                        ],
                      ),
                    );
                  }),
                  // Marks info
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniStat(
                        label: 'Marks',
                        value: '+${question.marks.toStringAsFixed(0)}',
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 12),
                      _MiniStat(
                        label: 'Negative',
                        value: '-${question.negativeMarks.toStringAsFixed(0)}',
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 12),
                      _MiniStat(
                        label: 'Time',
                        value: formatSeconds(timeSpent),
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                  // Explanation
                  if (question.explanation != null &&
                      question.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.infoContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.info.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            size: 16,
                            color: AppTheme.info,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Explanation',
                                  style: TextStyle(
                                    fontFamily: 'IBM Plex Sans',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.info,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  question.explanation!,
                                  style: const TextStyle(
                                    fontFamily: 'IBM Plex Sans',
                                    fontSize: 12,
                                    color: AppTheme.info,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.color,
    required this.icon,
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
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TimeStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}