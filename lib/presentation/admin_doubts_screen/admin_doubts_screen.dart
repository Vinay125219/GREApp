import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Admin screen to view all student doubts and navigate to reply threads
class AdminDoubtsScreen extends StatefulWidget {
  const AdminDoubtsScreen({super.key});

  @override
  State<AdminDoubtsScreen> createState() => _AdminDoubtsScreenState();
}

class _AdminDoubtsScreenState extends State<AdminDoubtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<DoubtItem> _doubts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoubts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDoubts({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final doubts = await SupabaseService.instance.fetchAllDoubts(
        pageSize: 50,
      );
      if (mounted) {
        setState(() {
          _doubts = doubts;
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

  List<DoubtItem> _filtered(String status) {
    if (status == 'all') return _doubts;
    return _doubts.where((d) => d.status == status).toList();
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
                          'Student Doubts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: _loadDoubts,
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
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: 'All (${_doubts.length})'),
                      Tab(text: 'Open (${_filtered('open').length})'),
                      Tab(text: 'Answered (${_filtered('answered').length})'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
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
                            'Failed to load doubts',
                            style: theme.textTheme.titleSmall,
                          ),
                          TextButton(
                            onPressed: _loadDoubts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_filtered('all'), theme),
                        _buildList(_filtered('open'), theme),
                        _buildList(_filtered('answered'), theme),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<DoubtItem> doubts, ThemeData theme) {
    if (doubts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 64,
              color: AppTheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No doubts',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDoubts,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doubts.length,
        itemBuilder: (context, index) {
          final doubt = doubts[index];
          final isAnswered = doubt.status == 'answered';
          final statusColor = isAnswered ? AppTheme.success : AppTheme.warning;

          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/admin-doubt-reply-screen',
              arguments: doubt,
            ).then((_) => _loadDoubts()),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doubt.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            isAnswered ? 'Answered' : 'Open',
                            style: TextStyle(
                              fontFamily: 'IBM Plex Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doubt.body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _timeAgo(doubt.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.reply_rounded,
                                size: 12,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAnswered ? 'View Thread' : 'Reply',
                                style: const TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
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
        },
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
