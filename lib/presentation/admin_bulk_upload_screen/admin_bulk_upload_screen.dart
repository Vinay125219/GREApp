import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AdminBulkUploadScreen extends StatefulWidget {
  const AdminBulkUploadScreen({super.key});

  @override
  State<AdminBulkUploadScreen> createState() => _AdminBulkUploadScreenState();
}

class _AdminBulkUploadScreenState extends State<AdminBulkUploadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploading = false;
  String? _uploadResult;
  bool _uploadSuccess = false;

  // Questions upload state
  String? _selectedTestId;
  String? _selectedTestTitle;
  List<Map<String, dynamic>> _tests = [];
  bool _loadingTests = true;
  List<Map<String, dynamic>> _parsedQuestions = [];
  String? _questionsFileError;

  // Lessons upload state
  String? _selectedCourseId;
  String? _selectedCourseTitle;
  List<Map<String, dynamic>> _courses = [];
  bool _loadingCourses = true;
  List<Map<String, dynamic>> _parsedLessons = [];
  String? _lessonsFileError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDropdowns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        SupabaseService.instance.fetchAllTestsSimple(),
        SupabaseService.instance.fetchAllCourses(),
      ]);
      if (mounted) {
        setState(() {
          _tests = results[0];
          _courses = results[1];
          _loadingTests = false;
          _loadingCourses = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingTests = false;
          _loadingCourses = false;
        });
      }
    }
  }

  Future<void> _pickQuestionsFile() async {
    setState(() {
      _questionsFileError = null;
      _parsedQuestions = [];
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _questionsFileError = 'Could not read file bytes');
        return;
      }

      final content = utf8.decode(bytes);
      final ext = file.extension?.toLowerCase() ?? '';

      List<Map<String, dynamic>> parsed = [];
      if (ext == 'json') {
        parsed = _parseQuestionsJson(content);
      } else if (ext == 'csv') {
        parsed = _parseQuestionsCsv(content);
      }

      if (parsed.isEmpty) {
        setState(
          () => _questionsFileError = 'No valid questions found in file',
        );
        return;
      }

      setState(() => _parsedQuestions = parsed);
    } catch (e) {
      setState(() => _questionsFileError = 'Parse error: $e');
    }
  }

  List<Map<String, dynamic>> _parseQuestionsJson(String content) {
    final decoded = jsonDecode(content);
    final list = decoded is List
        ? decoded
        : (decoded['questions'] as List? ?? []);
    return list
        .map<Map<String, dynamic>>((item) {
          final m = item as Map<String, dynamic>;
          return {
            'test_id': _selectedTestId,
            'section_name': (m['section_name'] ?? m['section'] ?? 'Section 1')
                .toString(),
            'question_text': (m['question_text'] ?? m['question'] ?? '')
                .toString(),
            'option_a':
                (m['option_a'] ??
                        (m['options'] is List
                            ? (m['options'] as List).elementAtOrNull(0)
                            : null) ??
                        '')
                    .toString(),
            'option_b':
                (m['option_b'] ??
                        (m['options'] is List
                            ? (m['options'] as List).elementAtOrNull(1)
                            : null) ??
                        '')
                    .toString(),
            'option_c':
                (m['option_c'] ??
                        (m['options'] is List
                            ? (m['options'] as List).elementAtOrNull(2)
                            : null) ??
                        '')
                    .toString(),
            'option_d':
                (m['option_d'] ??
                        (m['options'] is List
                            ? (m['options'] as List).elementAtOrNull(3)
                            : null) ??
                        '')
                    .toString(),
            'correct_option': _toInt(m['correct_option'] ?? m['correct'] ?? 0),
            'explanation': m['explanation']?.toString(),
            'marks': _toDouble(m['marks'] ?? 1.0),
            'negative_marks': _toDouble(m['negative_marks'] ?? 0.0),
            'sort_order': _toInt(m['sort_order'] ?? 0),
            'difficulty': (m['difficulty'] ?? 'medium').toString(),
            'subject': m['subject']?.toString(),
            'has_latex': m['has_latex'] == true || m['has_latex'] == 'true',
          };
        })
        .where((q) => (q['question_text'] as String).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _parseQuestionsCsv(String content) {
    final lines = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return [];
    final headers = lines[0]
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList();
    final result = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      if (values.isEmpty) continue;
      final row = <String, String>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      final questionText = row['question_text'] ?? row['question'] ?? '';
      if (questionText.isEmpty) continue;
      result.add({
        'test_id': _selectedTestId,
        'section_name': row['section_name'] ?? row['section'] ?? 'Section 1',
        'question_text': questionText,
        'option_a': row['option_a'] ?? row['a'] ?? '',
        'option_b': row['option_b'] ?? row['b'] ?? '',
        'option_c': row['option_c'] ?? row['c'] ?? '',
        'option_d': row['option_d'] ?? row['d'] ?? '',
        'correct_option':
            int.tryParse(row['correct_option'] ?? row['correct'] ?? '0') ?? 0,
        'explanation': (row['explanation'] ?? '').isEmpty
            ? null
            : row['explanation'],
        'marks': double.tryParse(row['marks'] ?? '1') ?? 1.0,
        'negative_marks': double.tryParse(row['negative_marks'] ?? '0') ?? 0.0,
        'sort_order': int.tryParse(row['sort_order'] ?? '0') ?? 0,
        'difficulty': row['difficulty'] ?? 'medium',
        'subject': (row['subject'] ?? '').isEmpty ? null : row['subject'],
        'has_latex': (row['has_latex'] ?? 'false').toLowerCase() == 'true',
      });
    }
    return result;
  }

  // ── Safe type converters ──────────────────────────────────
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<void> _pickLessonsFile() async {
    setState(() {
      _lessonsFileError = null;
      _parsedLessons = [];
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() => _lessonsFileError = 'Could not read file bytes');
        return;
      }

      final content = utf8.decode(bytes);
      final ext = file.extension?.toLowerCase() ?? '';

      List<Map<String, dynamic>> parsed = [];
      if (ext == 'json') {
        parsed = _parseLessonsJson(content);
      } else if (ext == 'csv') {
        parsed = _parseLessonsCsv(content);
      }

      if (parsed.isEmpty) {
        setState(() => _lessonsFileError = 'No valid lessons found in file');
        return;
      }

      setState(() => _parsedLessons = parsed);
    } catch (e) {
      setState(() => _lessonsFileError = 'Parse error: $e');
    }
  }

  List<Map<String, dynamic>> _parseLessonsJson(String content) {
    final decoded = jsonDecode(content);
    final list = decoded is List
        ? decoded
        : (decoded['lessons'] as List? ?? []);
    final validTypes = {'video', 'text', 'quiz', 'pdf'};
    return list
        .map<Map<String, dynamic>>((item) {
          final m = item as Map<String, dynamic>;
          final rawType = (m['lesson_type'] ?? m['type'] ?? 'text')
              .toString()
              .toLowerCase();
          final lessonType = validTypes.contains(rawType) ? rawType : 'text';
          return {
            'course_id': _selectedCourseId,
            'title': (m['title'] ?? '').toString(),
            'lesson_type': lessonType,
            'content_url': m['content_url']?.toString().isEmpty == true
                ? null
                : m['content_url']?.toString(),
            'duration_mins': m['duration_mins'] != null
                ? _toInt(m['duration_mins'])
                : (m['duration'] != null ? _toInt(m['duration']) : null),
            'sort_order': _toInt(m['sort_order'] ?? 0),
            'is_published':
                m['is_published'] == true || m['is_published'] == 'true',
          };
        })
        .where((l) => (l['title'] as String).isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _parseLessonsCsv(String content) {
    final lines = content
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return [];
    final headers = lines[0]
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList();
    final validTypes = {'video', 'text', 'quiz', 'pdf'};
    final result = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final values = _splitCsvLine(lines[i]);
      if (values.isEmpty) continue;
      final row = <String, String>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j].trim();
      }
      final title = row['title'] ?? '';
      if (title.isEmpty) continue;
      final rawType = (row['lesson_type'] ?? row['type'] ?? 'text')
          .toLowerCase();
      final lessonType = validTypes.contains(rawType) ? rawType : 'text';
      final contentUrl = row['content_url'] ?? '';
      final durationStr = row['duration_mins'] ?? row['duration'] ?? '';
      result.add({
        'course_id': _selectedCourseId,
        'title': title,
        'lesson_type': lessonType,
        'content_url': contentUrl.isEmpty ? null : contentUrl,
        'duration_mins': durationStr.isEmpty ? null : int.tryParse(durationStr),
        'sort_order': int.tryParse(row['sort_order'] ?? '0') ?? 0,
        'is_published':
            (row['is_published'] ?? 'false').toLowerCase() == 'true',
      });
    }
    return result;
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());
    return result;
  }

  Future<void> _uploadQuestions() async {
    if (_selectedTestId == null) {
      _showError('Please select a test first');
      return;
    }
    if (_parsedQuestions.isEmpty) {
      _showError('Please select a file with questions');
      return;
    }

    // Confirmation dialog showing affected item count
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Bulk Upload',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
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
                color: Colors.orange.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.quiz_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_parsedQuestions.length} question${_parsedQuestions.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                          const TextSpan(text: ' will be uploaded to\n'),
                          TextSpan(
                            text: '"$_selectedTestTitle"',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Existing questions in this test will not be removed. New questions will be appended. This action cannot be undone.',
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
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Upload ${_parsedQuestions.length} Question${_parsedQuestions.length == 1 ? '' : 's'}',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isUploading = true;
      _uploadResult = null;
    });
    try {
      final questionsWithTestId = _parsedQuestions
          .map((q) => {...q, 'test_id': _selectedTestId!})
          .toList();
      final count = await SupabaseService.instance.bulkInsertQuestions(
        questionsWithTestId,
      );
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadSuccess = true;
          _uploadResult =
              'Successfully uploaded $count questions to "$_selectedTestTitle"';
          _parsedQuestions = [];
          _questionsFileError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _isUploading = false;
          _uploadSuccess = false;
          _uploadResult = 'Upload failed: $errMsg';
        });
      }
    }
  }

  Future<void> _uploadLessons() async {
    if (_selectedCourseId == null) {
      _showError('Please select a course first');
      return;
    }
    if (_parsedLessons.isEmpty) {
      _showError('Please select a file with lessons');
      return;
    }

    // Confirmation dialog showing affected item count
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Bulk Upload',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
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
                color: Colors.orange.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(51)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${_parsedLessons.length} lesson${_parsedLessons.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.orange,
                            ),
                          ),
                          const TextSpan(text: ' will be uploaded to\n'),
                          TextSpan(
                            text: '"$_selectedCourseTitle"',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Existing lessons in this course will not be removed. New lessons will be appended. This action cannot be undone.',
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
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Upload ${_parsedLessons.length} Lesson${_parsedLessons.length == 1 ? '' : 's'}',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isUploading = true;
      _uploadResult = null;
    });
    try {
      final lessonsWithCourseId = _parsedLessons
          .map((l) => {...l, 'course_id': _selectedCourseId!})
          .toList();
      final count = await SupabaseService.instance.bulkInsertLessons(
        lessonsWithCourseId,
      );
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadSuccess = true;
          _uploadResult =
              'Successfully uploaded $count lessons to "$_selectedCourseTitle"';
          _parsedLessons = [];
          _lessonsFileError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final errMsg = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _isUploading = false;
          _uploadSuccess = false;
          _uploadResult = 'Upload failed: $errMsg';
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                          'Bulk Content Upload',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
                      Tab(text: 'Questions'),
                      Tab(text: 'Lessons'),
                    ],
                  ),
                ],
              ),
            ),
            // Result banner
            if (_uploadResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: _uploadSuccess
                    ? AppTheme.successContainer
                    : AppTheme.errorContainer,
                child: Row(
                  children: [
                    Icon(
                      _uploadSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: _uploadSuccess ? AppTheme.success : AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _uploadResult!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _uploadSuccess
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () => setState(() => _uploadResult = null),
                      color: _uploadSuccess ? AppTheme.success : AppTheme.error,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildQuestionsTab(theme), _buildLessonsTab(theme)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format guide
          _FormatGuideCard(
            title: 'Questions CSV/JSON Format',
            fields: const [
              'question_text (required)',
              'option_a, option_b, option_c, option_d',
              'correct_option (0-3)',
              'section_name, subject, difficulty',
              'marks, negative_marks, explanation',
            ],
            exampleJson:
                '{"question_text":"What is 2+2?","option_a":"3","option_b":"4","option_c":"5","option_d":"6","correct_option":1,"subject":"Math","marks":1}',
          ),
          const SizedBox(height: 16),
          // Select test
          Text(
            'Select Test',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _loadingTests
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _tests.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    'No tests found. Create a test first.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedTestId,
                  decoration: InputDecoration(
                    hintText: 'Choose a test',
                    prefixIcon: const Icon(
                      Icons.assignment_rounded,
                      color: AppTheme.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                  ),
                  items: _tests.map((t) {
                    return DropdownMenuItem<String>(
                      value: t['id'] as String,
                      child: Text(
                        t['title'] as String? ?? 'Untitled',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTestId = val;
                      _selectedTestTitle =
                          _tests.firstWhere((t) => t['id'] == val)['title']
                              as String?;
                    });
                  },
                ),
          const SizedBox(height: 16),
          // File picker
          Text(
            'Upload File',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickQuestionsFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _parsedQuestions.isNotEmpty
                      ? AppTheme.success
                      : AppTheme.outline,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _parsedQuestions.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 36,
                    color: _parsedQuestions.isNotEmpty
                        ? AppTheme.success
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _parsedQuestions.isNotEmpty
                        ? '${_parsedQuestions.length} questions ready to upload'
                        : 'Tap to select CSV or JSON file',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _parsedQuestions.isNotEmpty
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_questionsFileError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _questionsFileError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_parsedQuestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Preview first 3
            Text(
              'Preview (first ${_parsedQuestions.length > 3 ? 3 : _parsedQuestions.length} of ${_parsedQuestions.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._parsedQuestions
                .take(3)
                .map(
                  (q) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['question_text'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A: ${q['option_a']}  B: ${q['option_b']}',
                          style: theme.textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Correct: Option ${['A', 'B', 'C', 'D'][q['correct_option'] as int? ?? 0]}  |  Subject: ${q['subject'] ?? 'N/A'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_isUploading ||
                      _parsedQuestions.isEmpty ||
                      _selectedTestId == null)
                  ? null
                  : _uploadQuestions,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(
                _isUploading
                    ? 'Uploading...'
                    : 'Upload ${_parsedQuestions.length} Questions',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormatGuideCard(
            title: 'Lessons CSV/JSON Format',
            fields: const [
              'title (required)',
              'lesson_type: video | text | pdf | quiz',
              'content_url (optional)',
              'duration_mins (optional)',
              'sort_order, is_published',
            ],
            exampleJson:
                '{"title":"Introduction","lesson_type":"video","content_url":"https://...","duration_mins":15,"sort_order":1}',
          ),
          const SizedBox(height: 16),
          Text(
            'Select Course',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _loadingCourses
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : _courses.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Text(
                    'No courses found. Create a course first.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  decoration: InputDecoration(
                    hintText: 'Choose a course',
                    prefixIcon: const Icon(
                      Icons.menu_book_rounded,
                      color: AppTheme.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                  ),
                  items: _courses.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'] as String,
                      child: Text(
                        c['title'] as String? ?? 'Untitled',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCourseId = val;
                      _selectedCourseTitle =
                          _courses.firstWhere((c) => c['id'] == val)['title']
                              as String?;
                    });
                  },
                ),
          const SizedBox(height: 16),
          Text(
            'Upload File',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickLessonsFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _parsedLessons.isNotEmpty
                      ? AppTheme.success
                      : AppTheme.outline,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _parsedLessons.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 36,
                    color: _parsedLessons.isNotEmpty
                        ? AppTheme.success
                        : AppTheme.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _parsedLessons.isNotEmpty
                        ? '${_parsedLessons.length} lessons ready to upload'
                        : 'Tap to select CSV or JSON file',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _parsedLessons.isNotEmpty
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_lessonsFileError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _lessonsFileError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_parsedLessons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Preview (first ${_parsedLessons.length > 3 ? 3 : _parsedLessons.length} of ${_parsedLessons.length})',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._parsedLessons
                .take(3)
                .map(
                  (l) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _lessonTypeIcon(
                            l['lesson_type'] as String? ?? 'text',
                          ),
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l['title'] as String? ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${l['lesson_type']} • ${l['duration_mins'] ?? '—'} mins',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  (_isUploading ||
                      _parsedLessons.isEmpty ||
                      _selectedCourseId == null)
                  ? null
                  : _uploadLessons,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 18),
              label: Text(
                _isUploading
                    ? 'Uploading...'
                    : 'Upload ${_parsedLessons.length} Lessons',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _lessonTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      default:
        return Icons.article_rounded;
    }
  }
}

class _FormatGuideCard extends StatelessWidget {
  final String title;
  final List<String> fields;
  final String exampleJson;

  const _FormatGuideCard({
    required this.title,
    required this.fields,
    required this.exampleJson,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.info,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.info,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...fields.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(color: AppTheme.info, fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Example JSON:',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.info,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              exampleJson,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
