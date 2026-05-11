import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class TestResultScreen extends StatelessWidget {
  const TestResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)?.settings.arguments as TestAttemptResult?;

    if (result == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Test Result')),
        body: const Center(child: Text('No result data available.')),
      );
    }

    return _TestResultView(result: result);
  }
}

class _TestResultView extends StatefulWidget {
  final TestAttemptResult result;
  const _TestResultView({required this.result});

  @override
  State<_TestResultView> createState() => _TestResultViewState();
}

class _TestResultViewState extends State<_TestResultView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _showAnswers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    final pct = widget.result.percentage;
    if (pct >= 75) return AppTheme.success;
    if (pct >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  String get _grade {
    final pct = widget.result.percentage;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    return 'F';
  }

  String get _remark {
    final pct = widget.result.percentage;
    if (pct >= 90) return 'Outstanding!';
    if (pct >= 75) return 'Excellent Work!';
    if (pct >= 60) return 'Good Job!';
    if (pct >= 50) return 'Keep Practicing';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
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
                Tab(text: 'Scorecard'),
                Tab(text: 'Answer Review'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildScorecard(theme), _buildAnswerReview(theme)],
              ),
            ),
            _buildBottomActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.studentDashboardScreen,
                  (r) => false,
                ),
              ),
              Expanded(
                child: Text(
                  widget.result.testTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _scoreColor, width: 4),
                  color: _scoreColor.withValues(alpha: 0.08),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _grade,
                      style: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
                      ),
                    ),
                    Text(
                      '${widget.result.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _remark,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: ${widget.result.score.toStringAsFixed(0)} / ${widget.result.totalMarks.toStringAsFixed(0)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Submitted ${_formatTime(widget.result.submittedAt)}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorecard(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                label: 'Correct',
                value: '${widget.result.correct}',
                color: AppTheme.success,
                icon: Icons.check_circle_rounded,
              ),
              _StatCard(
                label: 'Incorrect',
                value: '${widget.result.incorrect}',
                color: AppTheme.error,
                icon: Icons.cancel_rounded,
              ),
              _StatCard(
                label: 'Skipped',
                value: '${widget.result.skipped}',
                color: AppTheme.textMuted,
                icon: Icons.remove_circle_rounded,
              ),
              _StatCard(
                label: 'Accuracy',
                value: '${widget.result.accuracy.toStringAsFixed(1)}%',
                color: AppTheme.info,
                icon: Icons.analytics_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Section-wise breakdown
          Text(
            'Section Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildSectionBreakdown(theme),
          const SizedBox(height: 20),
          // Score progress bar
          Text(
            'Score Progress',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Score', style: theme.textTheme.bodySmall),
                    Text(
                      '${widget.result.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.result.percentage / 100,
                    backgroundColor: AppTheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionBreakdown(ThemeData theme) {
    final sections = <String, Map<String, int>>{};
    for (int i = 0; i < widget.result.questions.length; i++) {
      final q = widget.result.questions[i];
      final section = q.sectionName;
      sections.putIfAbsent(
        section,
        () => {'total': 0, 'correct': 0, 'incorrect': 0},
      );
      sections[section]!['total'] = sections[section]!['total']! + 1;
      final selectedId = widget.result.selectedAnswers[q.id];
      if (selectedId != null) {
        if (selectedId == q.correctOptionIndex) {
          sections[section]!['correct'] = sections[section]!['correct']! + 1;
        } else {
          sections[section]!['incorrect'] =
              sections[section]!['incorrect']! + 1;
        }
      }
    }

    return sections.entries.map((entry) {
      final total = entry.value['total']!;
      final correct = entry.value['correct']!;
      final accuracy = total > 0 ? (correct / total) * 100 : 0.0;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$correct/$total',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accuracy >= 50 ? AppTheme.success : AppTheme.error,
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  accuracy >= 50 ? AppTheme.success : AppTheme.error,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildAnswerReview(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.result.questions.length,
      itemBuilder: (context, index) {
        final q = widget.result.questions[index];
        final selectedId = widget.result.selectedAnswers[q.id];
        final isCorrect = selectedId == q.correctOptionIndex;
        final isSkipped = selectedId == null;

        Color statusColor = isSkipped
            ? AppTheme.textMuted
            : (isCorrect ? AppTheme.success : AppTheme.error);
        IconData statusIcon = isSkipped
            ? Icons.remove_circle_outline_rounded
            : (isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      'Q${index + 1} · ${q.sectionName}',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+${q.marks.toStringAsFixed(0)} marks',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 11,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.questionText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(q.options.length, (optIdx) {
                      final isSelected = selectedId == optIdx;
                      final isCorrectOpt = optIdx == q.correctOptionIndex;
                      Color? optColor;
                      if (isCorrectOpt) optColor = AppTheme.success;
                      if (isSelected && !isCorrect) optColor = AppTheme.error;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
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
                            Text(
                              String.fromCharCode(65 + optIdx),
                              style: TextStyle(
                                fontFamily: 'IBM Plex Mono',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: optColor ?? AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.options[optIdx],
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
                              Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppTheme.success,
                              ),
                            if (isSelected && !isCorrect)
                              Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.error,
                              ),
                          ],
                        ),
                      );
                    }),
                    if (q.explanation != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.infoContainer,
                          borderRadius: BorderRadius.circular(8),
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
                              child: Text(
                                q.explanation!,
                                style: const TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 12,
                                  color: AppTheme.info,
                                ),
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
      },
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.studentDashboardScreen,
                    (r) => false,
                  ),
                  icon: const Icon(Icons.dashboard_rounded, size: 18),
                  label: const Text('Dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.testEngineScreen,
                    (r) => r.settings.name == AppRoutes.studentDashboardScreen,
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Retake Test'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.testReviewScreen,
                arguments: widget.result,
              ),
              icon: const Icon(Icons.manage_search_rounded, size: 18),
              label: const Text('Detailed Review'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
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
                  fontSize: 12,
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
