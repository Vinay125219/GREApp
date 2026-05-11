import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of offline actions that can be queued
enum OfflineActionType {
  bookmark,
  testAttemptStart,
  testAttemptSubmit,
  lessonComplete,
  submitDoubt,
  markNotificationRead,
}

/// A single queued offline action
class OfflineAction {
  final String id;
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  int retryCount;

  OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'queuedAt': queuedAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
    id: json['id'] as String,
    type: OfflineActionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => OfflineActionType.bookmark,
    ),
    payload: (json['payload'] as Map<String, dynamic>?) ?? {},
    queuedAt: DateTime.parse(json['queuedAt'] as String),
    retryCount: (json['retryCount'] as int?) ?? 0,
  );
}

typedef SyncHandler = Future<void> Function(OfflineAction action);

/// Offline queue service that persists actions to SharedPreferences
/// and replays them when connectivity is restored.
class OfflineQueueService {
  static OfflineQueueService? _instance;
  static OfflineQueueService get instance =>
      _instance ??= OfflineQueueService._();

  OfflineQueueService._();

  static const String _queueKey = 'offline_action_queue';
  static const int _maxRetries = 5;

  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  bool _isOnline = true;

  /// Registered handlers per action type
  final Map<OfflineActionType, SyncHandler> _handlers = {};

  /// Stream controller for queue size updates
  final _queueSizeController = StreamController<int>.broadcast();
  Stream<int> get queueSizeStream => _queueSizeController.stream;

  bool get isOnline => _isOnline;

  // ── Initialization ──────────────────────────────────────

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Check initial connectivity
    try {
      final results = await Connectivity().checkConnectivity();
      _isOnline = results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      _isOnline = true;
    }

    // Listen for connectivity changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      debugPrint(
        '[OfflineQueue] Connectivity changed: ${_isOnline ? "online" : "offline"}',
      );
      if (wasOffline && _isOnline) {
        debugPrint('[OfflineQueue] Back online — triggering sync');
        syncQueue();
      }
    });

    debugPrint(
      '[OfflineQueue] Initialized. Online: $_isOnline, '
      'Queued: ${(await getQueue()).length}',
    );
  }

  void dispose() {
    _connectivitySub?.cancel();
    _queueSizeController.close();
  }

  // ── Handler registration ────────────────────────────────

  void registerHandler(OfflineActionType type, SyncHandler handler) {
    _handlers[type] = handler;
  }

  // ── Queue operations ────────────────────────────────────

  Future<List<OfflineAction>> getQueue() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final raw = prefs.getString(_queueKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OfflineAction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[OfflineQueue] getQueue error: $e');
      return [];
    }
  }

  Future<void> _saveQueue(List<OfflineAction> queue) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(
        _queueKey,
        jsonEncode(queue.map((a) => a.toJson()).toList()),
      );
      _queueSizeController.add(queue.length);
    } catch (e) {
      debugPrint('[OfflineQueue] _saveQueue error: $e');
    }
  }

  /// Enqueue an offline action. If online, attempts immediate execution.
  Future<void> enqueue(OfflineAction action) async {
    if (_isOnline && _handlers.containsKey(action.type)) {
      // Try to execute immediately
      try {
        await _handlers[action.type]!(action);
        debugPrint('[OfflineQueue] Executed immediately: ${action.type.name}');
        return;
      } catch (e) {
        debugPrint('[OfflineQueue] Immediate execution failed, queuing: $e');
      }
    }

    // Add to persistent queue
    final queue = await getQueue();
    queue.add(action);
    await _saveQueue(queue);
    debugPrint(
      '[OfflineQueue] Queued: ${action.type.name} (total: ${queue.length})',
    );
  }

  /// Convenience: queue a bookmark action
  Future<void> queueBookmark({
    required String lessonId,
    required String courseId,
    required bool isBookmarked,
  }) async {
    await enqueue(
      OfflineAction(
        id: 'bookmark_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.bookmark,
        payload: {
          'lessonId': lessonId,
          'courseId': courseId,
          'isBookmarked': isBookmarked,
        },
        queuedAt: DateTime.now(),
      ),
    );
  }

  /// Convenience: queue a lesson completion
  Future<void> queueLessonComplete({
    required String courseId,
    required String lessonId,
  }) async {
    await enqueue(
      OfflineAction(
        id: 'lesson_complete_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.lessonComplete,
        payload: {'courseId': courseId, 'lessonId': lessonId},
        queuedAt: DateTime.now(),
      ),
    );
  }

  /// Convenience: queue a test attempt submission
  Future<void> queueTestAttemptSubmit({
    required String attemptId,
    required String testId,
    required Map<String, dynamic> answersJson,
    required double score,
    required double totalMarks,
    required int correct,
    required int incorrect,
    required int skipped,
    required int antiCheatViolations,
  }) async {
    await enqueue(
      OfflineAction(
        id: 'test_submit_${attemptId}_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.testAttemptSubmit,
        payload: {
          'attemptId': attemptId,
          'testId': testId,
          'answersJson': answersJson,
          'score': score,
          'totalMarks': totalMarks,
          'correct': correct,
          'incorrect': incorrect,
          'skipped': skipped,
          'antiCheatViolations': antiCheatViolations,
          'submittedAt': DateTime.now().toIso8601String(),
        },
        queuedAt: DateTime.now(),
      ),
    );
  }

  /// Convenience: queue a doubt submission
  Future<void> queueSubmitDoubt({
    required String title,
    required String body,
    String? courseId,
  }) async {
    await enqueue(
      OfflineAction(
        id: 'doubt_${DateTime.now().millisecondsSinceEpoch}',
        type: OfflineActionType.submitDoubt,
        payload: {
          'title': title,
          'body': body,
          if (courseId != null) 'courseId': courseId,
        },
        queuedAt: DateTime.now(),
      ),
    );
  }

  // ── Sync ────────────────────────────────────────────────

  /// Process all queued actions. Called automatically when connectivity is restored.
  Future<SyncResult> syncQueue() async {
    if (_isSyncing) {
      debugPrint('[OfflineQueue] Sync already in progress, skipping');
      return SyncResult(synced: 0, failed: 0, remaining: 0);
    }
    _isSyncing = true;

    int synced = 0;
    int failed = 0;
    final List<OfflineAction> remaining = [];

    try {
      final queue = await getQueue();
      if (queue.isEmpty) {
        debugPrint('[OfflineQueue] Queue empty, nothing to sync');
        return SyncResult(synced: 0, failed: 0, remaining: 0);
      }

      debugPrint('[OfflineQueue] Syncing ${queue.length} queued actions...');

      for (final action in queue) {
        final handler = _handlers[action.type];
        if (handler == null) {
          debugPrint(
            '[OfflineQueue] No handler for ${action.type.name}, skipping',
          );
          // Keep in queue if no handler registered yet
          remaining.add(action);
          continue;
        }

        try {
          await handler(action);
          synced++;
          debugPrint(
            '[OfflineQueue] Synced: ${action.type.name} (id: ${action.id})',
          );
        } catch (e) {
          action.retryCount++;
          debugPrint(
            '[OfflineQueue] Sync failed for ${action.type.name} '
            '(retry ${action.retryCount}/$_maxRetries): $e',
          );
          if (action.retryCount < _maxRetries) {
            remaining.add(action);
          } else {
            failed++;
            debugPrint(
              '[OfflineQueue] Max retries reached, dropping: ${action.id}',
            );
          }
        }
      }

      await _saveQueue(remaining);
      debugPrint(
        '[OfflineQueue] Sync complete — synced: $synced, '
        'failed: $failed, remaining: ${remaining.length}',
      );
    } finally {
      _isSyncing = false;
    }

    return SyncResult(
      synced: synced,
      failed: failed,
      remaining: remaining.length,
    );
  }

  /// Remove a specific action from the queue by id
  Future<void> removeAction(String actionId) async {
    final queue = await getQueue();
    queue.removeWhere((a) => a.id == actionId);
    await _saveQueue(queue);
  }

  /// Clear the entire queue
  Future<void> clearQueue() async {
    await _saveQueue([]);
  }

  Future<int> get queueLength async => (await getQueue()).length;
}

/// Result of a sync operation
class SyncResult {
  final int synced;
  final int failed;
  final int remaining;

  const SyncResult({
    required this.synced,
    required this.failed,
    required this.remaining,
  });

  @override
  String toString() =>
      'SyncResult(synced: $synced, failed: $failed, remaining: $remaining)';
}
