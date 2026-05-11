import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<NotificationItem> _notifications = [];
  RealtimeChannel? _realtimeChannel;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtime() {
    final uid = SupabaseService.instance.currentUserId;
    if (uid == null) return;

    _realtimeChannel = SupabaseService.instance.client
        .channel('notifications_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (payload) {
            if (!mounted) return;
            try {
              final newNotif = NotificationItem.fromJson(payload.newRecord);
              setState(() {
                _notifications.insert(0, newNotif);
              });
              _showInAppBanner(newNotif);
            } catch (_) {}
          },
        )
        .subscribe();
  }

  void _showInAppBanner(NotificationItem notif) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_iconForType(notif.type), color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    notif.body,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _colorForType(notif.type),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final uid = SupabaseService.instance.currentUserId;
      final List<NotificationItem> items;
      if (uid == null) {
        items = [];
      } else {
        final resp = await SupabaseService.instance.client
            .from('notifications')
            .select('*')
            .eq('user_id', uid)
            .order('created_at', ascending: false);
        items = (resp as List<dynamic>)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    final uid = SupabaseService.instance.currentUserId;
    if (uid != null) {
      await SupabaseService.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    }
    setState(() {
      _notifications = _notifications
          .map(
            (n) => NotificationItem(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
              metadata: n.metadata,
            ),
          )
          .toList();
    });
  }

  Future<void> _handleNotificationTap(NotificationItem notif, int index) async {
    // Mark as read
    if (!notif.isRead) {
      await SupabaseService.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notif.id);
      if (mounted) {
        setState(() {
          _notifications[index] = NotificationItem(
            id: notif.id,
            title: notif.title,
            body: notif.body,
            type: notif.type,
            isRead: true,
            createdAt: notif.createdAt,
            metadata: notif.metadata,
          );
        });
      }
    }

    final meta = notif.metadata;

    // Navigate for test submission notifications
    if (notif.type == 'test' && meta != null && meta['attempt_id'] != null) {
      final attemptId = meta['attempt_id'] as String;
      if (_isNavigating) return;
      setState(() => _isNavigating = true);

      try {
        final result = await SupabaseService.instance.fetchTestAttemptForAdmin(
          attemptId,
        );
        if (!mounted) return;
        if (result != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.testReviewScreen,
            arguments: result,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load test submission details.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open test submission.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isNavigating = false);
      }
      return;
    }

    // Navigate for doubt notifications
    if (notif.type == 'doubt' && meta != null && meta['doubt_id'] != null) {
      final doubtId = meta['doubt_id'] as String;
      if (_isNavigating) return;
      setState(() => _isNavigating = true);

      try {
        final doubt = await SupabaseService.instance.fetchDoubtById(doubtId);
        if (!mounted) return;
        if (doubt != null) {
          // Determine route based on user role
          final profile = await SupabaseService.instance
              .fetchCurrentUserProfile();
          if (!mounted) return;
          final role = profile?['role'] as String? ?? 'student';
          final isAdmin = role == 'admin' || role == 'super_admin';
          Navigator.pushNamed(
            context,
            isAdmin
                ? AppRoutes.adminDoubtReplyScreen
                : AppRoutes.studentDoubtThreadScreen,
            arguments: doubt,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load doubt details.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open doubt thread.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isNavigating = false);
      }
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'test':
        return Icons.assignment_rounded;
      case 'doubt':
        return Icons.help_rounded;
      case 'course':
        return Icons.menu_book_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'test':
        return AppTheme.primary;
      case 'doubt':
        return AppTheme.error;
      case 'course':
        return AppTheme.secondary;
      case 'announcement':
        return AppTheme.warning;
      default:
        return AppTheme.info;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
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
                    'Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Realtime indicator
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: AppTheme.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: AppTheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see live updates here',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: context.adaptivePagePadding(bottom: 32),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          final typeColor = _colorForType(notif.type);
                          final isTestSubmission =
                              notif.type == 'test' &&
                              notif.metadata != null &&
                              notif.metadata!['attempt_id'] != null;
                          final isDoubtNotification =
                              notif.type == 'doubt' &&
                              notif.metadata != null &&
                              notif.metadata!['doubt_id'] != null;
                          final isTappable =
                              isTestSubmission || isDoubtNotification;
                          return AdaptiveListItem(
                            child: GestureDetector(
                              onTap: () => _handleNotificationTap(notif, index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: notif.isRead
                                      ? AppTheme.surface
                                      : AppTheme.primaryContainer.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: notif.isRead
                                        ? Colors.transparent
                                        : AppTheme.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _iconForType(notif.type),
                                        size: 18,
                                        color: typeColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelLarge
                                                      ?.copyWith(
                                                        fontWeight: notif.isRead
                                                            ? FontWeight.w500
                                                            : FontWeight.w700,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!notif.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: AppTheme.primary,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.body,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                _timeAgo(notif.createdAt),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: AppTheme.textMuted,
                                                    ),
                                              ),
                                              if (isTappable) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: typeColor.withValues(
                                                      alpha: 0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    isTestSubmission
                                                        ? 'Tap to review'
                                                        : 'Tap to view',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: typeColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isTappable)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
