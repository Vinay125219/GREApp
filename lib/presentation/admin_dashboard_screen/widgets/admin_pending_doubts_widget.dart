import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class AdminPendingDoubtsWidget extends StatefulWidget {
  const AdminPendingDoubtsWidget({super.key});

  @override
  State<AdminPendingDoubtsWidget> createState() =>
      _AdminPendingDoubtsWidgetState();
}

class _AdminPendingDoubtsWidgetState extends State<AdminPendingDoubtsWidget> {
  bool _isLoading = true;
  List<DoubtItem> _doubts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doubts = await SupabaseService.instance.fetchAllDoubts(
        status: 'open',
        pageSize: 5,
      );
      if (mounted) {
        setState(() {
          _doubts = doubts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Doubts',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Student questions awaiting reply',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/admin-doubts-screen',
                  ).then((_) => _load()),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: List.generate(
                  3,
                  (i) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonCard(),
                  ),
                ),
              ),
            )
          else if (_doubts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 48,
                      color: AppTheme.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No pending doubts',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student doubts will appear here',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _doubts.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final doubt = _doubts[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/admin-doubt-reply-screen',
                    arguments: doubt,
                  ).then((_) => _load()),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_rounded,
                      size: 18,
                      color: AppTheme.error,
                    ),
                  ),
                  title: Text(
                    doubt.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _timeAgo(doubt.createdAt),
                    style: theme.textTheme.labelSmall,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
