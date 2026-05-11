import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;
import './local_cache_service.dart';
import './offline_queue_service.dart';

// ─── Data Models ─────────────────────────────────────────────

class StudentKpiData {
  final int testsTaken;
  final double accuracy;
  final int openDoubts;
  final int studyStreakDays;

  const StudentKpiData({
    required this.testsTaken,
    required this.accuracy,
    required this.openDoubts,
    required this.studyStreakDays,
  });
}

class CourseProgressItem {
  final String id;
  final String title;
  final int totalLessons;
  final int lessonsCompleted;
  final DateTime? lastAccessedAt;

  const CourseProgressItem({
    required this.id,
    required this.title,
    required this.totalLessons,
    required this.lessonsCompleted,
    this.lastAccessedAt,
  });

  double get progressPercent => totalLessons > 0
      ? (lessonsCompleted / totalLessons).clamp(0.0, 1.0)
      : 0.0;

  factory CourseProgressItem.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>? ?? {};
    return CourseProgressItem(
      id: json['course_id'] as String? ?? '',
      title: course['title'] as String? ?? 'Untitled Course',
      totalLessons: (course['total_lessons'] as int?) ?? 0,
      lessonsCompleted: (json['lessons_completed'] as int?) ?? 0,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.tryParse(json['last_accessed_at'] as String)
          : null,
    );
  }
}

class UpcomingTestItem {
  final String id;
  final String title;
  final DateTime? scheduledAt;
  final int durationMins;

  const UpcomingTestItem({
    required this.id,
    required this.title,
    this.scheduledAt,
    required this.durationMins,
  });

  Duration? get timeUntil => scheduledAt?.difference(DateTime.now());

  factory UpcomingTestItem.fromJson(Map<String, dynamic> json) {
    return UpcomingTestItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Test',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      durationMins: (json['duration_mins'] as int?) ?? 60,
    );
  }
}

class TestQuestion {
  final String id;
  final String sectionName;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;
  final double marks;
  final double negativeMarks;
  final int sortOrder;
  final String difficulty;
  final String? subject;
  // Compatibility fields
  final int questionNumber;
  final bool hasLatex;
  // Image support
  final String? questionImageUrl;
  final List<String?> optionImageUrls;

  const TestQuestion({
    required this.id,
    required this.sectionName,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
    required this.marks,
    required this.negativeMarks,
    required this.sortOrder,
    required this.difficulty,
    this.subject,
    this.questionNumber = 1,
    this.hasLatex = false,
    this.questionImageUrl,
    this.optionImageUrls = const [null, null, null, null],
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    final sortOrder = (json['sort_order'] as int?) ?? 0;
    return TestQuestion(
      id: json['id'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? 'Section 1',
      questionText: json['question_text'] as String? ?? '',
      options: [
        json['option_a'] as String? ?? '',
        json['option_b'] as String? ?? '',
        json['option_c'] as String? ?? '',
        json['option_d'] as String? ?? '',
      ],
      correctOptionIndex: (json['correct_option'] as int?) ?? 0,
      explanation: json['explanation'] as String?,
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      negativeMarks: (json['negative_marks'] as num?)?.toDouble() ?? 0.0,
      sortOrder: sortOrder,
      difficulty: json['difficulty'] as String? ?? 'medium',
      subject: json['subject'] as String?,
      questionNumber: sortOrder,
      hasLatex: json['has_latex'] as bool? ?? false,
      questionImageUrl: json['question_image_url'] as String?,
      optionImageUrls: [
        json['option_a_image_url'] as String?,
        json['option_b_image_url'] as String?,
        json['option_c_image_url'] as String?,
        json['option_d_image_url'] as String?,
      ],
    );
  }
}

class TestAttemptResult {
  final String attemptId;
  final String testId;
  final String testTitle;
  final double score;
  final double totalMarks;
  final int totalQuestions;
  final int attempted;
  final int correct;
  final int incorrect;
  final int skipped;
  final Map<String, int> selectedAnswers;
  final List<TestQuestion> questions;
  final DateTime submittedAt;

  const TestAttemptResult({
    required this.attemptId,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.totalMarks,
    required this.totalQuestions,
    required this.attempted,
    required this.correct,
    required this.incorrect,
    required this.skipped,
    required this.selectedAnswers,
    required this.questions,
    required this.submittedAt,
  });

  double get percentage => totalMarks > 0 ? (score / totalMarks) * 100 : 0;
  double get accuracy => attempted > 0 ? (correct / attempted) * 100 : 0;
}

class DoubtItem {
  final String id;
  final String title;
  final String body;
  final String status;
  final String? answerText;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final String? courseTitle;

  const DoubtItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    this.answerText,
    required this.createdAt,
    this.answeredAt,
    this.courseTitle,
  });

  factory DoubtItem.fromJson(Map<String, dynamic> json) {
    final course = json['courses'] as Map<String, dynamic>?;
    return DoubtItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      answerText: json['answer_text'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      answeredAt: json['answered_at'] != null
          ? DateTime.tryParse(json['answered_at'] as String)
          : null,
      courseTitle: course?['title'] as String?,
    );
  }
}

// ─── Notifications ────────────────────────────────────────

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['notification_type'] as String? ?? 'system',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }
}

class AdminKpiData {
  final int totalStudents;
  final int activeBatches;
  final int pendingDoubts;
  final int totalCourses;
  final int testsPublished;
  final int totalLessons;

  const AdminKpiData({
    required this.totalStudents,
    required this.activeBatches,
    required this.pendingDoubts,
    required this.totalCourses,
    required this.testsPublished,
    required this.totalLessons,
  });
}

class SupabaseErrorLog {
  final String operation;
  final Object error;
  final StackTrace stackTrace;
  final DateTime timestamp;
  final int attempt;

  const SupabaseErrorLog({
    required this.operation,
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.attempt,
  });

  @override
  String toString() =>
      '[SupabaseErrorLog] operation=$operation, attempt=$attempt, error=$error, timestamp=$timestamp';
}

class LessonItem {
  final String id;
  final String title;
  final String type;
  final String? contentUrl;
  final int? durationMins;
  final bool isCompleted;
  final bool isLocked;
  final int sortOrder;

  const LessonItem({
    required this.id,
    required this.title,
    required this.type,
    this.contentUrl,
    this.durationMins,
    required this.isCompleted,
    required this.isLocked,
    required this.sortOrder,
  });

  factory LessonItem.fromJson(
    Map<String, dynamic> json, {
    bool completed = false,
  }) {
    // Map DB lesson_type to UI type
    String rawType = json['lesson_type'] as String? ?? 'text';
    String uiType;
    switch (rawType) {
      case 'video':
        uiType = 'video';
        break;
      case 'pdf':
        uiType = 'pdf';
        break;
      case 'text':
        uiType = 'notes';
        break;
      case 'quiz':
        uiType = 'notes';
        break;
      default:
        uiType = 'notes';
    }
    return LessonItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Lesson',
      type: uiType,
      contentUrl: json['content_url'] as String?,
      durationMins: json['duration_mins'] as int?,
      isCompleted: completed,
      isLocked: !(json['is_published'] as bool? ?? false),
      sortOrder: (json['sort_order'] as int?) ?? 0,
    );
  }

  String get duration => durationMins != null ? '${durationMins}m' : '—';
}

// ─── Drip Content Models ──────────────────────────────────

enum DripContentType { lesson, test }

class DripContentItem {
  final String id;
  final String title;
  final DripContentType type;
  final DateTime? scheduledAt;
  final bool isReleased;
  final bool isCompleted;
  final String contentType;
  final int? durationMins;

  const DripContentItem({
    required this.id,
    required this.title,
    required this.type,
    this.scheduledAt,
    required this.isReleased,
    required this.isCompleted,
    required this.contentType,
    this.durationMins,
  });

  bool get isUpcoming => !isReleased && scheduledAt != null;

  Duration? get timeUntilRelease => scheduledAt != null && !isReleased
      ? scheduledAt!.difference(DateTime.now())
      : null;
}

// ─── Service ─────────────────────────────────────────────────

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  // Compile-time fallbacks (populated when built with --dart-define)
  static const String _envUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _envAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Runtime-resolved values (populated from env.json on web)
  static String _resolvedUrl = _envUrl;
  static String _resolvedAnonKey = _envAnonKey;

  static bool _initialized = false;

  /// Loads env.json from assets and extracts SUPABASE_URL / SUPABASE_ANON_KEY.
  /// Falls back to dart-define values if the file is missing or keys are absent.
  static Future<void> _loadEnvJson() async {
    try {
      final raw = await rootBundle.loadString('env.json');
      final map = json.decode(raw) as Map<String, dynamic>;
      final url = map['SUPABASE_URL'] as String? ?? '';
      final key = map['SUPABASE_ANON_KEY'] as String? ?? '';
      if (url.isNotEmpty) _resolvedUrl = url;
      if (key.isNotEmpty) _resolvedAnonKey = key;
      debugPrint('[SupabaseService] Loaded credentials from env.json');
    } catch (e) {
      debugPrint(
        '[SupabaseService] env.json not loaded ($e), using dart-define values',
      );
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    // Try to load from env.json first (runtime injection on web)
    if (_resolvedUrl.isEmpty || _resolvedAnonKey.isEmpty) {
      await _loadEnvJson();
    }

    if (_resolvedUrl.isEmpty || _resolvedAnonKey.isEmpty) {
      debugPrint(
        '[SupabaseService] WARNING: SUPABASE_URL or SUPABASE_ANON_KEY is empty.',
      );
      return;
    }

    try {
      await Supabase.initialize(url: _resolvedUrl, anonKey: _resolvedAnonKey);
      _initialized = true;
      debugPrint('[SupabaseService] Initialized successfully.');
    } catch (e) {
      if (e.toString().contains('already been initialized') ||
          e.toString().contains('already initialized')) {
        _initialized = true;
        debugPrint('[SupabaseService] Already initialized, reusing instance.');
      } else {
        debugPrint('[SupabaseService] Initialization error: $e');
        rethrow;
      }
    }
  }

  static bool get isInitialized => _initialized;

  SupabaseClient get client => Supabase.instance.client;

  String? get currentUserId => client.auth.currentUser?.id;

  // ── Retry / Backoff ──────────────────────────────────────

  /// Structured error log buffer (last 100 entries)
  static final List<SupabaseErrorLog> errorLog = [];
  static const int _maxLogEntries = 100;

  static void _logError(SupabaseErrorLog entry) {
    errorLog.add(entry);
    if (errorLog.length > _maxLogEntries) {
      errorLog.removeAt(0);
    }
    debugPrint(entry.toString());
  }

  /// Executes [fn] with exponential backoff retry.
  /// - maxAttempts: total tries (default 3)
  /// - baseDelayMs: initial delay in ms (default 300)
  /// - Delay doubles each retry with ±20% jitter
  /// - Retries only on network/server errors, not auth/RLS errors
  Future<T> withRetry<T>(
    String operationName,
    Future<T> Function() fn, {
    int maxAttempts = 3,
    int baseDelayMs = 300,
  }) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await fn();
      } catch (e, st) {
        final log = SupabaseErrorLog(
          operation: operationName,
          error: e,
          stackTrace: st,
          timestamp: DateTime.now(),
          attempt: attempt,
        );
        _logError(log);

        // Don't retry auth/RLS/client errors
        final errStr = e.toString().toLowerCase();
        final isRetryable =
            !errStr.contains('jwt') &&
            !errStr.contains('unauthorized') &&
            !errStr.contains('forbidden') &&
            !errStr.contains('row-level') &&
            !errStr.contains('permission') &&
            !errStr.contains('not authenticated') &&
            !errStr.contains('invalid_credentials');

        if (!isRetryable || attempt >= maxAttempts) {
          rethrow;
        }

        // Exponential backoff with ±20% jitter
        final jitter = (math.Random().nextDouble() * 0.4) - 0.2; // -0.2 to +0.2
        final delayMs = (baseDelayMs * math.pow(2, attempt - 1) * (1 + jitter))
            .round();
        debugPrint(
          '[SupabaseService] Retrying $operationName in ${delayMs}ms '
          '(attempt $attempt/$maxAttempts)',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  // ── Student KPI ──────────────────────────────────────────

  Future<StudentKpiData> fetchStudentKpi() async {
    return withRetry('fetchStudentKpi', () async {
      final uid = currentUserId;
      if (uid == null) {
        return const StudentKpiData(
          testsTaken: 0,
          accuracy: 0,
          openDoubts: 0,
          studyStreakDays: 0,
        );
      }

      final attemptsResp = await client
          .from('test_attempts')
          .select('id, score, total_marks')
          .eq('student_id', uid)
          .inFilter('status', ['submitted', 'graded']);

      final testsTaken = attemptsResp.length;
      double accuracy = 0.0;
      final attempts = attemptsResp as List<dynamic>;
      if (attempts.isNotEmpty) {
        double totalPct = 0;
        int validCount = 0;
        for (final a in attempts) {
          final score = (a['score'] as num?)?.toDouble() ?? 0;
          final total = (a['total_marks'] as num?)?.toDouble() ?? 0;
          if (total > 0) {
            totalPct += (score / total) * 100;
            validCount++;
          }
        }
        if (validCount > 0) accuracy = totalPct / validCount;
      }

      final streakResp = await client
          .from('test_attempts')
          .select('started_at')
          .eq('student_id', uid)
          .gte(
            'started_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final streakDays = _calculateStreak(streakResp as List<dynamic>);

      int openDoubts = 0;
      try {
        final doubtsResp = await client
            .from('doubts')
            .select('id')
            .eq('student_id', uid)
            .eq('status', 'open');
        openDoubts = (doubtsResp as List<dynamic>).length;
      } catch (_) {}

      return StudentKpiData(
        testsTaken: testsTaken,
        accuracy: accuracy,
        openDoubts: openDoubts,
        studyStreakDays: streakDays,
      );
    });
  }

  int _calculateStreak(List<dynamic> attempts) {
    if (attempts.isEmpty) return 0;
    final days = <String>{};
    for (final a in attempts) {
      final dt = DateTime.tryParse(a['started_at'] as String? ?? '');
      if (dt != null) {
        days.add('${dt.year}-${dt.month}-${dt.day}');
      }
    }
    int streak = 0;
    DateTime check = DateTime.now();
    while (days.contains('${check.year}-${check.month}-${check.day}')) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Course Progress ──────────────────────────────────────

  Future<List<CourseProgressItem>> fetchCourseProgress({
    int page = 0,
    int pageSize = 10,
  }) async {
    return withRetry('fetchCourseProgress', () async {
      final uid = currentUserId;
      if (uid == null) return [];

      // Step 1: Get all batch IDs the student is enrolled in
      final batchResp = await client
          .from('batch_enrollments')
          .select('batch_id')
          .eq('student_id', uid)
          .eq('is_active', true);

      final batchIds = (batchResp as List<dynamic>)
          .map((e) => e['batch_id'] as String)
          .toList();

      // Step 2: Fetch existing enrollment records (courses already started)
      final enrollResp = await client
          .from('course_enrollments')
          .select(
            'course_id, lessons_completed, last_accessed_at, courses(id, title, total_lessons, is_published)',
          )
          .eq('student_id', uid);

      final enrolledCourseIds = <String>{};
      final enrolledItems = <CourseProgressItem>[];
      for (final e in (enrollResp as List<dynamic>)) {
        final map = e as Map<String, dynamic>;
        final course = map['courses'] as Map<String, dynamic>?;
        // Only include if the course is published
        if (course != null && (course['is_published'] as bool? ?? false)) {
          enrolledCourseIds.add(map['course_id'] as String? ?? '');
          enrolledItems.add(CourseProgressItem.fromJson(map));
        }
      }

      // Step 3: Fetch published courses from student's batches that they haven't started
      List<CourseProgressItem> unenrolledItems = [];
      if (batchIds.isNotEmpty) {
        final publishedResp = await client
            .from('courses')
            .select('id, title, total_lessons')
            .eq('is_published', true)
            .inFilter('batch_id', batchIds);

        for (final c in (publishedResp as List<dynamic>)) {
          final map = c as Map<String, dynamic>;
          final courseId = map['id'] as String? ?? '';
          if (!enrolledCourseIds.contains(courseId)) {
            unenrolledItems.add(
              CourseProgressItem(
                id: courseId,
                title: map['title'] as String? ?? 'Untitled Course',
                totalLessons: (map['total_lessons'] as int?) ?? 0,
                lessonsCompleted: 0,
                lastAccessedAt: null,
              ),
            );
          }
        }
      }

      // Step 4: Also fetch published courses with no batch (global courses)
      final globalResp = await client
          .from('courses')
          .select('id, title, total_lessons')
          .eq('is_published', true)
          .isFilter('batch_id', null);

      for (final c in (globalResp as List<dynamic>)) {
        final map = c as Map<String, dynamic>;
        final courseId = map['id'] as String? ?? '';
        if (!enrolledCourseIds.contains(courseId) &&
            !unenrolledItems.any((i) => i.id == courseId)) {
          unenrolledItems.add(
            CourseProgressItem(
              id: courseId,
              title: map['title'] as String? ?? 'Untitled Course',
              totalLessons: (map['total_lessons'] as int?) ?? 0,
              lessonsCompleted: 0,
              lastAccessedAt: null,
            ),
          );
        }
      }

      // Merge: enrolled (sorted by last accessed) first, then unenrolled
      enrolledItems.sort((a, b) {
        if (a.lastAccessedAt == null && b.lastAccessedAt == null) return 0;
        if (a.lastAccessedAt == null) return 1;
        if (b.lastAccessedAt == null) return -1;
        return b.lastAccessedAt!.compareTo(a.lastAccessedAt!);
      });

      final allItems = [...enrolledItems, ...unenrolledItems];

      // Apply pagination
      final from = page * pageSize;
      if (from >= allItems.length) return [];
      final to = (from + pageSize).clamp(0, allItems.length);
      return allItems.sublist(from, to);
    });
  }

  // ── Upcoming Tests ───────────────────────────────────────

  Future<UpcomingTestItem?> fetchNextUpcomingTest() async {
    return withRetry('fetchNextUpcomingTest', () async {
      final uid = currentUserId;
      if (uid == null) return null;

      final batchResp = await client
          .from('batch_enrollments')
          .select('batch_id')
          .eq('student_id', uid)
          .eq('is_active', true);

      final batchIds = (batchResp as List<dynamic>)
          .map((e) => e['batch_id'] as String)
          .toList();

      // Also include published tests with no batch (global tests)
      // Fetch tests that are published and either:
      //   - have no scheduled_at (available immediately), OR
      //   - have scheduled_at >= now (upcoming), OR
      //   - have scheduled_at in the past (already available)
      // Priority: upcoming scheduled tests first, then unscheduled
      List<dynamic> list = [];

      if (batchIds.isNotEmpty) {
        // Upcoming scheduled tests in student's batches
        final scheduledResp = await client
            .from('tests')
            .select('id, title, scheduled_at, duration_mins')
            .eq('status', 'published')
            .gte('scheduled_at', DateTime.now().toIso8601String())
            .inFilter('batch_id', batchIds)
            .order('scheduled_at', ascending: true)
            .limit(1);
        list = scheduledResp as List<dynamic>;
      }

      if (list.isEmpty) {
        // Try published tests without scheduled_at in student's batches
        if (batchIds.isNotEmpty) {
          final unscheduledResp = await client
              .from('tests')
              .select('id, title, scheduled_at, duration_mins')
              .eq('status', 'published')
              .isFilter('scheduled_at', null)
              .inFilter('batch_id', batchIds)
              .order('created_at', ascending: false)
              .limit(1);
          list = unscheduledResp as List<dynamic>;
        }
      }

      if (list.isEmpty) {
        // Try global published tests (no batch restriction)
        final globalResp = await client
            .from('tests')
            .select('id, title, scheduled_at, duration_mins')
            .eq('status', 'published')
            .isFilter('batch_id', null)
            .order('created_at', ascending: false)
            .limit(1);
        list = globalResp as List<dynamic>;
      }

      if (list.isEmpty) return null;
      return UpcomingTestItem.fromJson(list.first as Map<String, dynamic>);
    });
  }

  Future<List<UpcomingTestItem>> fetchUpcomingTests({
    int page = 0,
    int pageSize = 5,
  }) async {
    return withRetry('fetchUpcomingTests', () async {
      final uid = currentUserId;
      if (uid == null) return [];

      final batchResp = await client
          .from('batch_enrollments')
          .select('batch_id')
          .eq('student_id', uid)
          .eq('is_active', true);

      final batchIds = (batchResp as List<dynamic>)
          .map((e) => e['batch_id'] as String)
          .toList();

      final from = page * pageSize;
      final to = from + pageSize - 1;

      final List<UpcomingTestItem> allTests = [];

      if (batchIds.isNotEmpty) {
        // Upcoming scheduled tests in student's batches
        final scheduledResp = await client
            .from('tests')
            .select('id, title, scheduled_at, duration_mins')
            .eq('status', 'published')
            .gte('scheduled_at', DateTime.now().toIso8601String())
            .inFilter('batch_id', batchIds)
            .order('scheduled_at', ascending: true);
        allTests.addAll(
          (scheduledResp as List<dynamic>).map(
            (e) => UpcomingTestItem.fromJson(e as Map<String, dynamic>),
          ),
        );

        // Published tests without scheduled_at in student's batches
        final unscheduledResp = await client
            .from('tests')
            .select('id, title, scheduled_at, duration_mins')
            .eq('status', 'published')
            .isFilter('scheduled_at', null)
            .inFilter('batch_id', batchIds)
            .order('created_at', ascending: false);
        allTests.addAll(
          (unscheduledResp as List<dynamic>).map(
            (e) => UpcomingTestItem.fromJson(e as Map<String, dynamic>),
          ),
        );
      }

      // Global published tests (no batch restriction)
      final globalResp = await client
          .from('tests')
          .select('id, title, scheduled_at, duration_mins')
          .eq('status', 'published')
          .isFilter('batch_id', null)
          .order('created_at', ascending: false);
      allTests.addAll(
        (globalResp as List<dynamic>).map(
          (e) => UpcomingTestItem.fromJson(e as Map<String, dynamic>),
        ),
      );

      // Deduplicate by id
      final seen = <String>{};
      final unique = allTests.where((t) => seen.add(t.id)).toList();

      if (from >= unique.length) return [];
      final end = (from + pageSize).clamp(0, unique.length);
      return unique.sublist(from, end);
    });
  }

  // ── Test Questions ───────────────────────────────────────

  Future<List<TestQuestion>> fetchTestQuestions(String testId) async {
    return withRetry('fetchTestQuestions', () async {
      final resp = await client
          .from('questions')
          .select('*')
          .eq('test_id', testId)
          .order('sort_order', ascending: true);

      return (resp as List<dynamic>)
          .map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  /// Fetch all questions for a test (admin view — raw map for editing)
  Future<List<Map<String, dynamic>>> fetchTestQuestionsAdmin(
    String testId,
  ) async {
    return withRetry('fetchTestQuestionsAdmin', () async {
      final resp = await client
          .from('questions')
          .select('*')
          .eq('test_id', testId)
          .order('sort_order', ascending: true);
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  /// Create a new question
  Future<void> createQuestion(Map<String, dynamic> data) async {
    return withRetry('createQuestion', () async {
      await client.from('questions').insert(data);
    });
  }

  /// Update an existing question
  Future<void> updateQuestion(
    String questionId,
    Map<String, dynamic> data,
  ) async {
    return withRetry('updateQuestion', () async {
      await client
          .from('questions')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', questionId);
    });
  }

  /// Delete a question
  Future<void> deleteQuestion(String questionId) async {
    return withRetry('deleteQuestion', () async {
      await client.from('questions').delete().eq('id', questionId);
    });
  }

  /// Upload an image to the question-images storage bucket.
  /// Returns the public URL of the uploaded image.
  Future<String> uploadQuestionImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    return withRetry('uploadQuestionImage', () async {
      final ext = fileName.split('.').last.toLowerCase();
      final mimeExt = ext == 'jpg' ? 'jpeg' : ext;
      final path =
          'questions/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage
          .from('question-images')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              contentType: 'image/$mimeExt',
              upsert: true,
            ),
          );
      final publicUrl = client.storage
          .from('question-images')
          .getPublicUrl(path);
      return publicUrl;
    });
  }

  /// Upload a PDF to the course-materials storage bucket.
  /// Returns the public URL of the uploaded PDF.
  Future<String> uploadCoursePdf({
    required List<int> bytes,
    required String fileName,
  }) async {
    return withRetry('uploadCoursePdf', () async {
      final path = 'lessons/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage
          .from('course-materials')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(
              contentType: 'application/pdf',
              upsert: true,
            ),
          );
      final publicUrl = client.storage
          .from('course-materials')
          .getPublicUrl(path);
      return publicUrl;
    });
  }

  /// Upload a video file to the course-materials storage bucket.
  /// Returns the public URL of the uploaded video.
  Future<String> uploadCourseVideo({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    return withRetry('uploadCourseVideo', () async {
      final path = 'videos/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await client.storage
          .from('course-materials')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );
      final publicUrl = client.storage
          .from('course-materials')
          .getPublicUrl(path);
      return publicUrl;
    });
  }

  Future<Map<String, dynamic>?> fetchTestById(String testId) async {
    return withRetry('fetchTestById', () async {
      final resp = await client
          .from('tests')
          .select(
            'id, title, description, duration_mins, total_marks, passing_marks',
          )
          .eq('id', testId)
          .maybeSingle();
      return resp;
    });
  }

  Future<String> startTestAttempt(String testId) async {
    return withRetry('startTestAttempt', () async {
      final uid = currentUserId;
      if (uid == null) throw Exception('Not authenticated');

      final resp = await client
          .from('test_attempts')
          .insert({
            'student_id': uid,
            'test_id': testId,
            'status': 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return resp['id'] as String;
    });
  }

  Future<TestAttemptResult> submitTestAttempt({
    required String attemptId,
    required String testId,
    required List<TestQuestion> questions,
    required Map<int, int?> selectedAnswers,
    required int antiCheatViolations,
  }) async {
    return withRetry('submitTestAttempt', () async {
      int correct = 0;
      int incorrect = 0;
      int skipped = 0;
      double score = 0;
      double totalMarks = 0;
      final answersJson = <String, dynamic>{};

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        totalMarks += q.marks;
        final selected = selectedAnswers[i];
        answersJson[q.id] = selected;

        if (selected == null) {
          skipped++;
        } else if (selected == q.correctOptionIndex) {
          correct++;
          score += q.marks;
        } else {
          incorrect++;
          score -= q.negativeMarks;
        }
      }
      if (score < 0) score = 0;

      final testData = await fetchTestById(testId);
      final testTitle = testData?['title'] as String? ?? 'Test';

      await client
          .from('test_attempts')
          .update({
            'score': score,
            'total_marks': totalMarks,
            'status': 'submitted',
            'submitted_at': DateTime.now().toIso8601String(),
            'answers_json': answersJson,
            'anti_cheat_violations': antiCheatViolations,
          })
          .eq('id', attemptId);

      final selectedAnswersStr = <String, int>{};
      for (final entry in selectedAnswers.entries) {
        if (entry.value != null) {
          selectedAnswersStr[questions[entry.key].id] = entry.value!;
        }
      }

      return TestAttemptResult(
        attemptId: attemptId,
        testId: testId,
        testTitle: testTitle,
        score: score,
        totalMarks: totalMarks,
        totalQuestions: questions.length,
        attempted: correct + incorrect,
        correct: correct,
        incorrect: incorrect,
        skipped: skipped,
        selectedAnswers: selectedAnswersStr,
        questions: questions,
        submittedAt: DateTime.now(),
      );
    });
  }

  // ── Lessons ──────────────────────────────────────────────

  /// Fetch a test attempt by its ID for admin review.
  /// Returns a [TestAttemptResult] reconstructed from the stored attempt data.
  Future<TestAttemptResult?> fetchTestAttemptForAdmin(String attemptId) async {
    return withRetry('fetchTestAttemptForAdmin', () async {
      final attemptResp = await client
          .from('test_attempts')
          .select(
            'id, test_id, student_id, score, total_marks, answers_json, submitted_at, anti_cheat_violations',
          )
          .eq('id', attemptId)
          .maybeSingle();

      if (attemptResp == null) return null;

      final testId = attemptResp['test_id'] as String;
      final testData = await fetchTestById(testId);
      final testTitle = testData?['title'] as String? ?? 'Test';
      final questions = await fetchTestQuestions(testId);

      final answersJson =
          attemptResp['answers_json'] as Map<String, dynamic>? ?? {};
      final selectedAnswers = <String, int>{};
      for (final entry in answersJson.entries) {
        if (entry.value != null) {
          selectedAnswers[entry.key] = (entry.value as num).toInt();
        }
      }

      int correct = 0, incorrect = 0, skipped = 0;
      for (final q in questions) {
        final selected = selectedAnswers[q.id];
        if (selected == null) {
          skipped++;
        } else if (selected == q.correctOptionIndex) {
          correct++;
        } else {
          incorrect++;
        }
      }

      final score = (attemptResp['score'] as num?)?.toDouble() ?? 0.0;
      final totalMarks =
          (attemptResp['total_marks'] as num?)?.toDouble() ?? 0.0;

      return TestAttemptResult(
        attemptId: attemptId,
        testId: testId,
        testTitle: testTitle,
        score: score,
        totalMarks: totalMarks,
        totalQuestions: questions.length,
        attempted: correct + incorrect,
        correct: correct,
        incorrect: incorrect,
        skipped: skipped,
        selectedAnswers: selectedAnswers,
        questions: questions,
        submittedAt: attemptResp['submitted_at'] != null
            ? DateTime.tryParse(attemptResp['submitted_at'] as String) ??
                  DateTime.now()
            : DateTime.now(),
      );
    });
  }

  Future<List<LessonItem>> fetchCourseLessons(String courseId) async {
    return withRetry('fetchCourseLessons', () async {
      final uid = currentUserId;

      Set<String> completedIds = {};
      if (uid != null) {
        try {
          final completedResp = await client
              .from('lesson_completions')
              .select('lesson_id')
              .eq('student_id', uid)
              .eq('course_id', courseId);
          completedIds = (completedResp as List<dynamic>)
              .map((e) => e['lesson_id'] as String)
              .toSet();
        } catch (_) {}
      }

      final resp = await client
          .from('lessons')
          .select(
            'id, title, lesson_type, content_url, duration_mins, sort_order, is_published',
          )
          .eq('course_id', courseId)
          .eq('is_published', true)
          .order('sort_order', ascending: true);

      return (resp as List<dynamic>)
          .map(
            (e) => LessonItem.fromJson(
              e as Map<String, dynamic>,
              completed: completedIds.contains(e['id'] as String? ?? ''),
            ),
          )
          .toList();
    });
  }

  Future<void> markLessonComplete(String courseId, String lessonId) async {
    return withRetry('markLessonComplete', () async {
      final uid = currentUserId;
      if (uid == null) return;

      try {
        await client.from('lesson_completions').upsert({
          'student_id': uid,
          'course_id': courseId,
          'lesson_id': lessonId,
          'completed_at': DateTime.now().toIso8601String(),
        }, onConflict: 'student_id,lesson_id');

        final completedResp = await client
            .from('lesson_completions')
            .select('lesson_id')
            .eq('student_id', uid)
            .eq('course_id', courseId);

        await client.from('course_enrollments').upsert({
          'student_id': uid,
          'course_id': courseId,
          'lessons_completed': (completedResp as List<dynamic>).length,
          'last_accessed_at': DateTime.now().toIso8601String(),
        }, onConflict: 'student_id,course_id');
      } catch (e) {
        debugPrint('[SupabaseService] markLessonComplete error: $e');
      }
    });
  }

  // ── Admin KPI ────────────────────────────────────────────

  Future<AdminKpiData> fetchAdminKpi() async {
    return withRetry('fetchAdminKpi', () async {
      try {
        final studentsResp = await client
            .from('user_profiles')
            .select('id')
            .eq('role', 'student');

        final batchesResp = await client
            .from('batches')
            .select('id')
            .eq('is_active', true);

        final doubtsResp = await client
            .from('doubts')
            .select('id')
            .eq('status', 'open');

        final coursesResp = await client.from('courses').select('id');

        final testsResp = await client
            .from('tests')
            .select('id')
            .eq('status', 'published');

        final lessonsResp = await client.from('lessons').select('id');

        return AdminKpiData(
          totalStudents: (studentsResp as List<dynamic>).length,
          activeBatches: (batchesResp as List<dynamic>).length,
          pendingDoubts: (doubtsResp as List<dynamic>).length,
          totalCourses: (coursesResp as List<dynamic>).length,
          testsPublished: (testsResp as List<dynamic>).length,
          totalLessons: (lessonsResp as List<dynamic>).length,
        );
      } catch (e) {
        debugPrint('[SupabaseService] fetchAdminKpi error: $e');
        return const AdminKpiData(
          totalStudents: 0,
          activeBatches: 0,
          pendingDoubts: 0,
          totalCourses: 0,
          testsPublished: 0,
          totalLessons: 0,
        );
      }
    });
  }

  // ── Admin Students ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllStudents({
    int page = 0,
    int pageSize = 20,
  }) async {
    return withRetry('fetchAllStudents', () async {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final resp = await client
          .from('user_profiles')
          .select(
            'id, email, full_name, username, avatar_url, is_active, account_expires_at, created_at',
          )
          .eq('role', 'student')
          .order('created_at', ascending: false)
          .range(from, to);

      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  /// Creates a student account via Edge Function (uses service-role key server-side)
  Future<void> createStudentAccount({
    required String email,
    required String password,
    required String fullName,
    String? username,
    DateTime? expiresAt,
  }) async {
    // Build request body
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'full_name': fullName,
    };
    if (username != null && username.trim().isNotEmpty) {
      body['username'] = username.trim();
    }
    if (expiresAt != null) {
      body['expires_at'] = expiresAt.toUtc().toIso8601String();
    }

    // Invoke the edge function (runs with service-role key server-side)
    final response = await client.functions.invoke(
      'create-student',
      body: body,
    );

    // Check for errors in the response
    final data = response.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    if (data == null || (data is Map && data['success'] != true)) {
      throw Exception('Failed to create student account');
    }
  }

  /// Updates an existing student's profile fields (name, username, expiry)
  Future<void> updateStudentAccount({
    required String studentId,
    required String fullName,
    String? username,
    DateTime? expiresAt,
  }) async {
    return withRetry('updateStudentAccount', () async {
      await client
          .from('user_profiles')
          .update({
            'full_name': fullName,
            'username': username,
            'account_expires_at': expiresAt?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', studentId);
    });
  }

  /// Toggles is_active for a student
  Future<void> toggleStudentActive(String studentId, bool isActive) async {
    return withRetry('toggleStudentActive', () async {
      await client
          .from('user_profiles')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', studentId);
    });
  }

  // ── Admin Doubts ─────────────────────────────────────────

  Future<List<DoubtItem>> fetchAllDoubts({
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    return withRetry('fetchAllDoubts', () async {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      var query = client
          .from('doubts')
          .select(
            'id, title, body, status, answer_text, created_at, answered_at, courses(title)',
          );

      if (status != null) {
        query = query.eq('status', status);
      }

      final resp = await query
          .order('created_at', ascending: false)
          .range(from, to);

      return (resp as List<dynamic>)
          .map((e) => DoubtItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> answerDoubt(String doubtId, String answerText) async {
    return withRetry('answerDoubt', () async {
      await client
          .from('doubts')
          .update({
            'answer_text': answerText,
            'status': 'answered',
            'answered_by': currentUserId,
            'answered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', doubtId);
    });
  }

  /// Fetch a single doubt by its ID (used for notification navigation).
  Future<DoubtItem?> fetchDoubtById(String doubtId) async {
    return withRetry('fetchDoubtById', () async {
      final resp = await client
          .from('doubts')
          .select(
            'id, title, body, status, answer_text, created_at, answered_at, courses(title)',
          )
          .eq('id', doubtId)
          .maybeSingle();
      if (resp == null) return null;
      return DoubtItem.fromJson(resp);
    });
  }

  // ── Student Doubts ───────────────────────────────────────

  Future<List<DoubtItem>> fetchStudentDoubts() async {
    return withRetry('fetchStudentDoubts', () async {
      final uid = currentUserId;
      if (uid == null) return [];

      final resp = await client
          .from('doubts')
          .select(
            'id, title, body, status, answer_text, created_at, answered_at, courses(title)',
          )
          .eq('student_id', uid)
          .order('created_at', ascending: false);

      return (resp as List<dynamic>)
          .map((e) => DoubtItem.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> submitDoubt({
    required String title,
    required String body,
    String? courseId,
  }) async {
    return withRetry('submitDoubt', () async {
      final uid = currentUserId;
      if (uid == null) throw Exception('Not authenticated');

      await client.from('doubts').insert({
        'student_id': uid,
        'title': title,
        'body': body,
        if (courseId != null) 'course_id': courseId,
        'status': 'open',
      });
    });
  }

  // ── Doubt Replies ────────────────────────────────────────

  /// Fetch all replies for a doubt thread, including author name
  Future<List<Map<String, dynamic>>> fetchDoubtReplies(String doubtId) async {
    return withRetry('fetchDoubtReplies', () async {
      final resp = await client
          .from('doubt_replies')
          .select(
            'id, doubt_id, body, is_admin, created_at, author_id, user_profiles(full_name)',
          )
          .eq('doubt_id', doubtId)
          .order('created_at', ascending: true);

      return (resp as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        final profile = map['user_profiles'] as Map<String, dynamic>?;
        return {
          'id': map['id'],
          'doubt_id': map['doubt_id'],
          'body': map['body'],
          'is_admin': map['is_admin'],
          'created_at': map['created_at'],
          'author_id': map['author_id'],
          'author_name': profile?['full_name'] as String? ?? 'Unknown',
        };
      }).toList();
    });
  }

  /// Add a reply to a doubt thread
  Future<void> addDoubtReply({
    required String doubtId,
    required String body,
    required bool isAdmin,
  }) async {
    return withRetry('addDoubtReply', () async {
      final uid = currentUserId;
      if (uid == null) throw Exception('Not authenticated');

      await client.from('doubt_replies').insert({
        'doubt_id': doubtId,
        'author_id': uid,
        'body': body,
        'is_admin': isAdmin,
      });
    });
  }

  // ── PDF Signed URL ───────────────────────────────────────

  /// Get a signed URL for a PDF stored in Supabase Storage.
  /// First tries to get content_url from the lesson record.
  /// If the URL is already a public URL, returns it directly.
  Future<String?> getSignedPdfUrl(String lessonId) async {
    return withRetry('getSignedPdfUrl', () async {
      final resp = await client
          .from('lessons')
          .select('content_url')
          .eq('id', lessonId)
          .maybeSingle();

      final contentUrl = resp?['content_url'] as String?;
      if (contentUrl == null || contentUrl.isEmpty) return null;

      // If it's already a full HTTP URL, return as-is
      if (contentUrl.startsWith('http')) return contentUrl;

      // Otherwise treat as a storage path and create a signed URL
      try {
        final signedUrl = await client.storage
            .from('course-materials')
            .createSignedUrl(contentUrl, 3600); // 1 hour expiry
        return signedUrl;
      } catch (e) {
        debugPrint('[SupabaseService] getSignedPdfUrl storage error: $e');
        // Fall back to public URL
        return client.storage.from('course-materials').getPublicUrl(contentUrl);
      }
    });
  }

  // ── Admin Bulk Upload ────────────────────────────────────

  Future<int> bulkInsertQuestions(List<Map<String, dynamic>> questions) async {
    return withRetry('bulkInsertQuestions', () async {
      if (questions.isEmpty) return 0;
      try {
        await client.from('questions').insert(questions);
        return questions.length;
      } catch (e) {
        debugPrint('[SupabaseService] bulkInsertQuestions error: $e');
        rethrow;
      }
    });
  }

  Future<int> bulkInsertLessons(List<Map<String, dynamic>> lessons) async {
    return withRetry('bulkInsertLessons', () async {
      if (lessons.isEmpty) return 0;
      try {
        await client.from('lessons').insert(lessons);
        return lessons.length;
      } catch (e) {
        debugPrint('[SupabaseService] bulkInsertLessons error: $e');
        rethrow;
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchAllTestsSimple() async {
    return withRetry('fetchAllTestsSimple', () async {
      final resp = await client
          .from('tests')
          .select('id, title')
          .order('created_at', ascending: false);
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  // ── Admin Batch Chart ────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchBatchEnrollmentStats() async {
    return withRetry('fetchBatchEnrollmentStats', () async {
      try {
        final resp = await client
            .from('batches')
            .select('id, name, is_active')
            .order('name', ascending: true);

        return (resp as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (e) {
        debugPrint('[SupabaseService] fetchBatchEnrollmentStats error: $e');
        return [];
      }
    });
  }

  // ── User Profile ─────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    return withRetry('fetchCurrentUserProfile', () async {
      final uid = currentUserId;
      if (uid == null) return null;
      final resp = await client
          .from('user_profiles')
          .select('id, email, full_name, avatar_url, role, created_at')
          .eq('id', uid)
          .maybeSingle();
      return resp;
    });
  }

  Future<void> updateUserProfile({String? fullName, String? avatarUrl}) async {
    return withRetry('updateUserProfile', () async {
      final uid = currentUserId;
      if (uid == null) return;
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (updates.isEmpty) return;
      await client.from('user_profiles').update(updates).eq('id', uid);
    });
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ── Admin Content ────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllCourses({
    int page = 0,
    int pageSize = 20,
  }) async {
    return withRetry('fetchAllCourses', () async {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final resp = await client
          .from('courses')
          .select(
            'id, title, description, is_published, total_lessons, created_at, batches(name)',
          )
          .order('created_at', ascending: false)
          .range(from, to);

      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  Future<List<Map<String, dynamic>>> fetchAllTests({
    int page = 0,
    int pageSize = 20,
  }) async {
    return withRetry('fetchAllTests', () async {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final resp = await client
          .from('tests')
          .select(
            'id, title, status, duration_mins, total_marks, scheduled_at, created_at, batches(name)',
          )
          .order('created_at', ascending: false)
          .range(from, to);

      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  Future<List<Map<String, dynamic>>> fetchAllBatches() async {
    return withRetry('fetchAllBatches', () async {
      final resp = await client
          .from('batches')
          .select(
            'id, name, description, is_active, start_date, end_date, created_at',
          )
          .order('created_at', ascending: false);

      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  Future<void> createBatch({required String name, String? description}) async {
    return withRetry('createBatch', () async {
      await client.from('batches').insert({
        'name': name,
        if (description != null) 'description': description,
        'is_active': true,
      });
    });
  }

  Future<void> createCourse({
    required String title,
    String? description,
    String? batchId,
  }) async {
    return withRetry('createCourse', () async {
      await client.from('courses').insert({
        'title': title,
        if (description != null) 'description': description,
        if (batchId != null) 'batch_id': batchId,
        'is_published': false,
        'total_lessons': 0,
      });
    });
  }

  Future<void> createTest({
    required String title,
    String? description,
    String? batchId,
    String? courseId,
    int durationMins = 60,
    int totalMarks = 100,
  }) async {
    return withRetry('createTest', () async {
      await client.from('tests').insert({
        'title': title,
        if (description != null) 'description': description,
        if (batchId != null) 'batch_id': batchId,
        if (courseId != null) 'course_id': courseId,
        'duration_mins': durationMins,
        'total_marks': totalMarks,
        'status': 'draft',
      });
    });
  }

  // ── Admin Lesson CRUD ────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchCourseLessonsAdmin(
    String courseId,
  ) async {
    return withRetry('fetchCourseLessonsAdmin', () async {
      final resp = await client
          .from('lessons')
          .select(
            'id, title, lesson_type, content_url, sort_order, duration_mins, is_published, created_at',
          )
          .eq('course_id', courseId)
          .order('sort_order', ascending: true);
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  Future<void> createLesson({
    required String courseId,
    required String title,
    required String lessonType,
    String? contentUrl,
    int? durationMins,
    int sortOrder = 0,
  }) async {
    return withRetry('createLesson', () async {
      await client.from('lessons').insert({
        'course_id': courseId,
        'title': title,
        'lesson_type': lessonType,
        if (contentUrl != null) 'content_url': contentUrl,
        if (durationMins != null) 'duration_mins': durationMins,
        'sort_order': sortOrder,
        'is_published': true,
      });
      // Update total_lessons count
      final count = await client
          .from('lessons')
          .select('id')
          .eq('course_id', courseId);
      await client
          .from('courses')
          .update({'total_lessons': (count as List).length})
          .eq('id', courseId);
    });
  }

  Future<void> updateLesson(String lessonId, Map<String, dynamic> data) async {
    return withRetry('updateLesson', () async {
      await client
          .from('lessons')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', lessonId);
    });
  }

  Future<void> deleteLesson(String lessonId, String courseId) async {
    return withRetry('deleteLesson', () async {
      await client.from('lessons').delete().eq('id', lessonId);
      // Update total_lessons count
      final count = await client
          .from('lessons')
          .select('id')
          .eq('course_id', courseId);
      await client
          .from('courses')
          .update({'total_lessons': (count as List).length})
          .eq('id', courseId);
    });
  }

  Future<void> publishLesson(String lessonId, bool isPublished) async {
    return withRetry('publishLesson', () async {
      await client
          .from('lessons')
          .update({
            'is_published': isPublished,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', lessonId);
    });
  }

  Future<void> publishCourse(String courseId, bool isPublished) async {
    return withRetry('publishCourse', () async {
      await client
          .from('courses')
          .update({
            'is_published': isPublished,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', courseId);
    });
  }

  Future<void> publishTest(String testId, String status) async {
    return withRetry('publishTest', () async {
      await client
          .from('tests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', testId);
    });
  }

  Future<void> deleteCourse(String courseId) async {
    return withRetry('deleteCourse', () async {
      await client.from('courses').delete().eq('id', courseId);
    });
  }

  Future<void> deleteTest(String testId) async {
    return withRetry('deleteTest', () async {
      await client.from('tests').delete().eq('id', testId);
    });
  }

  Future<void> deleteBatch(String batchId) async {
    return withRetry('deleteBatch', () async {
      await client.from('batches').delete().eq('id', batchId);
    });
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    return withRetry('updateCourse', () async {
      await client
          .from('courses')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', courseId);
    });
  }

  Future<void> updateTest(String testId, Map<String, dynamic> data) async {
    return withRetry('updateTest', () async {
      await client
          .from('tests')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', testId);
    });
  }

  Future<void> updateBatch(String batchId, Map<String, dynamic> data) async {
    return withRetry('updateBatch', () async {
      await client
          .from('batches')
          .update({...data, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', batchId);
    });
  }

  // ── Batch Assignments ────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchBatchAssignments(
    String batchId,
  ) async {
    return withRetry('fetchBatchAssignments', () async {
      final resp = await client
          .from('batch_course_assignments')
          .select(
            'id, course_id, test_id, assigned_at, courses(id, title, is_published), tests(id, title, status)',
          )
          .eq('batch_id', batchId)
          .order('assigned_at', ascending: false);
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  Future<void> assignCourseToBatch({
    required String batchId,
    required String courseId,
  }) async {
    return withRetry('assignCourseToBatch', () async {
      await client.from('batch_course_assignments').insert({
        'batch_id': batchId,
        'course_id': courseId,
        'assigned_by': currentUserId,
      });
      // Also update courses.batch_id
      await client
          .from('courses')
          .update({'batch_id': batchId})
          .eq('id', courseId);
    });
  }

  Future<void> assignTestToBatch({
    required String batchId,
    required String testId,
  }) async {
    return withRetry('assignTestToBatch', () async {
      await client.from('batch_course_assignments').insert({
        'batch_id': batchId,
        'test_id': testId,
        'assigned_by': currentUserId,
      });
      // Also update tests.batch_id
      await client.from('tests').update({'batch_id': batchId}).eq('id', testId);
    });
  }

  Future<void> removeAssignment(String assignmentId) async {
    return withRetry('removeAssignment', () async {
      await client
          .from('batch_course_assignments')
          .delete()
          .eq('id', assignmentId);
    });
  }

  Future<List<Map<String, dynamic>>> fetchBatchStudents(String batchId) async {
    return withRetry('fetchBatchStudents', () async {
      final resp = await client
          .from('batch_enrollments')
          .select(
            'id, student_id, enrolled_at, is_active, user_profiles(id, full_name, email, avatar_url)',
          )
          .eq('batch_id', batchId)
          .order('enrolled_at', ascending: false);
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  Future<void> enrollStudentInBatch({
    required String batchId,
    required String studentId,
  }) async {
    return withRetry('enrollStudentInBatch', () async {
      await client.from('batch_enrollments').upsert({
        'batch_id': batchId,
        'student_id': studentId,
        'is_active': true,
      }, onConflict: 'student_id,batch_id');
    });
  }

  Future<void> removeStudentFromBatch({
    required String batchId,
    required String studentId,
  }) async {
    return withRetry('removeStudentFromBatch', () async {
      await client
          .from('batch_enrollments')
          .update({'is_active': false})
          .eq('batch_id', batchId)
          .eq('student_id', studentId);
    });
  }

  // ── Drip Content / Schedule ──────────────────────────────

  /// Fetch all lessons for a course with their scheduled_at dates (admin view)
  Future<List<Map<String, dynamic>>> fetchLessonsWithSchedule(
    String courseId,
  ) async {
    return withRetry('fetchLessonsWithSchedule', () async {
      final resp = await client
          .from('lessons')
          .select(
            'id, title, lesson_type, sort_order, is_published, scheduled_at, duration_mins',
          )
          .eq('course_id', courseId)
          .order('sort_order', ascending: true);
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  /// Fetch all tests with their scheduled_at dates (admin view)
  Future<List<Map<String, dynamic>>> fetchTestsWithSchedule({
    String? batchId,
  }) async {
    return withRetry('fetchTestsWithSchedule', () async {
      var query = client
          .from('tests')
          .select(
            'id, title, status, scheduled_at, duration_mins, total_marks, batch_id, batches(name)',
          );
      if (batchId != null) {
        query = query.eq('batch_id', batchId);
      }
      final resp = await query.order(
        'scheduled_at',
        ascending: true,
        nullsFirst: false,
      );
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  /// Update scheduled_at for a lesson
  Future<void> scheduleLessonRelease({
    required String lessonId,
    required DateTime? scheduledAt,
  }) async {
    return withRetry('scheduleLessonRelease', () async {
      await client
          .from('lessons')
          .update({
            'scheduled_at': scheduledAt?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', lessonId);
    });
  }

  /// Update scheduled_at for a test
  Future<void> scheduleTestRelease({
    required String testId,
    required DateTime? scheduledAt,
    String? status,
  }) async {
    return withRetry('scheduleTestRelease', () async {
      await client
          .from('tests')
          .update({
            'scheduled_at': scheduledAt?.toIso8601String(),
            if (status != null) 'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', testId);
    });
  }

  /// Fetch drip content timeline for a student (lessons + tests, sorted by scheduled_at)
  Future<List<DripContentItem>> fetchStudentDripTimeline({
    String? courseId,
    String? batchId,
  }) async {
    return withRetry('fetchStudentDripTimeline', () async {
      final uid = currentUserId;
      if (uid == null) return [];

      final List<DripContentItem> items = [];
      final now = DateTime.now();

      // Fetch lessons
      if (courseId != null) {
        final lessonsResp = await client
            .from('lessons')
            .select(
              'id, title, lesson_type, sort_order, is_published, scheduled_at, duration_mins',
            )
            .eq('course_id', courseId)
            .eq('is_published', true)
            .order('sort_order', ascending: true);

        // Fetch completed lesson IDs for this student
        final completedResp = await client
            .from('lesson_completions')
            .select('lesson_id')
            .eq('student_id', uid)
            .eq('course_id', courseId);
        final completedIds = (completedResp as List<dynamic>)
            .map((e) => e['lesson_id'] as String)
            .toSet();

        for (final l in (lessonsResp as List<dynamic>)) {
          final scheduledAt = l['scheduled_at'] != null
              ? DateTime.tryParse(l['scheduled_at'] as String)
              : null;
          final isReleased = scheduledAt == null || scheduledAt.isBefore(now);
          items.add(
            DripContentItem(
              id: l['id'] as String,
              title: l['title'] as String? ?? 'Untitled Lesson',
              type: DripContentType.lesson,
              scheduledAt: scheduledAt,
              isReleased: isReleased,
              isCompleted: completedIds.contains(l['id'] as String),
              contentType: l['lesson_type'] as String? ?? 'text',
            ),
          );
        }
      }

      // Fetch tests
      if (batchId != null) {
        final testsResp = await client
            .from('tests')
            .select('id, title, scheduled_at, duration_mins, status')
            .eq('batch_id', batchId)
            .eq('status', 'published')
            .order('scheduled_at', ascending: true, nullsFirst: false);

        // Fetch attempted test IDs
        final attemptsResp = await client
            .from('test_attempts')
            .select('test_id')
            .eq('student_id', uid)
            .inFilter('status', ['submitted', 'graded']);
        final attemptedIds = (attemptsResp as List<dynamic>)
            .map((e) => e['test_id'] as String)
            .toSet();

        for (final t in (testsResp as List<dynamic>)) {
          final scheduledAt = t['scheduled_at'] != null
              ? DateTime.tryParse(t['scheduled_at'] as String)
              : null;
          final isReleased = scheduledAt == null || scheduledAt.isBefore(now);
          items.add(
            DripContentItem(
              id: t['id'] as String,
              title: t['title'] as String? ?? 'Untitled Test',
              type: DripContentType.test,
              scheduledAt: scheduledAt,
              isReleased: isReleased,
              isCompleted: attemptedIds.contains(t['id'] as String),
              contentType: 'test',
              durationMins: t['duration_mins'] as int?,
            ),
          );
        }
      }

      // Sort by scheduledAt (nulls first = already released)
      items.sort((a, b) {
        if (a.scheduledAt == null && b.scheduledAt == null) return 0;
        if (a.scheduledAt == null) return -1;
        if (b.scheduledAt == null) return 1;
        return a.scheduledAt!.compareTo(b.scheduledAt!);
      });

      return items;
    });
  }

  /// Fetch all courses for drip schedule admin (with batch info)
  Future<List<Map<String, dynamic>>> fetchCoursesForSchedule() async {
    return withRetry('fetchCoursesForSchedule', () async {
      final resp = await client
          .from('courses')
          .select('id, title, batch_id, total_lessons, batches(name)')
          .order('created_at', ascending: false);
      return (resp as List<dynamic>).cast<Map<String, dynamic>>();
    });
  }

  // ── Cache-Aware Methods ──────────────────────────────────

  /// Fetch course lessons with local cache fallback.
  /// Returns cached data if available and not expired; fetches from Supabase otherwise.
  Future<List<LessonItem>> fetchCourseLessonsCached(String courseId) async {
    final cache = LocalCacheService.instance;

    // Try cache first
    final cached = await cache.getCachedLessons(courseId);
    if (cached != null) {
      debugPrint('[SupabaseService] Lessons served from cache: $courseId');
      final uid = currentUserId;
      Set<String> completedIds = {};
      if (uid != null) {
        try {
          final completedResp = await client
              .from('lesson_completions')
              .select('lesson_id')
              .eq('student_id', uid)
              .eq('course_id', courseId);
          completedIds = (completedResp as List<dynamic>)
              .map((e) => e['lesson_id'] as String)
              .toSet();
        } catch (_) {}
      }
      return cached
          .map(
            (e) => LessonItem.fromJson(
              e,
              completed: completedIds.contains(e['id'] as String? ?? ''),
            ),
          )
          .toList();
    }

    // Fetch from Supabase and cache result
    try {
      final lessons = await fetchCourseLessons(courseId);
      // Store raw JSON for caching (only published lessons, matching fetchCourseLessons)
      final rawResp = await client
          .from('lessons')
          .select(
            'id, title, lesson_type, content_url, duration_mins, sort_order, is_published',
          )
          .eq('course_id', courseId)
          .eq('is_published', true)
          .order('sort_order', ascending: true);
      await cache.cacheLessons(
        courseId,
        (rawResp as List<dynamic>).cast<Map<String, dynamic>>(),
      );
      return lessons;
    } catch (e) {
      debugPrint('[SupabaseService] fetchCourseLessonsCached error: $e');
      rethrow;
    }
  }

  // ─── Notifications ────────────────────────────────────────

  Future<void> markNotificationRead(String notificationId) async {
    return withRetry('markNotificationRead', () async {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    });
  }

  // ── Offline Queue Integration ────────────────────────────

  /// Initialize the offline queue and register all sync handlers.
  /// Call this once during app startup after Supabase is initialized.
  Future<void> initOfflineQueue() async {
    final queue = OfflineQueueService.instance;
    await queue.initialize();

    // Register handler: lesson completion
    queue.registerHandler(OfflineActionType.lessonComplete, (action) async {
      final courseId = action.payload['courseId'] as String;
      final lessonId = action.payload['lessonId'] as String;
      await markLessonComplete(courseId, lessonId);
      // Invalidate lessons cache so next fetch is fresh
      await LocalCacheService.instance.invalidateLessons(courseId);
    });

    // Register handler: test attempt submission
    queue.registerHandler(OfflineActionType.testAttemptSubmit, (action) async {
      final p = action.payload;
      final attemptId = p['attemptId'] as String;
      final score = (p['score'] as num).toDouble();
      final totalMarks = (p['totalMarks'] as num).toDouble();
      final answersJson = (p['answersJson'] as Map<String, dynamic>?) ?? {};
      final antiCheat = (p['antiCheatViolations'] as int?) ?? 0;

      await client
          .from('test_attempts')
          .update({
            'score': score,
            'total_marks': totalMarks,
            'status': 'submitted',
            'submitted_at':
                p['submittedAt'] as String? ?? DateTime.now().toIso8601String(),
            'answers_json': answersJson,
            'anti_cheat_violations': antiCheat,
          })
          .eq('id', attemptId);

      // Invalidate scores cache
      final uid = currentUserId;
      if (uid != null) {
        await LocalCacheService.instance.invalidateScores(uid);
      }
    });

    // Register handler: bookmark
    queue.registerHandler(OfflineActionType.bookmark, (action) async {
      final lessonId = action.payload['lessonId'] as String;
      final courseId = action.payload['courseId'] as String;
      final isBookmarked = action.payload['isBookmarked'] as bool? ?? true;
      final uid = currentUserId;
      if (uid == null) return;

      if (isBookmarked) {
        await client.from('lesson_bookmarks').upsert({
          'student_id': uid,
          'lesson_id': lessonId,
          'course_id': courseId,
          'bookmarked_at': DateTime.now().toIso8601String(),
        }, onConflict: 'student_id,lesson_id');
      } else {
        await client
            .from('lesson_bookmarks')
            .delete()
            .eq('student_id', uid)
            .eq('lesson_id', lessonId);
      }
    });

    // Register handler: submit doubt
    queue.registerHandler(OfflineActionType.submitDoubt, (action) async {
      final p = action.payload;
      await submitDoubt(
        title: p['title'] as String,
        body: p['body'] as String,
        courseId: p['courseId'] as String?,
      );
    });

    debugPrint('[SupabaseService] Offline queue initialized with handlers');

    // Attempt to sync any pending actions immediately if online
    if (queue.isOnline) {
      final result = await queue.syncQueue();
      if (result.synced > 0) {
        debugPrint(
          '[SupabaseService] Startup sync: ${result.synced} actions synced',
        );
      }
    }
  }

  // ── Admin Reporting ──────────────────────────────────────

  /// Fetch all test results for admin reporting (paginated)
  Future<List<Map<String, dynamic>>> fetchAdminTestResultsReport({
    int page = 0,
    int pageSize = 50,
    String? batchId,
    String? testId,
  }) async {
    return withRetry('fetchAdminTestResultsReport', () async {
      final cacheKey =
          'admin_test_results_${batchId ?? "all"}_${testId ?? "all"}_p$page';
      final cached = await LocalCacheService.instance.getCachedGeneric(
        cacheKey,
      );
      if (cached != null) {
        return (cached as List<dynamic>).cast<Map<String, dynamic>>();
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      var query = client
          .from('test_attempts')
          .select(
            'id, score, total_marks, status, submitted_at, started_at, '
            'student_id, test_id, '
            'user_profiles!test_attempts_student_id_fkey(full_name, email), '
            'tests(title, batch_id, batches(name))',
          )
          .inFilter('status', ['submitted', 'graded']);

      if (testId != null) query = query.eq('test_id', testId);

      final resp = await query
          .order('submitted_at', ascending: false)
          .range(from, to);

      final data = (resp as List<dynamic>).cast<Map<String, dynamic>>();

      // Filter by batchId after fetch if needed
      final filtered = batchId != null
          ? data.where((r) {
              final tests = r['tests'] as Map<String, dynamic>?;
              return tests?['batch_id'] == batchId;
            }).toList()
          : data;

      await LocalCacheService.instance.cacheGeneric(
        cacheKey,
        filtered,
        ttl: const Duration(minutes: 15),
      );
      return filtered;
    });
  }

  /// Fetch student progress report for admin (paginated)
  Future<List<Map<String, dynamic>>> fetchStudentProgressReport({
    int page = 0,
    int pageSize = 50,
    String? batchId,
  }) async {
    return withRetry('fetchStudentProgressReport', () async {
      final cacheKey = 'admin_student_progress_${batchId ?? "all"}_p$page';
      final cached = await LocalCacheService.instance.getCachedGeneric(
        cacheKey,
      );
      if (cached != null) {
        return (cached as List<dynamic>).cast<Map<String, dynamic>>();
      }

      final from = page * pageSize;
      final to = from + pageSize - 1;

      List<String> studentIds = [];
      if (batchId != null) {
        final enrollResp = await client
            .from('batch_enrollments')
            .select('student_id')
            .eq('batch_id', batchId)
            .eq('is_active', true);
        studentIds = (enrollResp as List<dynamic>)
            .map((e) => e['student_id'] as String)
            .toList();
        if (studentIds.isEmpty) return [];
      }

      var profileQuery = client
          .from('user_profiles')
          .select('id, full_name, email, created_at')
          .eq('role', 'student');

      if (studentIds.isNotEmpty) {
        profileQuery = profileQuery.inFilter('id', studentIds);
      }

      final profilesResp = await profileQuery
          .order('full_name', ascending: true)
          .range(from, to);

      final profiles = (profilesResp as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (profiles.isEmpty) return [];

      final ids = profiles.map((p) => p['id'] as String).toList();

      // Fetch test attempts summary per student
      final attemptsResp = await client
          .from('test_attempts')
          .select('student_id, score, total_marks, status')
          .inFilter('student_id', ids)
          .inFilter('status', ['submitted', 'graded']);

      final attempts = (attemptsResp as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // Fetch lesson completions per student
      final lessonsResp = await client
          .from('lesson_completions')
          .select('student_id')
          .inFilter('student_id', ids);

      final lessonCompletions = (lessonsResp as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // Aggregate per student
      final result = profiles.map((profile) {
        final sid = profile['id'] as String;
        final studentAttempts = attempts
            .where((a) => a['student_id'] == sid)
            .toList();
        final testsTaken = studentAttempts.length;
        double avgScore = 0;
        if (testsTaken > 0) {
          double totalPct = 0;
          int valid = 0;
          for (final a in studentAttempts) {
            final score = (a['score'] as num?)?.toDouble() ?? 0;
            final total = (a['total_marks'] as num?)?.toDouble() ?? 0;
            if (total > 0) {
              totalPct += (score / total) * 100;
              valid++;
            }
          }
          if (valid > 0) avgScore = totalPct / valid;
        }
        final lessonsCompleted = lessonCompletions
            .where((l) => l['student_id'] == sid)
            .length;

        return {
          'student_id': sid,
          'full_name': profile['full_name'] as String? ?? 'Unknown',
          'email': profile['email'] as String? ?? '',
          'tests_taken': testsTaken,
          'avg_score_pct': avgScore,
          'lessons_completed': lessonsCompleted,
          'joined_at': profile['created_at'] as String? ?? '',
        };
      }).toList();

      await LocalCacheService.instance.cacheGeneric(
        cacheKey,
        result,
        ttl: const Duration(minutes: 15),
      );
      return result;
    });
  }

  /// Fetch batch performance analytics for admin
  Future<List<Map<String, dynamic>>> fetchBatchPerformanceReport() async {
    return withRetry('fetchBatchPerformanceReport', () async {
      const cacheKey = 'admin_batch_performance';
      final cached = await LocalCacheService.instance.getCachedGeneric(
        cacheKey,
      );
      if (cached != null) {
        return (cached as List<dynamic>).cast<Map<String, dynamic>>();
      }

      final batchesResp = await client
          .from('batches')
          .select('id, name, is_active')
          .order('name', ascending: true);

      final batches = (batchesResp as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (batches.isEmpty) return [];

      final batchIds = batches.map((b) => b['id'] as String).toList();

      // Enrollments per batch
      final enrollResp = await client
          .from('batch_enrollments')
          .select('batch_id, student_id')
          .inFilter('batch_id', batchIds)
          .eq('is_active', true);
      final enrollments = (enrollResp as List<dynamic>)
          .cast<Map<String, dynamic>>();

      // Tests per batch
      final testsResp = await client
          .from('tests')
          .select('id, batch_id, title')
          .inFilter('batch_id', batchIds);
      final tests = (testsResp as List<dynamic>).cast<Map<String, dynamic>>();

      // Test attempts for those tests
      final testIds = tests.map((t) => t['id'] as String).toSet();
      List<Map<String, dynamic>> attempts = [];
      if (testIds.isNotEmpty) {
        final attResp = await client
            .from('test_attempts')
            .select('test_id, score, total_marks, status')
            .inFilter('test_id', testIds.toList())
            .inFilter('status', ['submitted', 'graded']);
        attempts = (attResp as List<dynamic>).cast<Map<String, dynamic>>();
      }

      final result = batches.map((batch) {
        final bid = batch['id'] as String;
        final batchEnrollments = enrollments
            .where((e) => e['batch_id'] == bid)
            .length;
        final batchTests = tests.where((t) => t['batch_id'] == bid).toList();
        final batchTestIds = batchTests.map((t) => t['id'] as String).toSet();
        final batchAttempts = attempts
            .where((a) => batchTestIds.contains(a['test_id']))
            .toList();

        double avgScore = 0;
        if (batchAttempts.isNotEmpty) {
          double totalPct = 0;
          int valid = 0;
          for (final a in batchAttempts) {
            final score = (a['score'] as num?)?.toDouble() ?? 0;
            final total = (a['total_marks'] as num?)?.toDouble() ?? 0;
            if (total > 0) {
              totalPct += (score / total) * 100;
              valid++;
            }
          }
          if (valid > 0) avgScore = totalPct / valid;
        }

        return {
          'batch_id': bid,
          'batch_name': batch['name'] as String? ?? 'Unnamed Batch',
          'is_active': batch['is_active'] as bool? ?? false,
          'total_students': batchEnrollments,
          'total_tests': batchTests.length,
          'total_attempts': batchAttempts.length,
          'avg_score_pct': avgScore,
        };
      }).toList();

      await LocalCacheService.instance.cacheGeneric(
        cacheKey,
        result,
        ttl: const Duration(minutes: 20),
      );
      return result;
    });
  }

  // ── Paginated Admin KPI (cached) ─────────────────────────

  Future<AdminKpiData> fetchAdminKpiCached() async {
    const cacheKey = 'admin_kpi_summary';
    final cached = await LocalCacheService.instance.getCachedGeneric(cacheKey);
    if (cached != null) {
      final m = cached as Map<String, dynamic>;
      return AdminKpiData(
        totalStudents: m['totalStudents'] as int? ?? 0,
        activeBatches: m['activeBatches'] as int? ?? 0,
        pendingDoubts: m['pendingDoubts'] as int? ?? 0,
        totalCourses: m['totalCourses'] as int? ?? 0,
        testsPublished: m['testsPublished'] as int? ?? 0,
        totalLessons: m['totalLessons'] as int? ?? 0,
      );
    }
    final kpi = await fetchAdminKpi();
    await LocalCacheService.instance.cacheGeneric(cacheKey, {
      'totalStudents': kpi.totalStudents,
      'activeBatches': kpi.activeBatches,
      'pendingDoubts': kpi.pendingDoubts,
      'totalCourses': kpi.totalCourses,
      'testsPublished': kpi.testsPublished,
      'totalLessons': kpi.totalLessons,
    }, ttl: const Duration(minutes: 10));
    return kpi;
  }

  // ── Paginated Lazy-Load Helpers ──────────────────────────

  /// Paginated students for admin with cache
  Future<List<Map<String, dynamic>>> fetchAllStudentsCached({
    int page = 0,
    int pageSize = 20,
  }) async {
    final cacheKey = 'admin_students_p${page}_s$pageSize';
    final cached = await LocalCacheService.instance.getCachedGeneric(cacheKey);
    if (cached != null) {
      return (cached as List<dynamic>).cast<Map<String, dynamic>>();
    }
    final data = await fetchAllStudents(page: page, pageSize: pageSize);
    await LocalCacheService.instance.cacheGeneric(
      cacheKey,
      data,
      ttl: const Duration(minutes: 5),
    );
    return data;
  }

  /// Paginated doubts for admin with cache
  Future<List<DoubtItem>> fetchAllDoubtsCached({
    String? status,
    int page = 0,
    int pageSize = 20,
  }) async {
    final cacheKey = 'admin_doubts_${status ?? "all"}_p${page}_s$pageSize';
    final cached = await LocalCacheService.instance.getCachedGeneric(cacheKey);
    if (cached != null) {
      return (cached as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((e) => DoubtItem.fromJson(e))
          .toList();
    }
    final data = await fetchAllDoubts(
      status: status,
      page: page,
      pageSize: pageSize,
    );
    await LocalCacheService.instance.cacheGeneric(
      cacheKey,
      data
          .map(
            (d) => {
              'id': d.id,
              'title': d.title,
              'body': d.body,
              'status': d.status,
              'answer_text': d.answerText,
              'created_at': d.createdAt.toIso8601String(),
              'answered_at': d.answeredAt?.toIso8601String(),
              'courses': d.courseTitle != null
                  ? {'title': d.courseTitle}
                  : null,
            },
          )
          .toList(),
      ttl: const Duration(minutes: 5),
    );
    return data;
  }
}
