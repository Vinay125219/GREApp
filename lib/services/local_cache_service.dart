import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache entry wrapper with TTL metadata
class CacheEntry {
  final dynamic data;
  final DateTime cachedAt;
  final Duration ttl;

  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(cachedAt.add(ttl));

  Map<String, dynamic> toJson() => {
    'data': data,
    'cachedAt': cachedAt.toIso8601String(),
    'ttlSeconds': ttl.inSeconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: json['data'],
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    ttl: Duration(seconds: json['ttlSeconds'] as int),
  );
}

/// Local cache service backed by SharedPreferences.
/// Stores lessons, questions, and scores as JSON with configurable TTL.
class LocalCacheService {
  static LocalCacheService? _instance;
  static LocalCacheService get instance => _instance ??= LocalCacheService._();

  LocalCacheService._();

  static SharedPreferences? _prefs;

  // ── Cache key prefixes ──────────────────────────────────
  static const String _prefixLesson = 'cache_lessons_';
  static const String _prefixQuestions = 'cache_questions_';
  static const String _prefixScores = 'cache_scores_';
  static const String _prefixGeneric = 'cache_generic_';

  // ── Default TTLs ────────────────────────────────────────
  static const Duration ttlLessons = Duration(hours: 6);
  static const Duration ttlQuestions = Duration(hours: 12);
  static const Duration ttlScores = Duration(hours: 1);
  static const Duration ttlGeneric = Duration(minutes: 30);

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Core read/write ─────────────────────────────────────

  Future<void> _write(String key, dynamic data, Duration ttl) async {
    try {
      final prefs = await _storage;
      final entry = CacheEntry(data: data, cachedAt: DateTime.now(), ttl: ttl);
      await prefs.setString(key, jsonEncode(entry.toJson()));
      debugPrint('[LocalCache] Written: $key');
    } catch (e) {
      debugPrint('[LocalCache] Write error for $key: $e');
    }
  }

  Future<dynamic> _read(String key) async {
    try {
      final prefs = await _storage;
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final entry = CacheEntry.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (entry.isExpired) {
        await prefs.remove(key);
        debugPrint('[LocalCache] Expired, removed: $key');
        return null;
      }
      debugPrint('[LocalCache] Hit: $key');
      return entry.data;
    } catch (e) {
      debugPrint('[LocalCache] Read error for $key: $e');
      return null;
    }
  }

  Future<void> _delete(String key) async {
    try {
      final prefs = await _storage;
      await prefs.remove(key);
    } catch (e) {
      debugPrint('[LocalCache] Delete error for $key: $e');
    }
  }

  // ── Lessons ─────────────────────────────────────────────

  /// Cache lessons list for a course
  Future<void> cacheLessons(
    String courseId,
    List<Map<String, dynamic>> lessons,
  ) async {
    await _write('$_prefixLesson$courseId', lessons, ttlLessons);
  }

  /// Retrieve cached lessons for a course. Returns null if not cached or expired.
  Future<List<Map<String, dynamic>>?> getCachedLessons(String courseId) async {
    final data = await _read('$_prefixLesson$courseId');
    if (data == null) return null;
    try {
      return (data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> invalidateLessons(String courseId) async {
    await _delete('$_prefixLesson$courseId');
  }

  // ── Questions ───────────────────────────────────────────

  /// Cache questions list for a test
  Future<void> cacheQuestions(
    String testId,
    List<Map<String, dynamic>> questions,
  ) async {
    await _write('$_prefixQuestions$testId', questions, ttlQuestions);
  }

  /// Retrieve cached questions for a test. Returns null if not cached or expired.
  Future<List<Map<String, dynamic>>?> getCachedQuestions(String testId) async {
    final data = await _read('$_prefixQuestions$testId');
    if (data == null) return null;
    try {
      return (data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> invalidateQuestions(String testId) async {
    await _delete('$_prefixQuestions$testId');
  }

  // ── Scores / Test History ────────────────────────────────

  /// Cache student test history (scores)
  Future<void> cacheScores(
    String userId,
    List<Map<String, dynamic>> scores,
  ) async {
    await _write('$_prefixScores$userId', scores, ttlScores);
  }

  /// Retrieve cached scores for a student. Returns null if not cached or expired.
  Future<List<Map<String, dynamic>>?> getCachedScores(String userId) async {
    final data = await _read('$_prefixScores$userId');
    if (data == null) return null;
    try {
      return (data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> invalidateScores(String userId) async {
    await _delete('$_prefixScores$userId');
  }

  // ── Generic cache ────────────────────────────────────────

  Future<void> cacheGeneric(String key, dynamic data, {Duration? ttl}) async {
    await _write('$_prefixGeneric$key', data, ttl ?? ttlGeneric);
  }

  Future<dynamic> getCachedGeneric(String key) async {
    return _read('$_prefixGeneric$key');
  }

  Future<void> invalidateGeneric(String key) async {
    await _delete('$_prefixGeneric$key');
  }

  // ── Bulk invalidation ────────────────────────────────────

  /// Clear all cached data
  Future<void> clearAll() async {
    try {
      final prefs = await _storage;
      final keys = prefs.getKeys().where(
        (k) =>
            k.startsWith(_prefixLesson) ||
            k.startsWith(_prefixQuestions) ||
            k.startsWith(_prefixScores) ||
            k.startsWith(_prefixGeneric),
      );
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('[LocalCache] All cache cleared');
    } catch (e) {
      debugPrint('[LocalCache] clearAll error: $e');
    }
  }

  /// Clear all expired entries
  Future<int> evictExpired() async {
    int removed = 0;
    try {
      final prefs = await _storage;
      final keys = prefs.getKeys().where(
        (k) =>
            k.startsWith(_prefixLesson) ||
            k.startsWith(_prefixQuestions) ||
            k.startsWith(_prefixScores) ||
            k.startsWith(_prefixGeneric),
      );
      for (final key in keys) {
        final raw = prefs.getString(key);
        if (raw == null) continue;
        try {
          final entry = CacheEntry.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
          if (entry.isExpired) {
            await prefs.remove(key);
            removed++;
          }
        } catch (_) {
          await prefs.remove(key);
          removed++;
        }
      }
      debugPrint('[LocalCache] Evicted $removed expired entries');
    } catch (e) {
      debugPrint('[LocalCache] evictExpired error: $e');
    }
    return removed;
  }

  /// Returns cache statistics
  Future<Map<String, int>> getStats() async {
    try {
      final prefs = await _storage;
      final keys = prefs.getKeys();
      return {
        'lessons': keys.where((k) => k.startsWith(_prefixLesson)).length,
        'questions': keys.where((k) => k.startsWith(_prefixQuestions)).length,
        'scores': keys.where((k) => k.startsWith(_prefixScores)).length,
        'generic': keys.where((k) => k.startsWith(_prefixGeneric)).length,
      };
    } catch (_) {
      return {'lessons': 0, 'questions': 0, 'scores': 0, 'generic': 0};
    }
  }
}
