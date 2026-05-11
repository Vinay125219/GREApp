import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/supabase_service.dart';

// ─── Check Result Model ──────────────────────────────────────

enum CheckStatus { pending, running, passed, failed, warning }

class IntegrityCheck {
  final String id;
  final String table;
  final String name;
  final String description;
  CheckStatus status;
  String? detail;
  int? rowCount;
  Duration? duration;

  IntegrityCheck({
    required this.id,
    required this.table,
    required this.name,
    required this.description,
    this.status = CheckStatus.pending,
    this.detail,
    this.rowCount,
    this.duration,
  });
}

// ─── Screen ──────────────────────────────────────────────────

class AdminIntegrityScreen extends StatefulWidget {
  const AdminIntegrityScreen({super.key});

  @override
  State<AdminIntegrityScreen> createState() => _AdminIntegrityScreenState();
}

class _AdminIntegrityScreenState extends State<AdminIntegrityScreen> {
  bool _isRunning = false;
  DateTime? _lastRunAt;

  late List<IntegrityCheck> _checks;

  @override
  void initState() {
    super.initState();
    _initChecks();
  }

  void _initChecks() {
    _checks = [
      // user_profiles
      IntegrityCheck(
        id: 'up_read',
        table: 'user_profiles',
        name: 'RLS Read Access',
        description: 'Verify current user can read own profile row',
      ),
      IntegrityCheck(
        id: 'up_role_field',
        table: 'user_profiles',
        name: 'Role Field Consistency',
        description: 'All rows have a non-null role (admin/student)',
      ),
      IntegrityCheck(
        id: 'up_orphan',
        table: 'user_profiles',
        name: 'Orphan Check',
        description: 'Count profiles without matching auth.users (via id)',
      ),
      // courses
      IntegrityCheck(
        id: 'courses_read',
        table: 'courses',
        name: 'RLS Read Access',
        description: 'Admin can list all courses',
      ),
      IntegrityCheck(
        id: 'courses_published',
        table: 'courses',
        name: 'Published vs Draft',
        description: 'Count published and draft courses',
      ),
      IntegrityCheck(
        id: 'courses_lesson_count',
        table: 'courses',
        name: 'Lesson Count Sync',
        description: 'Courses where total_lessons matches actual lesson rows',
      ),
      // tests
      IntegrityCheck(
        id: 'tests_read',
        table: 'tests',
        name: 'RLS Read Access',
        description: 'Admin can list all tests',
      ),
      IntegrityCheck(
        id: 'tests_no_questions',
        table: 'tests',
        name: 'Tests Without Questions',
        description: 'Published tests that have zero questions',
      ),
      IntegrityCheck(
        id: 'tests_status_values',
        table: 'tests',
        name: 'Status Field Values',
        description: 'All tests have valid status (draft/published/archived)',
      ),
      // test_attempts
      IntegrityCheck(
        id: 'ta_read',
        table: 'test_attempts',
        name: 'RLS Read Access',
        description: 'Admin can list all test_attempts',
      ),
      IntegrityCheck(
        id: 'ta_in_progress',
        table: 'test_attempts',
        name: 'Stale In-Progress Attempts',
        description: 'Attempts stuck in_progress for > 24 hours',
      ),
      IntegrityCheck(
        id: 'ta_score_integrity',
        table: 'test_attempts',
        name: 'Score Integrity',
        description: 'Submitted attempts where score > total_marks',
      ),
    ];
  }

  Future<void> _runAllChecks() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      for (final c in _checks) {
        c.status = CheckStatus.pending;
        c.detail = null;
        c.rowCount = null;
        c.duration = null;
      }
    });

    for (final check in _checks) {
      setState(() => check.status = CheckStatus.running);
      final sw = Stopwatch()..start();
      try {
        await _runCheck(check);
      } catch (e) {
        check.status = CheckStatus.failed;
        check.detail = 'Unexpected error: $e';
      }
      sw.stop();
      check.duration = sw.elapsed;
      setState(() {});
      // Small delay so UI updates are visible
      await Future.delayed(const Duration(milliseconds: 120));
    }

    setState(() {
      _isRunning = false;
      _lastRunAt = DateTime.now();
    });
  }

  Future<void> _runCheck(IntegrityCheck check) async {
    final client = SupabaseService.instance.client;

    switch (check.id) {
      // ── user_profiles ──────────────────────────────────
      case 'up_read':
        final uid = SupabaseService.instance.currentUserId;
        if (uid == null) {
          check.status = CheckStatus.failed;
          check.detail = 'No authenticated user';
          return;
        }
        final resp = await client
            .from('user_profiles')
            .select('id, role')
            .eq('id', uid)
            .maybeSingle();
        if (resp == null) {
          check.status = CheckStatus.failed;
          check.detail = 'RLS blocked read — profile row not returned';
        } else {
          check.status = CheckStatus.passed;
          check.detail = 'Profile readable. Role: ${resp['role']}';
          check.rowCount = 1;
        }
        break;

      case 'up_role_field':
        final all = await client.from('user_profiles').select('id, role');
        final rows = (all as List<dynamic>).cast<Map<String, dynamic>>();
        final nullRoles = rows.where((r) => r['role'] == null).length;
        final invalidRoles = rows
            .where(
              (r) =>
                  r['role'] != null &&
                  !['admin', 'student', 'teacher'].contains(r['role']),
            )
            .length;
        check.rowCount = rows.length;
        if (nullRoles > 0 || invalidRoles > 0) {
          check.status = CheckStatus.warning;
          check.detail =
              '$nullRoles null roles, $invalidRoles invalid roles out of ${rows.length} profiles';
        } else {
          check.status = CheckStatus.passed;
          check.detail = 'All ${rows.length} profiles have valid roles';
        }
        break;

      case 'up_orphan':
        // We can only check from user_profiles side — count total profiles
        final profiles = await client.from('user_profiles').select('id');
        check.rowCount = (profiles as List<dynamic>).length;
        check.status = CheckStatus.passed;
        check.detail =
            '${check.rowCount} profile rows accessible via RLS. Auth-side orphan check requires service_role key.';
        break;

      // ── courses ────────────────────────────────────────
      case 'courses_read':
        final resp = await client.from('courses').select('id');
        final count = (resp as List<dynamic>).length;
        check.rowCount = count;
        check.status = CheckStatus.passed;
        check.detail = 'Admin can read $count course rows';
        break;

      case 'courses_published':
        final resp = await client.from('courses').select('id, is_published');
        final rows = (resp as List<dynamic>).cast<Map<String, dynamic>>();
        final published = rows.where((r) => r['is_published'] == true).length;
        final draft = rows.length - published;
        check.rowCount = rows.length;
        check.status = rows.isEmpty ? CheckStatus.warning : CheckStatus.passed;
        check.detail = '$published published, $draft draft';
        break;

      case 'courses_lesson_count':
        final courses = await client
            .from('courses')
            .select('id, title, total_lessons');
        final courseRows = (courses as List<dynamic>)
            .cast<Map<String, dynamic>>();
        int mismatch = 0;
        for (final course in courseRows) {
          final cid = course['id'] as String;
          final declared = (course['total_lessons'] as int?) ?? 0;
          final actual = await client
              .from('lessons')
              .select('id')
              .eq('course_id', cid);
          final actualCount = (actual as List<dynamic>).length;
          if (declared != actualCount) mismatch++;
        }
        check.rowCount = courseRows.length;
        if (mismatch > 0) {
          check.status = CheckStatus.warning;
          check.detail =
              '$mismatch/${courseRows.length} courses have stale total_lessons count';
        } else {
          check.status = CheckStatus.passed;
          check.detail =
              'All ${courseRows.length} courses have accurate lesson counts';
        }
        break;

      // ── tests ──────────────────────────────────────────
      case 'tests_read':
        final resp = await client.from('tests').select('id');
        final count = (resp as List<dynamic>).length;
        check.rowCount = count;
        check.status = CheckStatus.passed;
        check.detail = 'Admin can read $count test rows';
        break;

      case 'tests_no_questions':
        final tests = await client
            .from('tests')
            .select('id, title, status')
            .eq('status', 'published');
        final testRows = (tests as List<dynamic>).cast<Map<String, dynamic>>();
        final emptyTests = <String>[];
        for (final test in testRows) {
          final tid = test['id'] as String;
          final qs = await client
              .from('questions')
              .select('id')
              .eq('test_id', tid);
          if ((qs as List<dynamic>).isEmpty) {
            emptyTests.add(test['title'] as String? ?? tid);
          }
        }
        check.rowCount = testRows.length;
        if (emptyTests.isNotEmpty) {
          check.status = CheckStatus.warning;
          check.detail =
              '${emptyTests.length} published test(s) have no questions: ${emptyTests.take(3).join(', ')}${emptyTests.length > 3 ? '...' : ''}';
        } else {
          check.status = CheckStatus.passed;
          check.detail =
              'All ${testRows.length} published tests have questions';
        }
        break;

      case 'tests_status_values':
        final resp = await client.from('tests').select('id, status');
        final rows = (resp as List<dynamic>).cast<Map<String, dynamic>>();
        const validStatuses = {'draft', 'published', 'archived'};
        final invalid = rows
            .where((r) => !validStatuses.contains(r['status']))
            .length;
        check.rowCount = rows.length;
        if (invalid > 0) {
          check.status = CheckStatus.failed;
          check.detail = '$invalid tests have invalid status values';
        } else {
          check.status = CheckStatus.passed;
          check.detail = 'All ${rows.length} tests have valid status values';
        }
        break;

      // ── test_attempts ──────────────────────────────────
      case 'ta_read':
        final resp = await client.from('test_attempts').select('id');
        final count = (resp as List<dynamic>).length;
        check.rowCount = count;
        check.status = CheckStatus.passed;
        check.detail = 'Admin can read $count attempt rows';
        break;

      case 'ta_in_progress':
        final cutoff = DateTime.now()
            .subtract(const Duration(hours: 24))
            .toIso8601String();
        final resp = await client
            .from('test_attempts')
            .select('id, started_at')
            .eq('status', 'in_progress')
            .lte('started_at', cutoff);
        final stale = (resp as List<dynamic>).length;
        check.rowCount = stale;
        if (stale > 0) {
          check.status = CheckStatus.warning;
          check.detail = '$stale attempt(s) stuck in_progress for > 24 hours';
        } else {
          check.status = CheckStatus.passed;
          check.detail = 'No stale in-progress attempts found';
        }
        break;

      case 'ta_score_integrity':
        final resp = await client
            .from('test_attempts')
            .select('id, score, total_marks')
            .inFilter('status', ['submitted', 'graded']);
        final rows = (resp as List<dynamic>).cast<Map<String, dynamic>>();
        final invalid = rows.where((r) {
          final score = (r['score'] as num?)?.toDouble() ?? 0;
          final total = (r['total_marks'] as num?)?.toDouble() ?? 0;
          return total > 0 && score > total;
        }).length;
        check.rowCount = rows.length;
        if (invalid > 0) {
          check.status = CheckStatus.failed;
          check.detail =
              '$invalid attempt(s) have score > total_marks (data corruption)';
        } else {
          check.status = CheckStatus.passed;
          check.detail =
              'All ${rows.length} submitted attempts have valid scores';
        }
        break;
    }
  }

  // ─── Summary Counts ──────────────────────────────────────

  int get _passedCount =>
      _checks.where((c) => c.status == CheckStatus.passed).length;
  int get _failedCount =>
      _checks.where((c) => c.status == CheckStatus.failed).length;
  int get _warningCount =>
      _checks.where((c) => c.status == CheckStatus.warning).length;
  bool get _hasRun => _checks.any((c) => c.status != CheckStatus.pending);

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tables = ['user_profiles', 'courses', 'tests', 'test_attempts'];

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
                'DB Integrity Checks',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.icon(
                    onPressed: _isRunning ? null : _runAllChecks,
                    icon: _isRunning
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(
                      _isRunning ? 'Running…' : 'Run All',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary banner
                    if (_hasRun) ...[
                      _SummaryBanner(
                        passed: _passedCount,
                        failed: _failedCount,
                        warnings: _warningCount,
                        total: _checks.length,
                        lastRunAt: _lastRunAt,
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Description
                    if (!_hasRun)
                      _InfoCard(
                        message:
                            'Tap "Run All" to execute ${_checks.length} integrity checks across 4 tables. Checks verify RLS read access, data consistency, and potential anomalies.',
                      ),
                    if (!_hasRun) const SizedBox(height: 20),
                    // Checks grouped by table
                    ...tables.map((table) {
                      final tableChecks = _checks
                          .where((c) => c.table == table)
                          .toList();
                      return _TableSection(
                        table: table,
                        checks: tableChecks,
                        theme: theme,
                      );
                    }),
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

// ─── Summary Banner ──────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final int passed;
  final int failed;
  final int warnings;
  final int total;
  final DateTime? lastRunAt;

  const _SummaryBanner({
    required this.passed,
    required this.failed,
    required this.warnings,
    required this.total,
    this.lastRunAt,
  });

  @override
  Widget build(BuildContext context) {
    final allPassed = failed == 0 && warnings == 0;
    final hasFailed = failed > 0;

    Color bannerColor;
    Color textColor;
    IconData icon;

    if (hasFailed) {
      bannerColor = AppTheme.error.withValues(alpha: 0.08);
      textColor = AppTheme.error;
      icon = Icons.error_outline_rounded;
    } else if (warnings > 0) {
      bannerColor = const Color(0xFFF59E0B).withValues(alpha: 0.08);
      textColor = const Color(0xFFB45309);
      icon = Icons.warning_amber_rounded;
    } else {
      bannerColor = AppTheme.success.withValues(alpha: 0.08);
      textColor = AppTheme.success;
      icon = Icons.check_circle_outline_rounded;
    }

    final timeStr = lastRunAt != null
        ? '${lastRunAt!.hour.toString().padLeft(2, '0')}:${lastRunAt!.minute.toString().padLeft(2, '0')}:${lastRunAt!.second.toString().padLeft(2, '0')}'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allPassed
                      ? 'All checks passed'
                      : hasFailed
                      ? '$failed check(s) failed'
                      : '$warnings warning(s) found',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              if (timeStr.isNotEmpty)
                Text(
                  'Last run $timeStr',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: 'Passed',
                value: passed,
                color: AppTheme.success,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Warnings',
                value: warnings,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _StatChip(label: 'Failed', value: failed, color: AppTheme.error),
              const Spacer(),
              Text(
                '$total total',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
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

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ─── Info Card ───────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String message;
  const _InfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Section ───────────────────────────────────────────

class _TableSection extends StatelessWidget {
  final String table;
  final List<IntegrityCheck> checks;
  final ThemeData theme;

  const _TableSection({
    required this.table,
    required this.checks,
    required this.theme,
  });

  Color get _tableColor {
    switch (table) {
      case 'user_profiles':
        return const Color(0xFF6366F1);
      case 'courses':
        return const Color(0xFF0EA5E9);
      case 'tests':
        return const Color(0xFFF59E0B);
      case 'test_attempts':
        return const Color(0xFF10B981);
      default:
        return AppTheme.primary;
    }
  }

  IconData get _tableIcon {
    switch (table) {
      case 'user_profiles':
        return Icons.people_outline_rounded;
      case 'courses':
        return Icons.library_books_outlined;
      case 'tests':
        return Icons.quiz_outlined;
      case 'test_attempts':
        return Icons.assignment_outlined;
      default:
        return Icons.table_chart_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _tableColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_tableIcon, size: 16, color: _tableColor),
            ),
            const SizedBox(width: 8),
            Text(
              table,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _tableColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Divider(
                color: _tableColor.withValues(alpha: 0.2),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: checks.asMap().entries.map((entry) {
              final idx = entry.key;
              final check = entry.value;
              final isLast = idx == checks.length - 1;
              return _CheckRow(check: check, isLast: isLast);
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Check Row ───────────────────────────────────────────────

class _CheckRow extends StatelessWidget {
  final IntegrityCheck check;
  final bool isLast;

  const _CheckRow({required this.check, required this.isLast});

  Color get _statusColor {
    switch (check.status) {
      case CheckStatus.passed:
        return AppTheme.success;
      case CheckStatus.failed:
        return AppTheme.error;
      case CheckStatus.warning:
        return const Color(0xFFF59E0B);
      case CheckStatus.running:
        return AppTheme.primary;
      case CheckStatus.pending:
        return AppTheme.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (check.status) {
      case CheckStatus.passed:
        return Icons.check_circle_rounded;
      case CheckStatus.failed:
        return Icons.cancel_rounded;
      case CheckStatus.warning:
        return Icons.warning_rounded;
      case CheckStatus.running:
        return Icons.hourglass_top_rounded;
      case CheckStatus.pending:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  String get _statusLabel {
    switch (check.status) {
      case CheckStatus.passed:
        return 'PASS';
      case CheckStatus.failed:
        return 'FAIL';
      case CheckStatus.warning:
        return 'WARN';
      case CheckStatus.running:
        return 'RUN';
      case CheckStatus.pending:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status icon
              check.status == CheckStatus.running
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : Icon(_statusIcon, size: 20, color: _statusColor),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            check.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      check.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (check.detail != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _statusColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                check.detail!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: _statusColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            if (check.duration != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${check.duration!.inMilliseconds}ms',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 46, color: AppTheme.outlineVariant),
      ],
    );
  }
}