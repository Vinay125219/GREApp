import 'package:universal_html/html.dart' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_navigation.dart';

// ─── Main Admin Content Screen ────────────────────────────────

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _batches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.instance.fetchAllCourses(),
        SupabaseService.instance.fetchAllTests(),
        SupabaseService.instance.fetchAllBatches(),
      ]);
      if (mounted) {
        setState(() {
          _courses = results[0];
          _tests = results[1];
          _batches = results[2];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateCourseDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppTheme.secondary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Create Course',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    hintText: 'e.g. Verbal Reasoning',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              await SupabaseService.instance.createCourse(
                                title: nameCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadContent();
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Course',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateTestDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '60');
    final marksCtrl = TextEditingController(text: '100');
    String? selectedCourseId;
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Create Test',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Test Name',
                      hintText: 'e.g. GRE Mock Test 1',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Link to course
                  if (_courses.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Link to Course (optional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No course'),
                        ),
                        ..._courses.map(
                          (c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(
                              c['title'] as String? ?? 'Untitled',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setModalState(() => selectedCourseId = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (mins)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: marksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Marks',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await SupabaseService.instance.createTest(
                                  title: nameCtrl.text.trim(),
                                  description: descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                                  courseId: selectedCourseId,
                                  durationMins:
                                      int.tryParse(durationCtrl.text) ?? 60,
                                  totalMarks:
                                      int.tryParse(marksCtrl.text) ?? 100,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadContent();
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Test',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateBatchDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Create Batch',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name',
                    hintText: 'e.g. GRE Batch 2026',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              await SupabaseService.instance.createBatch(
                                name: nameCtrl.text.trim(),
                                description: descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadContent();
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Batch',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTestQuestions(Map<String, dynamic> test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminTestQuestionsScreen(
          testId: test['id'] as String,
          testTitle: test['title'] as String? ?? 'Test',
        ),
      ),
    ).then((_) => _loadContent());
  }

  void _openCourseMaterials(Map<String, dynamic> course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminCourseMaterialsScreen(
          courseId: course['id'] as String,
          courseTitle: course['title'] as String? ?? 'Course',
        ),
      ),
    ).then((_) => _loadContent());
  }

  void _openBatchDetail(Map<String, dynamic> batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminBatchDetailScreen(
          batchId: batch['id'] as String,
          batchName: batch['name'] as String? ?? 'Batch',
          courses: _courses,
          tests: _tests,
        ),
      ),
    ).then((_) => _loadContent());
  }

  void _onAdminNavDestination(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboardScreen);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.adminStudentsScreen);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.adminAnalyticsScreen);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.adminSettingsScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AdaptiveScaffoldBody(
        navigationRail: AdminNavigationRail(
          currentIndex: 2,
          onDestinationSelected: _onAdminNavDestination,
        ),
        child: SafeArea(child: _buildContentShell(theme)),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildContentShell(ThemeData theme) {
    return Column(
      children: [
        _buildContentHeader(theme),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCourseList(theme),
                    _buildMaterialsTab(theme),
                    _buildTestList(theme),
                    _buildBatchList(theme),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildContentHeader(ThemeData theme) {
    final compact = context.isCompact;
    final horizontalPadding = compact ? 12.0 : 24.0;

    return Material(
      color: AppTheme.surface,
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContent,
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 4 : 12,
                  8,
                  horizontalPadding,
                  4,
                ),
                child: Row(
                  children: [
                    if (context.isWide)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.library_books_rounded,
                          color: AppTheme.secondary,
                          size: 20,
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    SizedBox(width: context.isWide ? 12 : 0),
                    Expanded(
                      child: Text(
                        'Content Management',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: _loadContent,
                      tooltip: 'Refresh content',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  4,
                  horizontalPadding,
                  6,
                ),
                child: Align(
                  alignment: compact ? Alignment.centerLeft : Alignment.center,
                  child: _buildWorkflowSteps(),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.primary,
                isScrollable: compact,
                tabAlignment: compact ? TabAlignment.start : TabAlignment.fill,
                labelStyle: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
                onTap: (_) => setState(() {}),
                tabs: [
                  _buildContentTab(
                    icon: Icons.menu_book_rounded,
                    label: compact ? 'Courses' : 'Courses (${_courses.length})',
                  ),
                  _buildContentTab(
                    icon: Icons.picture_as_pdf_rounded,
                    label: compact ? 'Files' : 'Materials',
                  ),
                  _buildContentTab(
                    icon: Icons.assignment_rounded,
                    label: compact ? 'Tests' : 'Tests (${_tests.length})',
                  ),
                  _buildContentTab(
                    icon: Icons.groups_rounded,
                    label: compact ? 'Batches' : 'Batches (${_batches.length})',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowSteps() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WorkflowStep(
          step: 1,
          label: 'Courses',
          isActive: _tabController.index == 0,
          color: AppTheme.secondary,
        ),
        _WorkflowConnector(),
        _WorkflowStep(
          step: 2,
          label: 'Materials',
          isActive: _tabController.index == 1,
          color: AppTheme.warning,
        ),
        _WorkflowConnector(),
        _WorkflowStep(
          step: 3,
          label: 'Tests',
          isActive: _tabController.index == 2,
          color: AppTheme.primary,
        ),
        _WorkflowConnector(),
        _WorkflowStep(
          step: 4,
          label: 'Batches',
          isActive: _tabController.index == 3,
          color: AppTheme.accent,
        ),
      ],
    );
  }

  Tab _buildContentTab({required IconData icon, required String label}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14), const SizedBox(width: 5), Text(label)],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final idx = _tabController.index;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.small(
              heroTag: 'schedule',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.adminScheduleScreen),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              tooltip: 'Drip Schedule',
              child: const Icon(Icons.schedule_rounded, size: 20),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.small(
              heroTag: 'bulk_upload',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.adminBulkUploadScreen),
              backgroundColor: AppTheme.secondary,
              foregroundColor: Colors.white,
              tooltip: 'Bulk Upload',
              child: const Icon(Icons.upload_file_rounded, size: 20),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'create',
              onPressed: () {
                if (idx == 0) {
                  _showCreateCourseDialog();
                } else if (idx == 1) {
                  _showSelectCourseForMaterials();
                } else if (idx == 2) {
                  _showCreateTestDialog();
                } else {
                  _showCreateBatchDialog();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(
                idx == 0
                    ? 'Course'
                    : idx == 1
                    ? 'Materials'
                    : idx == 2
                    ? 'Test'
                    : 'Batch',
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: idx == 0
                  ? AppTheme.secondary
                  : idx == 1
                  ? AppTheme.warning
                  : idx == 2
                  ? AppTheme.primary
                  : AppTheme.accent,
              foregroundColor: Colors.white,
            ),
          ],
        );
      },
    );
  }

  void _showEditTestDialog(Map<String, dynamic> test) {
    final nameCtrl = TextEditingController(
      text: test['title'] as String? ?? '',
    );
    final descCtrl = TextEditingController(
      text: test['description'] as String? ?? '',
    );
    final durationCtrl = TextEditingController(
      text: '${test['duration_mins'] ?? 60}',
    );
    final marksCtrl = TextEditingController(
      text: '${test['total_marks'] ?? 100}',
    );
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit Test',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Test Name',
                      hintText: 'e.g. GRE Mock Test 1',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: durationCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Duration (mins)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: marksCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total Marks',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await SupabaseService.instance.updateTest(
                                  test['id'] as String,
                                  {
                                    'title': nameCtrl.text.trim(),
                                    'description': descCtrl.text.trim().isEmpty
                                        ? null
                                        : descCtrl.text.trim(),
                                    'duration_mins':
                                        int.tryParse(durationCtrl.text) ?? 60,
                                    'total_marks':
                                        int.tryParse(marksCtrl.text) ?? 100,
                                  },
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadContent();
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update: $e'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSelectCourseForMaterials() {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a course first before adding materials.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Course for Materials',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _courses.length,
            itemBuilder: (ctx, i) {
              final course = _courses[i];
              return ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.secondary,
                    size: 18,
                  ),
                ),
                title: Text(
                  course['title'] as String? ?? 'Untitled',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${course['total_lessons'] ?? 0} lessons',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textMuted,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCourseMaterials(course);
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCourseList(ThemeData theme) {
    if (_courses.isEmpty) {
      return _emptyState(
        'No courses yet',
        'Create your first course to get started',
        Icons.library_books_outlined,
        AppTheme.secondary,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadContent,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: context.adaptivePagePadding(bottom: 112),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          final isPublished = course['is_published'] as bool? ?? false;
          return AdaptiveListItem(
            child: _CourseCard(
              course: course,
              onTap: () => _openCourseMaterials(course),
              onPublishToggle: () async {
                await SupabaseService.instance.publishCourse(
                  course['id'] as String,
                  !isPublished,
                );
                _loadContent();
              },
              onDelete: () async {
                final confirmed = await _showDeleteConfirm(
                  context,
                  'Delete Course',
                  'Delete "${course['title']}"? All lessons will be removed.',
                );
                if (confirmed == true) {
                  await SupabaseService.instance.deleteCourse(
                    course['id'] as String,
                  );
                  _loadContent();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMaterialsTab(ThemeData theme) {
    if (_courses.isEmpty) {
      return _emptyState(
        'No courses yet',
        'Create a course first, then add PDF materials',
        Icons.picture_as_pdf_outlined,
        AppTheme.warning,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadContent,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: context.adaptivePagePadding(bottom: 112),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return AdaptiveListItem(
            child: _MaterialsCourseCard(
              course: course,
              onTap: () => _openCourseMaterials(course),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestList(ThemeData theme) {
    if (_tests.isEmpty) {
      return _emptyState(
        'No tests yet',
        'Create tests and add questions to them',
        Icons.assignment_outlined,
        AppTheme.primary,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadContent,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: context.adaptivePagePadding(bottom: 112),
        itemCount: _tests.length,
        itemBuilder: (context, index) {
          final test = _tests[index];
          return AdaptiveListItem(
            child: _TestCard(
              test: test,
              onTap: () => _openTestQuestions(test),
              onEdit: () => _showEditTestDialog(test),
              onStatusChange: (newStatus) async {
                await SupabaseService.instance.publishTest(
                  test['id'] as String,
                  newStatus,
                );
                _loadContent();
              },
              onDelete: () async {
                final confirmed = await _showDeleteConfirm(
                  context,
                  'Delete Test',
                  'Delete "${test['title']}"? All questions will be removed.',
                );
                if (confirmed == true) {
                  await SupabaseService.instance.deleteTest(
                    test['id'] as String,
                  );
                  _loadContent();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBatchList(ThemeData theme) {
    if (_batches.isEmpty) {
      return _emptyState(
        'No batches yet',
        'Create batches and assign courses, materials & tests to students',
        Icons.groups_outlined,
        AppTheme.accent,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadContent,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: context.adaptivePagePadding(bottom: 112),
        itemCount: _batches.length,
        itemBuilder: (context, index) {
          final batch = _batches[index];
          return AdaptiveListItem(
            child: _BatchCard(
              batch: batch,
              onTap: () => _openBatchDetail(batch),
              onDelete: () async {
                final confirmed = await _showDeleteConfirm(
                  context,
                  'Delete Batch',
                  'Delete "${batch['name']}"? Student enrollments will be removed.',
                );
                if (confirmed == true) {
                  await SupabaseService.instance.deleteBatch(
                    batch['id'] as String,
                  );
                  _loadContent();
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _showDeleteConfirm(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

// ─── Workflow Step Indicator ──────────────────────────────────

class _WorkflowStep extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final Color color;

  const _WorkflowStep({
    required this.step,
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return SizedBox(
      width: compact ? 68 : 94,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? color : AppTheme.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? color : AppTheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppTheme.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? color : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowConnector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.isCompact ? 22 : 56,
      height: 1,
      color: AppTheme.outlineVariant,
      margin: const EdgeInsets.only(bottom: 14),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final VoidCallback onPublishToggle;
  final VoidCallback onDelete;

  const _CourseCard({
    required this.course,
    required this.onTap,
    required this.onPublishToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = course['is_published'] as bool? ?? false;
    final batch = course['batches'] as Map<String, dynamic>?;
    final totalLessons = course['total_lessons'] as int? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: AppTheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 22,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] as String? ?? 'Untitled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.layers_rounded,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$totalLessons lessons',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      if (batch != null) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.groups_rounded,
                          size: 11,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            batch['name'] as String? ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPublished
                          ? AppTheme.success
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 12,
                              color: AppTheme.secondary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Materials',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      onSelected: (val) {
                        if (val == 'publish') onPublishToggle();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(
                                isPublished
                                    ? Icons.unpublished_rounded
                                    : Icons.publish_rounded,
                                size: 16,
                                color: isPublished
                                    ? AppTheme.warning
                                    : AppTheme.success,
                              ),
                              const SizedBox(width: 8),
                              Text(isPublished ? 'Unpublish' : 'Publish'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Materials Course Card ────────────────────────────────────

class _MaterialsCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;

  const _MaterialsCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLessons = course['total_lessons'] as int? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
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
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                size: 22,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['title'] as String? ?? 'Untitled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalLessons lesson${totalLessons == 1 ? '' : 's'} · Tap to manage PDFs',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    size: 14,
                    color: AppTheme.warning,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Upload PDF',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Test Card ────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  final Map<String, dynamic> test;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onDelete;

  const _TestCard({
    required this.test,
    required this.onTap,
    required this.onEdit,
    required this.onStatusChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = test['status'] as String? ?? 'draft';
    final durationMins = test['duration_mins'] as int? ?? 60;
    final totalMarks = test['total_marks'] as int? ?? 100;

    Color statusColor = status == 'published'
        ? AppTheme.success
        : status == 'archived'
        ? AppTheme.textMuted
        : AppTheme.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                size: 22,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test['title'] as String? ?? 'Untitled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$durationMins mins',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_outline_rounded,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$totalMarks marks',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.quiz_rounded,
                              size: 12,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Questions',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'publish') onStatusChange('published');
                        if (val == 'draft') onStatusChange('draft');
                        if (val == 'archive') onStatusChange('archived');
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Edit Test',
                                style: TextStyle(color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),
                        if (status != 'published')
                          const PopupMenuItem(
                            value: 'publish',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.publish_rounded,
                                  size: 16,
                                  color: AppTheme.success,
                                ),
                                SizedBox(width: 8),
                                Text('Publish'),
                              ],
                            ),
                          ),
                        if (status != 'draft')
                          const PopupMenuItem(
                            value: 'draft',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 16,
                                  color: AppTheme.warning,
                                ),
                                SizedBox(width: 8),
                                Text('Move to Draft'),
                              ],
                            ),
                          ),
                        if (status != 'archived')
                          const PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.archive_rounded,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                                SizedBox(width: 8),
                                Text('Archive'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Batch Card ───────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  final Map<String, dynamic> batch;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BatchCard({
    required this.batch,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = batch['is_active'] as bool? ?? true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 22,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch['name'] as String? ?? 'Untitled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    batch['description'] as String? ??
                        'Tap to manage assignments',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.success : AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_ind_rounded,
                              size: 12,
                              color: AppTheme.accent,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Assign',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      onSelected: (val) {
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Course Materials Screen ───────────────────────────

class AdminCourseMaterialsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const AdminCourseMaterialsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<AdminCourseMaterialsScreen> createState() =>
      _AdminCourseMaterialsScreenState();
}

class _AdminCourseMaterialsScreenState
    extends State<AdminCourseMaterialsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _lessons = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final lessons = await SupabaseService.instance.fetchCourseLessonsAdmin(
        widget.courseId,
      );
      if (mounted) {
        setState(() {
          _lessons = lessons;
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

  void _openLessonPreview(Map<String, dynamic> lesson) {
    final lessonType = lesson['lesson_type'] as String? ?? 'text';
    final contentUrl = lesson['content_url'] as String?;
    final title = lesson['title'] as String? ?? 'Lesson';

    if (lessonType == 'pdf' && contentUrl != null && contentUrl.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/pdf-viewer-screen',
        arguments: {
          'pdfUrl': contentUrl,
          'title': title,
          'lessonId': lesson['id'] as String? ?? '',
        },
      );
    } else if (lessonType == 'video' &&
        contentUrl != null &&
        contentUrl.isNotEmpty) {
      html.window.open(contentUrl, '_blank');
    } else if (lessonType == 'text') {
      _showTextPreviewDialog(lesson);
    } else if (contentUrl != null && contentUrl.isNotEmpty) {
      html.window.open(contentUrl, '_blank');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No content URL set for this lesson.'),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  void _showTextPreviewDialog(Map<String, dynamic> lesson) {
    final title = lesson['title'] as String? ?? 'Lesson';
    final contentUrl = lesson['content_url'] as String? ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.article_outlined,
              color: AppTheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Content / Notes:',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  contentUrl.isEmpty ? 'No content available.' : contentUrl,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditLessonDialog(Map<String, dynamic> lesson) {
    final titleCtrl = TextEditingController(
      text: lesson['title'] as String? ?? '',
    );
    final durationCtrl = TextEditingController(
      text: lesson['duration_mins'] != null ? '${lesson['duration_mins']}' : '',
    );
    final contentUrlCtrl = TextEditingController(
      text: lesson['content_url'] as String? ?? '',
    );
    String selectedType = lesson['lesson_type'] as String? ?? 'pdf';
    bool isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: AppTheme.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit Lesson',
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Chapter 1 - Introduction',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Content Type',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _TypeChip(
                        label: 'PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        isSelected: selectedType == 'pdf',
                        color: AppTheme.warning,
                        onTap: () => setModalState(() => selectedType = 'pdf'),
                      ),
                      _TypeChip(
                        label: 'Video',
                        icon: Icons.play_circle_outline_rounded,
                        isSelected: selectedType == 'video',
                        color: AppTheme.primary,
                        onTap: () =>
                            setModalState(() => selectedType = 'video'),
                      ),
                      _TypeChip(
                        label: 'Text',
                        icon: Icons.article_outlined,
                        isSelected: selectedType == 'text',
                        color: AppTheme.secondary,
                        onTap: () => setModalState(() => selectedType = 'text'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contentUrlCtrl,
                    decoration: InputDecoration(
                      labelText: selectedType == 'video'
                          ? 'Video URL'
                          : selectedType == 'pdf'
                          ? 'PDF URL'
                          : 'Content URL / Notes',
                      hintText: selectedType == 'video'
                          ? 'https://...'
                          : selectedType == 'pdf'
                          ? 'https://...'
                          : 'Enter notes or URL',
                    ),
                    maxLines: selectedType == 'text' ? 3 : 1,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (mins)',
                      hintText: 'e.g. 30',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await SupabaseService.instance
                                    .updateLesson(lesson['id'] as String, {
                                      'title': titleCtrl.text.trim(),
                                      'lesson_type': selectedType,
                                      'content_url':
                                          contentUrlCtrl.text.trim().isEmpty
                                          ? null
                                          : contentUrlCtrl.text.trim(),
                                      'duration_mins':
                                          durationCtrl.text.trim().isEmpty
                                          ? null
                                          : int.tryParse(
                                              durationCtrl.text.trim(),
                                            ),
                                    });
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadLessons();
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update: $e'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddLessonDialog() {
    final titleCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedType = 'pdf';
    String? pdfUrl;
    bool isUploading = false;
    bool isSubmitting = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Add Material / Lesson',
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Chapter 1 - Introduction',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  // Type selector
                  const Text(
                    'Content Type',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _TypeChip(
                        label: 'PDF',
                        icon: Icons.picture_as_pdf_rounded,
                        isSelected: selectedType == 'pdf',
                        color: AppTheme.warning,
                        onTap: () => setModalState(() => selectedType = 'pdf'),
                      ),
                      _TypeChip(
                        label: 'Video',
                        icon: Icons.play_circle_outline_rounded,
                        isSelected: selectedType == 'video',
                        color: AppTheme.primary,
                        onTap: () =>
                            setModalState(() => selectedType = 'video'),
                      ),
                      _TypeChip(
                        label: 'Text',
                        icon: Icons.article_outlined,
                        isSelected: selectedType == 'text',
                        color: AppTheme.secondary,
                        onTap: () => setModalState(() => selectedType = 'text'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // PDF Upload
                  if (selectedType == 'pdf') ...[
                    const Text(
                      'PDF File',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pdfUrl != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'PDF uploaded successfully',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 13,
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              onPressed: () =>
                                  setModalState(() => pdfUrl = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: isUploading
                            ? null
                            : () async {
                                try {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['pdf'],
                                      );
                                  if (result == null || result.files.isEmpty) {
                                    return;
                                  }
                                  final file = result.files.first;
                                  final bytes = file.bytes;
                                  if (bytes == null) return;
                                  setModalState(() => isUploading = true);
                                  final url = await SupabaseService.instance
                                      .uploadCoursePdf(
                                        bytes: bytes,
                                        fileName: file.name,
                                      );
                                  setModalState(() {
                                    pdfUrl = url;
                                    isUploading = false;
                                  });
                                } catch (e) {
                                  setModalState(() => isUploading = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload failed: $e'),
                                        backgroundColor: AppTheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.warning.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: isUploading
                              ? const Column(
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppTheme.warning,
                                      strokeWidth: 2,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Uploading PDF...',
                                      style: TextStyle(
                                        fontFamily: 'IBM Plex Sans',
                                        fontSize: 12,
                                        color: AppTheme.warning,
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  children: [
                                    Icon(
                                      Icons.upload_file_rounded,
                                      color: AppTheme.warning,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to upload PDF',
                                      style: TextStyle(
                                        fontFamily: 'IBM Plex Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.warning,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Max 50MB · PDF files only',
                                      style: TextStyle(
                                        fontFamily: 'IBM Plex Sans',
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  // Video Upload / URL
                  if (selectedType == 'video') ...[
                    const Text(
                      'Video Source',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show success state if video uploaded or URL entered
                    if (pdfUrl != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.success,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Video ready',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 13,
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppTheme.error,
                              ),
                              onPressed: () =>
                                  setModalState(() => pdfUrl = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // URL input
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Video URL',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.link_rounded),
                        ),
                        onChanged: (v) =>
                            pdfUrl = v.trim().isEmpty ? null : v.trim(),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Local file upload
                      GestureDetector(
                        onTap: isUploading
                            ? null
                            : () async {
                                try {
                                  final result = await FilePicker.platform
                                      .pickFiles(type: FileType.video);
                                  if (result == null || result.files.isEmpty) {
                                    return;
                                  }
                                  final file = result.files.first;
                                  final bytes = file.bytes;
                                  if (bytes == null) return;
                                  setModalState(() => isUploading = true);
                                  // Determine MIME type from extension
                                  final ext = (file.extension ?? 'mp4')
                                      .toLowerCase();
                                  final mimeMap = {
                                    'mp4': 'video/mp4',
                                    'webm': 'video/webm',
                                    'ogg': 'video/ogg',
                                    'mov': 'video/quicktime',
                                    'avi': 'video/x-msvideo',
                                    'mpeg': 'video/mpeg',
                                    'mpg': 'video/mpeg',
                                  };
                                  final mime = mimeMap[ext] ?? 'video/mp4';
                                  final url = await SupabaseService.instance
                                      .uploadCourseVideo(
                                        bytes: bytes,
                                        fileName: file.name,
                                        mimeType: mime,
                                      );
                                  setModalState(() {
                                    pdfUrl = url;
                                    isUploading = false;
                                  });
                                } catch (e) {
                                  setModalState(() => isUploading = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('Upload failed: $e'),
                                        backgroundColor: AppTheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: isUploading
                              ? const Column(
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppTheme.primary,
                                      strokeWidth: 2,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Uploading video...',
                                      style: TextStyle(
                                        fontFamily: 'IBM Plex Sans',
                                        fontSize: 12,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  children: [
                                    Icon(
                                      Icons.video_call_rounded,
                                      color: AppTheme.primary,
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to upload video from device',
                                      style: TextStyle(
                                        fontFamily: 'IBM Plex Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'MP4, WebM, MOV, AVI · Max 500MB',
                                      style: TextStyle(
                                        fontFamily: 'IBM Plex Sans',
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (mins, optional)',
                      hintText: 'e.g. 30',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (isSubmitting || isUploading)
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              try {
                                await SupabaseService.instance.createLesson(
                                  courseId: widget.courseId,
                                  title: titleCtrl.text.trim(),
                                  lessonType: selectedType,
                                  contentUrl: pdfUrl,
                                  durationMins: durationCtrl.text.trim().isEmpty
                                      ? null
                                      : int.tryParse(durationCtrl.text.trim()),
                                  sortOrder: _lessons.length + 1,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadLessons();
                              } catch (e) {
                                setModalState(() => isSubmitting = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save: $e'),
                                      backgroundColor: AppTheme.error,
                                    ),
                                  );
                                }
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.warning,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: (isSubmitting || isUploading)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add Material',
                              style: TextStyle(
                                fontFamily: 'IBM Plex Sans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Materials & Lessons',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: _loadLessons,
          ),
        ],
      ),
      body: _isLoading
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
                    'Failed to load materials',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadLessons,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _lessons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 40,
                      color: AppTheme.warning,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No materials yet',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload PDFs, videos, or text lessons',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showAddLessonDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Material'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLessons,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _lessons.length,
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  return _LessonMaterialCard(
                    lesson: lesson,
                    index: index,
                    onTap: () => _openLessonPreview(lesson),
                    onEdit: () => _showEditLessonDialog(lesson),
                    onPublishToggle: () async {
                      final isPublished =
                          lesson['is_published'] as bool? ?? false;
                      await SupabaseService.instance.publishLesson(
                        lesson['id'] as String,
                        !isPublished,
                      );
                      _loadLessons();
                    },
                    onDelete: () async {
                      final confirmed = await _showDeleteConfirm(
                        context,
                        'Delete Material',
                        'Delete "${lesson['title']}"?',
                      );
                      if (confirmed == true) {
                        await SupabaseService.instance.deleteLesson(
                          lesson['id'] as String,
                          widget.courseId,
                        );
                        _loadLessons();
                      }
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddLessonDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Material',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.warning,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Lesson Material Card ─────────────────────────────────────

class _LessonMaterialCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPublishToggle;
  final VoidCallback onDelete;

  const _LessonMaterialCard({
    required this.lesson,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onPublishToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonType = lesson['lesson_type'] as String? ?? 'text';
    final isPublished = lesson['is_published'] as bool? ?? false;
    final contentUrl = lesson['content_url'] as String?;
    final durationMins = lesson['duration_mins'] as int?;

    IconData typeIcon;
    Color typeColor;
    String typeLabel;
    switch (lessonType) {
      case 'pdf':
        typeIcon = Icons.picture_as_pdf_rounded;
        typeColor = AppTheme.warning;
        typeLabel = 'PDF';
        break;
      case 'video':
        typeIcon = Icons.play_circle_outline_rounded;
        typeColor = AppTheme.primary;
        typeLabel = 'Video';
        break;
      case 'quiz':
        typeIcon = Icons.quiz_rounded;
        typeColor = AppTheme.accent;
        typeLabel = 'Quiz';
        break;
      default:
        typeIcon = Icons.article_outlined;
        typeColor = AppTheme.secondary;
        typeLabel = 'Text';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, size: 18, color: typeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson['title'] as String? ?? 'Untitled',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                            ),
                          ),
                        ),
                        if (durationMins != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${durationMins}m',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                        if (contentUrl != null && lessonType == 'pdf') ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.cloud_done_rounded,
                            size: 11,
                            color: AppTheme.success,
                          ),
                          const SizedBox(width: 2),
                          const Text(
                            'Uploaded',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 10,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPublished
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPublished ? 'Live' : 'Draft',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPublished ? AppTheme.success : AppTheme.textMuted,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'publish') onPublishToggle();
                  if (val == 'delete') onDelete();
                  if (val == 'preview') onTap();
                  if (val == 'preview_pdf') {
                    Navigator.pushNamed(
                      context,
                      '/pdf-viewer-screen',
                      arguments: {
                        'pdfUrl': contentUrl,
                        'title': lesson['title'] as String? ?? 'PDF Document',
                        'lessonId': lesson['id'] as String? ?? '',
                      },
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: AppTheme.secondary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Preview',
                          style: TextStyle(color: AppTheme.secondary),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppTheme.warning,
                        ),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: AppTheme.warning)),
                      ],
                    ),
                  ),
                  if (lessonType == 'pdf' && contentUrl != null)
                    const PopupMenuItem(
                      value: 'preview_pdf',
                      child: Row(
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Open PDF',
                            style: TextStyle(color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'publish',
                    child: Row(
                      children: [
                        Icon(
                          isPublished
                              ? Icons.unpublished_rounded
                              : Icons.publish_rounded,
                          size: 16,
                          color: isPublished
                              ? AppTheme.warning
                              : AppTheme.success,
                        ),
                        const SizedBox(width: 8),
                        Text(isPublished ? 'Unpublish' : 'Publish'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppTheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Type Chip ────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : AppTheme.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Admin Batch Detail Screen ────────────────────────────────

class AdminBatchDetailScreen extends StatefulWidget {
  final String batchId;
  final String batchName;
  final List<Map<String, dynamic>> courses;
  final List<Map<String, dynamic>> tests;

  const AdminBatchDetailScreen({
    super.key,
    required this.batchId,
    required this.batchName,
    required this.courses,
    required this.tests,
  });

  @override
  State<AdminBatchDetailScreen> createState() => _AdminBatchDetailScreenState();
}

class _AdminBatchDetailScreenState extends State<AdminBatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _students = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
      final results = await Future.wait([
        SupabaseService.instance.fetchBatchAssignments(widget.batchId),
        SupabaseService.instance.fetchBatchStudents(widget.batchId),
      ]);
      if (mounted) {
        setState(() {
          _assignments = results[0];
          _students = results[1];
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

  void _showAssignDialog() {
    String assignType = 'course';
    String? selectedId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final assignedCourseIds = _assignments
              .where((a) => a['course_id'] != null)
              .map((a) => a['course_id'] as String)
              .toSet();
          final assignedTestIds = _assignments
              .where((a) => a['test_id'] != null)
              .map((a) => a['test_id'] as String)
              .toSet();

          final availableCourses = widget.courses
              .where((c) => !assignedCourseIds.contains(c['id'] as String))
              .toList();
          final availableTests = widget.tests
              .where((t) => !assignedTestIds.contains(t['id'] as String))
              .toList();

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Assign to Batch',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Type selector
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          assignType = 'course';
                          selectedId = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: assignType == 'course'
                                ? AppTheme.secondary.withValues(alpha: 0.12)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: assignType == 'course'
                                  ? AppTheme.secondary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 14,
                                color: assignType == 'course'
                                    ? AppTheme.secondary
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Course',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: assignType == 'course'
                                      ? AppTheme.secondary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() {
                          assignType = 'test';
                          selectedId = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: assignType == 'test'
                                ? AppTheme.primary.withValues(alpha: 0.12)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: assignType == 'test'
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_rounded,
                                size: 14,
                                color: assignType == 'test'
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Test',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: assignType == 'test'
                                      ? AppTheme.primary
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Dropdown
                if (assignType == 'course')
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    decoration: const InputDecoration(
                      labelText: 'Select Course',
                    ),
                    items: availableCourses.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All courses already assigned'),
                            ),
                          ]
                        : availableCourses
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(
                                    c['title'] as String? ?? 'Untitled',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                    onChanged: (v) => setModalState(() => selectedId = v),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    decoration: const InputDecoration(labelText: 'Select Test'),
                    items: availableTests.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All tests already assigned'),
                            ),
                          ]
                        : availableTests
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t['id'] as String,
                                  child: Text(
                                    t['title'] as String? ?? 'Untitled',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                    onChanged: (v) => setModalState(() => selectedId = v),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedId == null
                        ? null
                        : () async {
                            try {
                              if (assignType == 'course') {
                                await SupabaseService.instance
                                    .assignCourseToBatch(
                                      batchId: widget.batchId,
                                      courseId: selectedId!,
                                    );
                              } else {
                                await SupabaseService.instance
                                    .assignTestToBatch(
                                      batchId: widget.batchId,
                                      testId: selectedId!,
                                    );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _loadData();
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to assign: $e'),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Assign',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddStudentDialog() async {
    // Load all students first
    List<Map<String, dynamic>> allStudents = [];
    bool loadingStudents = true;
    String? loadError;

    final enrolledIds = _students
        .map((e) {
          final profile = e['user_profiles'] as Map<String, dynamic>?;
          return profile?['id'] as String?;
        })
        .whereType<String>()
        .toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loadingStudents && loadError == null) {
            SupabaseService.instance
                .fetchAllStudents(pageSize: 200)
                .then((students) {
                  setModalState(() {
                    allStudents = students
                        .where((s) => !enrolledIds.contains(s['id'] as String?))
                        .toList();
                    loadingStudents = false;
                  });
                })
                .catchError((e) {
                  setModalState(() {
                    loadError = e.toString();
                    loadingStudents = false;
                  });
                });
          }

          String? selectedStudentId;

          return StatefulBuilder(
            builder: (ctx2, setInnerState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: AppTheme.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Add Student to Batch',
                          style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (loadingStudents)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    else if (loadError != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Failed to load students',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ),
                      )
                    else if (allStudents.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'All students are already enrolled in this batch',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: selectedStudentId,
                        decoration: const InputDecoration(
                          labelText: 'Select Student',
                        ),
                        items: allStudents
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s['id'] as String,
                                child: Text(
                                  '${s['full_name'] ?? 'Unknown'} (${s['email'] ?? ''})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setInnerState(() => selectedStudentId = v),
                      ),
                    const SizedBox(height: 20),
                    if (!loadingStudents &&
                        loadError == null &&
                        allStudents.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: selectedStudentId == null
                              ? null
                              : () async {
                                  try {
                                    await SupabaseService.instance
                                        .enrollStudentInBatch(
                                          batchId: widget.batchId,
                                          studentId: selectedStudentId!,
                                        );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _loadData();
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to add student: $e',
                                          ),
                                          backgroundColor: AppTheme.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add to Batch',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.batchName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Batch Management',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          labelStyle: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_ind_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text('Assignments (${_assignments.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text('Students (${_students.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
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
                  Text('Failed to load', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _loadData, child: const Text('Retry')),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildAssignmentsTab(theme), _buildStudentsTab(theme)],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 1
            ? _showAddStudentDialog
            : _showAssignDialog,
        icon: Icon(
          _tabController.index == 1
              ? Icons.person_add_rounded
              : Icons.add_rounded,
        ),
        label: Text(
          _tabController.index == 1 ? 'Add Student' : 'Assign',
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAssignmentsTab(ThemeData theme) {
    if (_assignments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_ind_outlined,
                  size: 40,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No assignments yet',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Assign courses and tests to this batch',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        final course = assignment['courses'] as Map<String, dynamic>?;
        final test = assignment['tests'] as Map<String, dynamic>?;
        final isCourse = course != null;

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCourse
                      ? AppTheme.secondary.withValues(alpha: 0.12)
                      : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCourse ? Icons.menu_book_rounded : Icons.assignment_rounded,
                  size: 20,
                  color: isCourse ? AppTheme.secondary : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCourse
                          ? (course['title'] as String? ?? 'Untitled Course')
                          : (test?['title'] as String? ?? 'Untitled Test'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isCourse
                            ? AppTheme.secondary.withValues(alpha: 0.1)
                            : AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isCourse ? 'Course' : 'Test',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isCourse
                              ? AppTheme.secondary
                              : AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: AppTheme.error,
                  size: 20,
                ),
                onPressed: () async {
                  final confirmed = await _showDeleteConfirm(
                    context,
                    'Remove Assignment',
                    'Remove this ${isCourse ? 'course' : 'test'} from the batch?',
                  );
                  if (confirmed == true) {
                    await SupabaseService.instance.removeAssignment(
                      assignment['id'] as String,
                    );
                    _loadData();
                  }
                },
                tooltip: 'Remove',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentsTab(ThemeData theme) {
    if (_students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 40,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No students enrolled',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Students can be enrolled from the Students screen',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final enrollment = _students[index];
        final profile =
            enrollment['user_profiles'] as Map<String, dynamic>? ?? {};
        final isActive = enrollment['is_active'] as bool? ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
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
                radius: 18,
                backgroundColor: AppTheme.primaryContainer,
                child: Text(
                  (profile['full_name'] as String? ?? 'S')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
                      profile['full_name'] as String? ?? 'Unknown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      profile['email'] as String? ?? '',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.textMuted.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppTheme.success : AppTheme.textMuted,
                  ),
                ),
              ),
              if (isActive)
                IconButton(
                  icon: const Icon(
                    Icons.person_remove_outlined,
                    color: AppTheme.error,
                    size: 18,
                  ),
                  onPressed: () async {
                    final confirmed = await _showDeleteConfirm(
                      context,
                      'Remove Student',
                      'Remove ${profile['full_name'] ?? 'this student'} from the batch?',
                    );
                    if (confirmed == true) {
                      await SupabaseService.instance.removeStudentFromBatch(
                        batchId: widget.batchId,
                        studentId: profile['id'] as String,
                      );
                      _loadData();
                    }
                  },
                  tooltip: 'Remove from batch',
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Admin Test Questions Screen ──────────────────────────────

class AdminTestQuestionsScreen extends StatefulWidget {
  final String testId;
  final String testTitle;

  const AdminTestQuestionsScreen({
    super.key,
    required this.testId,
    required this.testTitle,
  });

  @override
  State<AdminTestQuestionsScreen> createState() =>
      _AdminTestQuestionsScreenState();
}

class _AdminTestQuestionsScreenState extends State<AdminTestQuestionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final qs = await SupabaseService.instance.fetchTestQuestionsAdmin(
        widget.testId,
      );
      if (mounted) {
        setState(() {
          _questions = qs;
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

  void _addQuestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminQuestionEditorScreen(
          testId: widget.testId,
          sortOrder: _questions.length + 1,
        ),
      ),
    ).then((_) => _loadQuestions());
  }

  void _editQuestion(Map<String, dynamic> question) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminQuestionEditorScreen(
          testId: widget.testId,
          existingQuestion: question,
          sortOrder: question['sort_order'] as int? ?? 1,
        ),
      ),
    ).then((_) => _loadQuestions());
  }

  Future<void> _deleteQuestion(String questionId) async {
    final question = _questions.firstWhere(
      (q) => q['id'] == questionId,
      orElse: () => {},
    );
    final questionIndex = _questions.indexWhere((q) => q['id'] == questionId);
    final questionText =
        question['question_text'] as String? ?? 'this question';
    final displayText = questionText.length > 80
        ? '${questionText.substring(0, 80)}…'
        : questionText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Question?',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withAlpha(51)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${questionIndex + 1}',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1 question will be permanently deleted. This action cannot be undone.',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.instance.deleteQuestion(questionId);
      _loadQuestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.testTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_questions.length} question${_questions.length == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: _loadQuestions,
          ),
        ],
      ),
      body: _isLoading
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
                    'Failed to load questions',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loadQuestions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.quiz_outlined,
                    size: 64,
                    color: AppTheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + to add the first question',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Question'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadQuestions,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return _QuestionListCard(
                    question: q,
                    index: index,
                    onEdit: () => _editQuestion(q),
                    onDelete: () => _deleteQuestion(q['id'] as String),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Question',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Question List Card ───────────────────────────────────────

class _QuestionListCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionListCard({
    required this.question,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLatex = question['has_latex'] as bool? ?? false;
    final hasImage =
        (question['question_image_url'] as String?)?.isNotEmpty == true;
    final difficulty = question['difficulty'] as String? ?? 'medium';
    final subject = question['subject'] as String? ?? '';
    final marks = (question['marks'] as num?)?.toDouble() ?? 1.0;
    final correctOption = question['correct_option'] as int? ?? 0;
    final options = [
      question['option_a'] as String? ?? '',
      question['option_b'] as String? ?? '',
      question['option_c'] as String? ?? '',
      question['option_d'] as String? ?? '',
    ];
    final correctLabels = ['A', 'B', 'C', 'D'];

    Color diffColor = difficulty == 'easy'
        ? AppTheme.success
        : difficulty == 'hard'
        ? AppTheme.error
        : AppTheme.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Mono',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (subject.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    difficulty[0].toUpperCase() + difficulty.substring(1),
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: diffColor,
                    ),
                  ),
                ),
                if (hasLatex) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.functions_rounded,
                          size: 10,
                          color: AppTheme.accent,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Math',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasImage) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.image_rounded,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                ],
                const Spacer(),
                Text(
                  '${marks.toStringAsFixed(marks == marks.roundToDouble() ? 0 : 1)} pts',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            size: 16,
                            color: AppTheme.error,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              question['question_text'] as String? ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Correct: ${correctLabels[correctOption]}. ${options[correctOption]}',
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 11,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
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

// ─── Admin Question Editor Screen ────────────────────────────

class AdminQuestionEditorScreen extends StatefulWidget {
  final String testId;
  final int sortOrder;
  final Map<String, dynamic>? existingQuestion;

  const AdminQuestionEditorScreen({
    super.key,
    required this.testId,
    required this.sortOrder,
    this.existingQuestion,
  });

  @override
  State<AdminQuestionEditorScreen> createState() =>
      _AdminQuestionEditorScreenState();
}

class _AdminQuestionEditorScreenState extends State<AdminQuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = List.generate(
    4,
    (_) => TextEditingController(),
  );

  int _correctOption = 0;
  String _difficulty = 'medium';
  double _marks = 4.0;
  double _negativeMarks = 1.0;
  bool _hasLatex = false;
  bool _isSaving = false;

  String? _questionImageUrl;
  final List<String?> _optionImageUrls = [null, null, null, null];
  bool _uploadingQuestionImage = false;
  final List<bool> _uploadingOptionImage = [false, false, false, false];

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _questionCtrl.addListener(_rebuild);
    for (final c in _optionCtrls) {
      c.addListener(_rebuild);
    }
    final q = widget.existingQuestion;
    if (q != null) {
      _questionCtrl.text = q['question_text'] as String? ?? '';
      _explanationCtrl.text = q['explanation'] as String? ?? '';
      _sectionCtrl.text = q['section_name'] as String? ?? 'Section 1';
      _subjectCtrl.text = q['subject'] as String? ?? '';
      _optionCtrls[0].text = q['option_a'] as String? ?? '';
      _optionCtrls[1].text = q['option_b'] as String? ?? '';
      _optionCtrls[2].text = q['option_c'] as String? ?? '';
      _optionCtrls[3].text = q['option_d'] as String? ?? '';
      _correctOption = q['correct_option'] as int? ?? 0;
      _difficulty = q['difficulty'] as String? ?? 'medium';
      _marks = (q['marks'] as num?)?.toDouble() ?? 4.0;
      _negativeMarks = (q['negative_marks'] as num?)?.toDouble() ?? 1.0;
      _hasLatex = q['has_latex'] as bool? ?? false;
      _questionImageUrl = q['question_image_url'] as String?;
      _optionImageUrls[0] = q['option_a_image_url'] as String?;
      _optionImageUrls[1] = q['option_b_image_url'] as String?;
      _optionImageUrls[2] = q['option_c_image_url'] as String?;
      _optionImageUrls[3] = q['option_d_image_url'] as String?;
    } else {
      _sectionCtrl.text = 'Section 1';
    }
  }

  @override
  void dispose() {
    _questionCtrl.removeListener(_rebuild);
    for (final c in _optionCtrls) {
      c.removeListener(_rebuild);
    }
    _questionCtrl.dispose();
    _explanationCtrl.dispose();
    _sectionCtrl.dispose();
    _subjectCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage({
    required bool isQuestion,
    int optionIndex = 0,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      if (isQuestion) {
        setState(() => _uploadingQuestionImage = true);
      } else {
        setState(() => _uploadingOptionImage[optionIndex] = true);
      }

      final url = await SupabaseService.instance.uploadQuestionImage(
        bytes: bytes,
        fileName: file.name,
      );

      if (mounted) {
        setState(() {
          if (isQuestion) {
            _questionImageUrl = url;
            _uploadingQuestionImage = false;
          } else {
            _optionImageUrls[optionIndex] = url;
            _uploadingOptionImage[optionIndex] = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingQuestionImage = false;
          for (int i = 0; i < 4; i++) {
            _uploadingOptionImage[i] = false;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final data = {
        'test_id': widget.testId,
        'section_name': _sectionCtrl.text.trim().isEmpty
            ? 'Section 1'
            : _sectionCtrl.text.trim(),
        'question_text': _questionCtrl.text.trim(),
        'option_a': _optionCtrls[0].text.trim(),
        'option_b': _optionCtrls[1].text.trim(),
        'option_c': _optionCtrls[2].text.trim(),
        'option_d': _optionCtrls[3].text.trim(),
        'correct_option': _correctOption,
        'explanation': _explanationCtrl.text.trim().isEmpty
            ? null
            : _explanationCtrl.text.trim(),
        'marks': _marks,
        'negative_marks': _negativeMarks,
        'sort_order': widget.sortOrder,
        'difficulty': _difficulty,
        'subject': _subjectCtrl.text.trim().isEmpty
            ? null
            : _subjectCtrl.text.trim(),
        'has_latex': _hasLatex,
        'question_image_url': _questionImageUrl,
        'option_a_image_url': _optionImageUrls[0],
        'option_b_image_url': _optionImageUrls[1],
        'option_c_image_url': _optionImageUrls[2],
        'option_d_image_url': _optionImageUrls[3],
      };

      final existingId = widget.existingQuestion?['id'] as String?;
      if (existingId != null) {
        await SupabaseService.instance.updateQuestion(existingId, data);
      } else {
        await SupabaseService.instance.createQuestion(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingQuestion != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Question' : 'Add Question',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing ? 'Update' : 'Save',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _sectionCtrl,
                      label: 'Section',
                      hint: 'e.g. Physics',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _subjectCtrl,
                      label: 'Subject (optional)',
                      hint: 'e.g. Mechanics',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(
                label: 'Question',
                icon: Icons.help_outline_rounded,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _questionCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            'Enter question text. Use \$...\$ for inline math, \$\$...\$\$ for block math.',
                        hintStyle: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          _ChipButton(
                            icon: Icons.functions_rounded,
                            label: 'Math',
                            isActive: _hasLatex,
                            onTap: () => setState(() => _hasLatex = !_hasLatex),
                            activeColor: AppTheme.accent,
                          ),
                          const Spacer(),
                          if (_uploadingQuestionImage)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          else if (_questionImageUrl != null)
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    _questionImageUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_rounded,
                                      size: 20,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: () =>
                                      setState(() => _questionImageUrl = null),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            )
                          else
                            TextButton.icon(
                              onPressed: () =>
                                  _pickAndUploadImage(isQuestion: true),
                              icon: const Icon(Icons.image_outlined, size: 16),
                              label: const Text(
                                'Add Image',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 12,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_hasLatex && _questionCtrl.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentContainer.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: _MathTextRenderer(text: _questionCtrl.text),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                label: 'Answer Options',
                icon: Icons.list_alt_rounded,
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (i) {
                final labels = ['A', 'B', 'C', 'D'];
                return _OptionEditor(
                  index: i,
                  label: labels[i],
                  controller: _optionCtrls[i],
                  isCorrect: _correctOption == i,
                  imageUrl: _optionImageUrls[i],
                  isUploading: _uploadingOptionImage[i],
                  hasLatex: _hasLatex,
                  onSetCorrect: () => setState(() => _correctOption = i),
                  onPickImage: () =>
                      _pickAndUploadImage(isQuestion: false, optionIndex: i),
                  onRemoveImage: () =>
                      setState(() => _optionImageUrls[i] = null),
                );
              }),
              const SizedBox(height: 20),
              _SectionLabel(
                label: 'Scoring & Difficulty',
                icon: Icons.tune_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      label: 'Marks',
                      value: _marks,
                      onChanged: (v) => setState(() => _marks = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumberField(
                      label: 'Negative Marks',
                      value: _negativeMarks,
                      onChanged: (v) => setState(() => _negativeMarks = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Difficulty:',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ...['easy', 'medium', 'hard'].map((d) {
                    final isSelected = _difficulty == d;
                    Color dColor = d == 'easy'
                        ? AppTheme.success
                        : d == 'hard'
                        ? AppTheme.error
                        : AppTheme.warning;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _difficulty = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? dColor.withValues(alpha: 0.15)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? dColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            d[0].toUpperCase() + d.substring(1),
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? dColor : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(
                label: 'Explanation (optional)',
                icon: Icons.lightbulb_outline_rounded,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _explanationCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Explain the correct answer...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildNumberField({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final ctrl = TextEditingController(
      text: value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString(),
    );
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}

// ─── Option Editor Widget ─────────────────────────────────────

class _OptionEditor extends StatefulWidget {
  final int index;
  final String label;
  final TextEditingController controller;
  final bool isCorrect;
  final String? imageUrl;
  final bool isUploading;
  final bool hasLatex;
  final VoidCallback onSetCorrect;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const _OptionEditor({
    required this.index,
    required this.label,
    required this.controller,
    required this.isCorrect,
    required this.imageUrl,
    required this.isUploading,
    required this.hasLatex,
    required this.onSetCorrect,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  State<_OptionEditor> createState() => _OptionEditorState();
}

class _OptionEditorState extends State<_OptionEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isCorrect ? AppTheme.success : AppTheme.outlineVariant,
          width: widget.isCorrect ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onSetCorrect,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.isCorrect
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.isCorrect
                            ? AppTheme.success
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: 'Option ${widget.label}',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                  ),
                ),
              ),
              if (widget.isUploading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              else if (widget.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          widget.imageUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: widget.onRemoveImage,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.image_outlined,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: widget.onPickImage,
                  tooltip: 'Add image',
                ),
              if (widget.isCorrect)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppTheme.success,
                  ),
                ),
            ],
          ),
          if (widget.hasLatex && widget.controller.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              decoration: BoxDecoration(
                color: AppTheme.accentContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              child: _MathTextRenderer(text: widget.controller.text),
            ),
        ],
      ),
    );
  }
}

// ─── Math Text Renderer ───────────────────────────────────────

class _MathTextRenderer extends StatelessWidget {
  final String text;

  const _MathTextRenderer({required this.text});

  @override
  Widget build(BuildContext context) {
    final segments = _parseLatexSegments(text);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: segments.map((seg) {
        if (seg.isLatex) {
          final processedLatex = _preprocessLatex(seg.content);
          return Math.tex(
            processedLatex,
            textStyle: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
            onErrorFallback: (e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                seg.content,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Mono',
                  fontSize: 13,
                  color: AppTheme.accent,
                ),
              ),
            ),
          );
        }
        return Text(
          seg.content,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            color: AppTheme.textPrimary,
            height: 1.5,
          ),
        );
      }).toList(),
    );
  }

  String _preprocessLatex(String latex) {
    String result = latex.trim();
    result = _convertFunctionToLatex(result, 'sqrt', r'\sqrt');
    result = result.replaceAllMapped(
      RegExp(r'cbrt\(([^)]+)\)'),
      (m) => r'\sqrt[3]{' + m.group(1)! + '}',
    );
    result = result.replaceAllMapped(
      RegExp(r'frac\(([^,]+),([^)]+)\)'),
      (m) => r'\frac{' + m.group(1)!.trim() + '}{' + m.group(2)!.trim() + '}',
    );
    result = result.replaceAllMapped(
      RegExp(r'log_(\w+)'),
      (m) => r'\log_{' + m.group(1)! + '}',
    );
    for (final fn in [
      'sin',
      'cos',
      'tan',
      'cot',
      'sec',
      'csc',
      'log',
      'ln',
      'lim',
      'max',
      'min',
      'exp',
    ]) {
      result = result.replaceAllMapped(
        RegExp('(?<!\\\\)\\b$fn\\b'),
        (m) => '\\$fn',
      );
    }
    result = result.replaceAll('**', '^');
    result = result
        .replaceAll('>=', r'\geq ')
        .replaceAll('<=', r'\leq ')
        .replaceAll('!=', r'\neq ')
        .replaceAll('<>', r'\neq ');
    result = result.replaceAllMapped(
      RegExp(r'(\w)\s*\*\s*(\w)'),
      (m) => '${m.group(1)!}\\cdot ${m.group(2)!}',
    );
    return result;
  }

  String _convertFunctionToLatex(String input, String fnName, String latexCmd) {
    final buffer = StringBuffer();
    int i = 0;
    while (i < input.length) {
      final idx = input.indexOf('$fnName(', i);
      if (idx == -1) {
        buffer.write(input.substring(i));
        break;
      }
      if (idx > 0 && input[idx - 1] == '\\') {
        buffer.write(input.substring(i, idx + fnName.length + 1));
        i = idx + fnName.length + 1;
        continue;
      }
      buffer.write(input.substring(i, idx));
      int depth = 0;
      int start = idx + fnName.length;
      int end = start;
      while (end < input.length) {
        if (input[end] == '(') {
          depth++;
        } else if (input[end] == ')') {
          depth--;
          if (depth == 0) break;
        }
        end++;
      }
      if (depth == 0 && end < input.length) {
        final inner = input.substring(start + 1, end);
        final processedInner = _convertFunctionToLatex(inner, fnName, latexCmd);
        buffer.write('$latexCmd{$processedInner}');
        i = end + 1;
      } else {
        buffer.write('$fnName(');
        i = idx + fnName.length + 1;
      }
    }
    return buffer.toString();
  }

  List<_TextSegment> _parseLatexSegments(String text) {
    final segments = <_TextSegment>[];
    final pattern = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);
    int lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(_TextSegment(text.substring(lastEnd, match.start), false));
      }
      final latexContent = match.group(1) ?? match.group(2) ?? '';
      segments.add(_TextSegment(latexContent, true));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      segments.add(_TextSegment(text.substring(lastEnd), false));
    }
    if (segments.isEmpty) {
      segments.add(_TextSegment(text, false));
    }
    return segments;
  }
}

class _TextSegment {
  final String content;
  final bool isLatex;
  const _TextSegment(this.content, this.isLatex);
}

// ─── Helper Widgets ───────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _ChipButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.15)
              : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? activeColor : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
