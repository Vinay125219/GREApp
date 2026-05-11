import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Student-facing view of a doubt thread (read replies, add follow-up)
class StudentDoubtThreadScreen extends StatefulWidget {
  const StudentDoubtThreadScreen({super.key});

  @override
  State<StudentDoubtThreadScreen> createState() =>
      _StudentDoubtThreadScreenState();
}

class _StudentDoubtThreadScreenState extends State<StudentDoubtThreadScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _replies = [];
  DoubtItem? _doubt;
  String? _error;
  final TextEditingController _replyCtrl = TextEditingController();
  bool _isSending = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadThread());
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    DoubtItem? doubt;
    if (args is DoubtItem) {
      doubt = args;
    } else if (args is Map<String, dynamic>) {
      doubt = args['doubt'] as DoubtItem?;
    }

    if (doubt == null) {
      setState(() {
        _error = 'No doubt data provided.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _doubt = doubt;
      _isLoading = true;
      _error = null;
    });

    try {
      final replies = await SupabaseService.instance.fetchDoubtReplies(
        doubt.id,
      );
      if (mounted) {
        setState(() {
          _replies = replies;
          _isLoading = false;
        });
        _scrollToBottom();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendFollowUp() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _doubt == null) return;

    setState(() => _isSending = true);
    try {
      await SupabaseService.instance.addDoubtReply(
        doubtId: _doubt!.id,
        body: text,
        isAdmin: false,
      );
      _replyCtrl.clear();
      await _loadThread();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doubt = _doubt;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doubt Thread',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (doubt != null)
                          Text(
                            doubt.title,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (doubt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: doubt.status == 'answered'
                            ? AppTheme.successContainer
                            : AppTheme.warningContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        doubt.status == 'answered' ? '✓ Answered' : 'Open',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: doubt.status == 'answered'
                              ? AppTheme.success
                              : AppTheme.warning,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Thread
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
                          Text(_error!, style: theme.textTheme.bodySmall),
                          TextButton(
                            onPressed: _loadThread,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (doubt != null) _buildOriginalDoubt(doubt, theme),
                        const SizedBox(height: 8),
                        if (_replies.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.hourglass_empty_rounded,
                                    size: 40,
                                    color: AppTheme.outlineVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Awaiting instructor reply...',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._replies.map((r) => _buildReplyBubble(r, theme)),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
            // Follow-up input
            Container(
              color: AppTheme.surface,
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                MediaQuery.of(context).viewInsets.bottom + 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Add a follow-up question...',
                        hintStyle: const TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 14,
                          color: AppTheme.textMuted,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _sendFollowUp,
                          icon: const Icon(Icons.send_rounded),
                          color: AppTheme.primary,
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  Widget _buildOriginalDoubt(DoubtItem doubt, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Your Question',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                _timeAgo(doubt.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            doubt.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            doubt.body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBubble(Map<String, dynamic> reply, ThemeData theme) {
    final isAdmin = reply['is_admin'] as bool? ?? false;
    final body = reply['body'] as String? ?? '';
    final createdAt = reply['created_at'] != null
        ? DateTime.tryParse(reply['created_at'] as String) ?? DateTime.now()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 16,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAdmin ? '👨‍🏫 Instructor' : 'You',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isAdmin ? AppTheme.secondary : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeAgo(createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? AppTheme.secondary.withValues(alpha: 0.1)
                        : AppTheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.only(
                      topLeft: isAdmin
                          ? Radius.zero
                          : const Radius.circular(12),
                      topRight: isAdmin
                          ? const Radius.circular(12)
                          : Radius.zero,
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                    border: Border.all(
                      color: isAdmin
                          ? AppTheme.secondary.withValues(alpha: 0.25)
                          : AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
