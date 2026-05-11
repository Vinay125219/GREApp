import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

/// Admin screen to view and reply to a specific student doubt thread
class AdminDoubtReplyScreen extends StatefulWidget {
  const AdminDoubtReplyScreen({super.key});

  @override
  State<AdminDoubtReplyScreen> createState() => _AdminDoubtReplyScreenState();
}

class _AdminDoubtReplyScreenState extends State<AdminDoubtReplyScreen> {
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

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _doubt == null) return;

    setState(() => _isSending = true);
    try {
      await SupabaseService.instance.addDoubtReply(
        doubtId: _doubt!.id,
        body: text,
        isAdmin: true,
      );
      _replyCtrl.clear();
      await _loadThread();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: $e'),
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
                    onPressed: () => Navigator.pop(context, true),
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
                        doubt.status == 'answered' ? 'Answered' : 'Open',
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
            // Thread body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    )
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Original doubt bubble
                        if (doubt != null) _buildDoubtBubble(doubt, theme),
                        const SizedBox(height: 8),
                        // Reply bubbles
                        ..._replies.map((r) => _buildReplyBubble(r, theme)),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
            // Reply input
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
                        hintText: 'Type your reply...',
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
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    child: _isSending
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
                            onPressed: _sendReply,
                            icon: const Icon(Icons.send_rounded),
                            color: AppTheme.primary,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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

  Widget _buildDoubtBubble(DoubtItem doubt, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Student',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(doubt.createdAt),
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
                    color: AppTheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                ),
              ],
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
    final authorName =
        reply['author_name'] as String? ?? (isAdmin ? 'Instructor' : 'Student');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isAdmin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isAdmin) ...[
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
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAdmin
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAdmin)
                      Text(
                        _timeAgo(createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    if (isAdmin) const SizedBox(width: 8),
                    Text(
                      isAdmin ? '👨‍🏫 $authorName' : authorName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isAdmin ? AppTheme.secondary : AppTheme.primary,
                      ),
                    ),
                    if (!isAdmin) const SizedBox(width: 8),
                    if (!isAdmin)
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
                        ? AppTheme.secondary.withValues(alpha: 0.12)
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: isAdmin
                          ? const Radius.circular(12)
                          : Radius.zero,
                      topRight: isAdmin
                          ? Radius.zero
                          : const Radius.circular(12),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                    border: Border.all(
                      color: isAdmin
                          ? AppTheme.secondary.withValues(alpha: 0.3)
                          : AppTheme.outlineVariant,
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
          if (isAdmin) ...[
            const SizedBox(width: 8),
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
