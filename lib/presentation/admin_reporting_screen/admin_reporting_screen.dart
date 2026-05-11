import 'dart:convert';
import 'dart:html' as html show AnchorElement, Blob, Url;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

// ignore: avoid_web_libraries_in_flutter

enum _ReportTab { testResults, studentProgress, batchPerformance }

class AdminReportingScreen extends StatefulWidget {
  const AdminReportingScreen({super.key});

  @override
  State<AdminReportingScreen> createState() => _AdminReportingScreenState();
}

class _AdminReportingScreenState extends State<AdminReportingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _ReportTab _activeTab = _ReportTab.testResults;

  // Filters
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _tests = [];
  String? _selectedBatchId;
  String? _selectedTestId;

  // Data
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 30;

  List<Map<String, dynamic>> _testResults = [];
  List<Map<String, dynamic>> _studentProgress = [];
  List<Map<String, dynamic>> _batchPerformance = [];

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _ReportTab.values[_tabController.index];
          _page = 0;
          _hasMore = true;
        });
        _loadData(reset: true);
      }
    });
    _loadFilters();
    _loadData(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait<List<Map<String, dynamic>>>([
        SupabaseService.instance.fetchAllBatches(),
        SupabaseService.instance.fetchAllTestsSimple(),
      ]);
      if (mounted) {
        setState(() {
          _batches = results[0];
          _tests = results[1];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData({bool reset = false}) async {
    if (_isLoading) return;
    if (reset) {
      setState(() {
        _page = 0;
        _hasMore = true;
        _isLoading = true;
      });
    } else {
      if (!_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      switch (_activeTab) {
        case _ReportTab.testResults:
          final data = await SupabaseService.instance
              .fetchAdminTestResultsReport(
                page: _page,
                pageSize: _pageSize,
                batchId: _selectedBatchId,
                testId: _selectedTestId,
              );
          if (mounted) {
            setState(() {
              if (reset) {
                _testResults = data;
              } else {
                _testResults.addAll(data);
              }
              _hasMore = data.length == _pageSize;
              _page++;
            });
          }
          break;
        case _ReportTab.studentProgress:
          final data = await SupabaseService.instance
              .fetchStudentProgressReport(
                page: _page,
                pageSize: _pageSize,
                batchId: _selectedBatchId,
              );
          if (mounted) {
            setState(() {
              if (reset) {
                _studentProgress = data;
              } else {
                _studentProgress.addAll(data);
              }
              _hasMore = data.length == _pageSize;
              _page++;
            });
          }
          break;
        case _ReportTab.batchPerformance:
          final data = await SupabaseService.instance
              .fetchBatchPerformanceReport();
          if (mounted) {
            setState(() {
              _batchPerformance = data;
              _hasMore = false;
            });
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load report: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  // ── CSV Export ───────────────────────────────────────────

  String _buildCsv(List<List<String>> rows) {
    return rows
        .map(
          (row) => row
              .map((cell) {
                final escaped = cell.replaceAll('"', '""');
                return '"$escaped"';
              })
              .join(','),
        )
        .join('\n');
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      List<List<String>> rows = [];
      String filename = '';

      switch (_activeTab) {
        case _ReportTab.testResults:
          filename =
              'test_results_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          rows.add([
            'Student Name',
            'Email',
            'Test Title',
            'Batch',
            'Score',
            'Total Marks',
            'Percentage',
            'Submitted At',
          ]);
          for (final r in _testResults) {
            final profile = r['user_profiles'] as Map<String, dynamic>?;
            final test = r['tests'] as Map<String, dynamic>?;
            final batch = test?['batches'] as Map<String, dynamic>?;
            final score = (r['score'] as num?)?.toDouble() ?? 0;
            final total = (r['total_marks'] as num?)?.toDouble() ?? 0;
            final pct = total > 0
                ? (score / total * 100).toStringAsFixed(1)
                : '0.0';
            final submittedAt = r['submitted_at'] as String? ?? '';
            final dt = DateTime.tryParse(submittedAt);
            rows.add([
              profile?['full_name'] as String? ?? 'Unknown',
              profile?['email'] as String? ?? '',
              test?['title'] as String? ?? '',
              batch?['name'] as String? ?? '',
              score.toStringAsFixed(1),
              total.toStringAsFixed(1),
              '$pct%',
              dt != null
                  ? DateFormat('dd MMM yyyy HH:mm').format(dt.toLocal())
                  : '',
            ]);
          }
          break;
        case _ReportTab.studentProgress:
          filename =
              'student_progress_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          rows.add([
            'Student Name',
            'Email',
            'Tests Taken',
            'Avg Score %',
            'Lessons Completed',
            'Joined',
          ]);
          for (final r in _studentProgress) {
            final joinedAt = r['joined_at'] as String? ?? '';
            final dt = DateTime.tryParse(joinedAt);
            rows.add([
              r['full_name'] as String? ?? '',
              r['email'] as String? ?? '',
              '${r['tests_taken'] ?? 0}',
              '${((r['avg_score_pct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
              '${r['lessons_completed'] ?? 0}',
              dt != null ? DateFormat('dd MMM yyyy').format(dt.toLocal()) : '',
            ]);
          }
          break;
        case _ReportTab.batchPerformance:
          filename =
              'batch_performance_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
          rows.add([
            'Batch Name',
            'Status',
            'Total Students',
            'Total Tests',
            'Total Attempts',
            'Avg Score %',
          ]);
          for (final r in _batchPerformance) {
            rows.add([
              r['batch_name'] as String? ?? '',
              (r['is_active'] as bool? ?? false) ? 'Active' : 'Inactive',
              '${r['total_students'] ?? 0}',
              '${r['total_tests'] ?? 0}',
              '${r['total_attempts'] ?? 0}',
              '${((r['avg_score_pct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
            ]);
          }
          break;
      }

      final csvString = _buildCsv(rows);
      final bytes = Uint8List.fromList(utf8.encode(csvString));

      if (kIsWeb) {
        // Web: trigger a real browser file download via an anchor element
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported: $filename'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── PDF Export ───────────────────────────────────────────

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

      switch (_activeTab) {
        case _ReportTab.testResults:
          pdf.addPage(_buildTestResultsPdfPage(now));
          break;
        case _ReportTab.studentProgress:
          pdf.addPage(_buildStudentProgressPdfPage(now));
          break;
        case _ReportTab.batchPerformance:
          pdf.addPage(_buildBatchPerformancePdfPage(now));
          break;
      }

      final bytes = await pdf.save();
      final tabName = [
        'test_results',
        'student_progress',
        'batch_performance',
      ][_tabController.index];
      final filename =
          '${tabName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

      await Printing.sharePdf(bytes: bytes, filename: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported: $filename'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Page _buildTestResultsPdfPage(String generatedAt) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfHeader('Test Results Report', generatedAt),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1),
                6: const pw.FlexColumnWidth(1),
              },
              children: [
                _pdfTableHeader([
                  'Student',
                  'Email',
                  'Test',
                  'Batch',
                  'Score',
                  'Total',
                  '%',
                ]),
                ..._testResults.take(200).map((r) {
                  final profile = r['user_profiles'] as Map<String, dynamic>?;
                  final test = r['tests'] as Map<String, dynamic>?;
                  final batch = test?['batches'] as Map<String, dynamic>?;
                  final score = (r['score'] as num?)?.toDouble() ?? 0;
                  final total = (r['total_marks'] as num?)?.toDouble() ?? 0;
                  final pct = total > 0 ? (score / total * 100) : 0.0;
                  return _pdfTableRow([
                    profile?['full_name'] as String? ?? 'Unknown',
                    profile?['email'] as String? ?? '',
                    test?['title'] as String? ?? '',
                    batch?['name'] as String? ?? '',
                    score.toStringAsFixed(1),
                    total.toStringAsFixed(1),
                    '${pct.toStringAsFixed(1)}%',
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total records: ${_testResults.length}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildStudentProgressPdfPage(String generatedAt) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfHeader('Student Progress Report', generatedAt),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2.5),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _pdfTableHeader([
                  'Name',
                  'Email',
                  'Tests Taken',
                  'Avg Score %',
                  'Lessons Done',
                  'Joined',
                ]),
                ..._studentProgress.take(200).map((r) {
                  final joinedAt = r['joined_at'] as String? ?? '';
                  final dt = DateTime.tryParse(joinedAt);
                  return _pdfTableRow([
                    r['full_name'] as String? ?? '',
                    r['email'] as String? ?? '',
                    '${r['tests_taken'] ?? 0}',
                    '${((r['avg_score_pct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
                    '${r['lessons_completed'] ?? 0}',
                    dt != null
                        ? DateFormat('dd MMM yyyy').format(dt.toLocal())
                        : '',
                  ]);
                }),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Total records: ${_studentProgress.length}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        );
      },
    );
  }

  pw.Page _buildBatchPerformancePdfPage(String generatedAt) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfHeader('Batch Performance Analytics', generatedAt),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                _pdfTableHeader([
                  'Batch Name',
                  'Status',
                  'Students',
                  'Tests',
                  'Attempts',
                  'Avg Score %',
                ]),
                ..._batchPerformance.map((r) {
                  return _pdfTableRow([
                    r['batch_name'] as String? ?? '',
                    (r['is_active'] as bool? ?? false) ? 'Active' : 'Inactive',
                    '${r['total_students'] ?? 0}',
                    '${r['total_tests'] ?? 0}',
                    '${r['total_attempts'] ?? 0}',
                    '${((r['avg_score_pct'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
                  ]);
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  pw.Widget _pdfHeader(String title, String generatedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Text(
              'GREApp',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated: $generatedAt',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.Divider(color: PdfColors.indigo200, thickness: 1),
      ],
    );
  }

  pw.TableRow _pdfTableHeader(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
      children: headers
          .map(
            (h) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 5,
              ),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  pw.TableRow _pdfTableRow(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map(
            (c) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              child: pw.Text(
                c,
                style: const pw.TextStyle(fontSize: 8),
                overflow: pw.TextOverflow.clip,
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                'Reports & Analytics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                if (_isExporting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.table_chart_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    tooltip: 'Export CSV',
                    onPressed: _exportCsv,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    tooltip: 'Export PDF',
                    onPressed: _exportPdf,
                  ),
                ],
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => _loadData(reset: true),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Test Results'),
                  Tab(text: 'Student Progress'),
                  Tab(text: 'Batch Analytics'),
                ],
              ),
            ),
          ],
          body: Column(
            children: [
              _buildFilterBar(theme),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTestResultsTab(theme),
                    _buildStudentProgressTab(theme),
                    _buildBatchPerformanceTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown(
              hint: 'All Batches',
              value: _selectedBatchId,
              items: _batches
                  .map(
                    (b) => DropdownMenuItem(
                      value: b['id'] as String,
                      child: Text(
                        b['name'] as String? ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedBatchId = v;
                  _page = 0;
                  _hasMore = true;
                });
                _loadData(reset: true);
              },
            ),
          ),
          if (_activeTab == _ReportTab.testResults) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _FilterDropdown(
                hint: 'All Tests',
                value: _selectedTestId,
                items: _tests
                    .map(
                      (t) => DropdownMenuItem(
                        value: t['id'] as String,
                        child: Text(
                          t['title'] as String? ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedTestId = v;
                    _page = 0;
                    _hasMore = true;
                  });
                  _loadData(reset: true);
                },
              ),
            ),
          ],
          if (_selectedBatchId != null || _selectedTestId != null)
            IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                size: 18,
                color: AppTheme.textMuted,
              ),
              tooltip: 'Clear filters',
              onPressed: () {
                setState(() {
                  _selectedBatchId = null;
                  _selectedTestId = null;
                  _page = 0;
                  _hasMore = true;
                });
                _loadData(reset: true);
              },
            ),
        ],
      ),
    );
  }

  // ── Test Results Tab ─────────────────────────────────────

  Widget _buildTestResultsTab(ThemeData theme) {
    if (_isLoading) return _buildLoader();
    if (_testResults.isEmpty) return _buildEmpty('No test results found');

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.extentAfter < 200 &&
            _hasMore &&
            !_isLoadingMore) {
          _loadData();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testResults.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _testResults.length) return _buildLoadMoreIndicator();
          final r = _testResults[i];
          final profile = r['user_profiles'] as Map<String, dynamic>?;
          final test = r['tests'] as Map<String, dynamic>?;
          final batch = test?['batches'] as Map<String, dynamic>?;
          final score = (r['score'] as num?)?.toDouble() ?? 0;
          final total = (r['total_marks'] as num?)?.toDouble() ?? 0;
          final pct = total > 0 ? (score / total * 100) : 0.0;
          final submittedAt = r['submitted_at'] as String? ?? '';
          final dt = DateTime.tryParse(submittedAt);
          final pctColor = pct >= 75
              ? AppTheme.success
              : pct >= 50
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?['full_name'] as String? ??
                                'Unknown Student',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?['email'] as String? ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pctColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: pctColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.assignment_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        test?['title'] as String? ?? 'Unknown Test',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (batch != null) ...[
                      const Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        batch['name'] as String? ?? '',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(
                      Icons.score_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${score.toStringAsFixed(1)} / ${total.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (dt != null)
                      Text(
                        DateFormat('dd MMM, HH:mm').format(dt.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    backgroundColor: AppTheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Student Progress Tab ─────────────────────────────────

  Widget _buildStudentProgressTab(ThemeData theme) {
    if (_isLoading) return _buildLoader();
    if (_studentProgress.isEmpty) return _buildEmpty('No student data found');

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.extentAfter < 200 &&
            _hasMore &&
            !_isLoadingMore) {
          _loadData();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _studentProgress.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _studentProgress.length) return _buildLoadMoreIndicator();
          final r = _studentProgress[i];
          final name = r['full_name'] as String? ?? 'Unknown';
          final email = r['email'] as String? ?? '';
          final testsTaken = r['tests_taken'] as int? ?? 0;
          final avgScore = (r['avg_score_pct'] as num?)?.toDouble() ?? 0;
          final lessonsCompleted = r['lessons_completed'] as int? ?? 0;
          final joinedAt = r['joined_at'] as String? ?? '';
          final dt = DateTime.tryParse(joinedAt);
          final initials = name.trim().isEmpty
              ? '?'
              : name
                    .trim()
                    .split(' ')
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join();
          final scoreColor = avgScore >= 75
              ? AppTheme.success
              : avgScore >= 50
              ? AppTheme.warning
              : avgScore > 0
              ? AppTheme.error
              : AppTheme.textMuted;

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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryContainer,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatChip(
                            icon: Icons.assignment_turned_in_rounded,
                            label: '$testsTaken tests',
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          _StatChip(
                            icon: Icons.menu_book_rounded,
                            label: '$lessonsCompleted lessons',
                            color: AppTheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${avgScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      'avg score',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    if (dt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yy').format(dt.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Batch Performance Tab ────────────────────────────────

  Widget _buildBatchPerformanceTab(ThemeData theme) {
    if (_isLoading) return _buildLoader();
    if (_batchPerformance.isEmpty) return _buildEmpty('No batch data found');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _batchPerformance.length,
      itemBuilder: (context, i) {
        final r = _batchPerformance[i];
        final batchName = r['batch_name'] as String? ?? 'Unnamed Batch';
        final isActive = r['is_active'] as bool? ?? false;
        final totalStudents = r['total_students'] as int? ?? 0;
        final totalTests = r['total_tests'] as int? ?? 0;
        final totalAttempts = r['total_attempts'] as int? ?? 0;
        final avgScore = (r['avg_score_pct'] as num?)?.toDouble() ?? 0;
        final scoreColor = avgScore >= 75
            ? AppTheme.success
            : avgScore >= 50
            ? AppTheme.warning
            : avgScore > 0
            ? AppTheme.error
            : AppTheme.textMuted;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      batchName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
                      color: isActive
                          ? AppTheme.successContainer
                          : AppTheme.outlineVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppTheme.success : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _BatchMetric(
                      label: 'Students',
                      value: '$totalStudents',
                      icon: Icons.people_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _BatchMetric(
                      label: 'Tests',
                      value: '$totalTests',
                      icon: Icons.assignment_rounded,
                      color: AppTheme.accent,
                    ),
                  ),
                  Expanded(
                    child: _BatchMetric(
                      label: 'Attempts',
                      value: '$totalAttempts',
                      icon: Icons.how_to_reg_rounded,
                      color: AppTheme.secondary,
                    ),
                  ),
                  Expanded(
                    child: _BatchMetric(
                      label: 'Avg Score',
                      value: '${avgScore.toStringAsFixed(1)}%',
                      icon: Icons.bar_chart_rounded,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (avgScore / 100).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── Helper Widgets ───────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outline, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppTheme.textMuted,
          ),
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: AppTheme.textPrimary,
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                hint,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BatchMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'IBM Plex Mono',
            fontSize: 14,
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
        ),
      ],
    );
  }
}
