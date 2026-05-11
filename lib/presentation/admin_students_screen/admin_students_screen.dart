import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_navigation.dart';
import '../admin_add_student_screen/admin_add_student_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await SupabaseService.instance.fetchAllStudents(
        pageSize: 100,
      );
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) {
      final name = (s['full_name'] as String? ?? '').toLowerCase();
      final email = (s['email'] as String? ?? '').toLowerCase();
      final username = (s['username'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || username.contains(q);
    }).toList();
  }

  Future<void> _openAddStudent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminAddStudentScreen()),
    );
    if (result == true) _loadStudents();
  }

  Future<void> _openEditStudent(Map<String, dynamic> student) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminAddStudentScreen(existingStudent: student),
      ),
    );
    if (result == true) _loadStudents();
  }

  Future<void> _toggleActive(Map<String, dynamic> student) async {
    final current = student['is_active'] as bool? ?? true;
    final name = student['full_name'] as String? ?? 'this student';
    final action = current ? 'Deactivate' : 'Activate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Account'),
        content: Text('$action account for $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: current ? AppTheme.error : AppTheme.success,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await SupabaseService.instance.toggleStudentActive(
        student['id'] as String,
        !current,
      );
      _loadStudents();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update account status'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _onAdminNavDestination(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboardScreen);
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.adminContentScreen);
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
      floatingActionButton: _students.isEmpty && _searchQuery.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddStudent,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text(
                'Add Student',
                style: TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: AdaptiveScaffoldBody(
        navigationRail: AdminNavigationRail(
          currentIndex: 1,
          onDestinationSelected: _onAdminNavDestination,
        ),
        child: SafeArea(child: _buildStudentsShell(theme)),
      ),
    );
  }

  Widget _buildStudentsShell(ThemeData theme) {
    return Column(
      children: [
        _buildStudentsHeader(theme),
        Expanded(child: _buildStudentsBody(theme)),
      ],
    );
  }

  Widget _buildStudentsHeader(ThemeData theme) {
    final compact = context.isCompact;
    return Material(
      color: AppTheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxContent,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 4 : 16,
              8,
              compact ? 16 : 24,
              12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (context.isWide)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: AppTheme.primary,
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
                        'Students',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_students.length}',
                        style: const TextStyle(
                          fontFamily: 'IBM Plex Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or username...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
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

  Widget _buildStudentsBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: AppTheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No students enrolled yet'
                    : 'No students found',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _openAddStudent,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add First Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: context.adaptivePagePadding(bottom: 112),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final student = _filtered[index];
          return AdaptiveListItem(
            child: _StudentCard(
              student: student,
              onEdit: () => _openEditStudent(student),
              onToggleActive: () => _toggleActive(student),
            ),
          );
        },
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = student['full_name'] as String? ?? 'Unknown';
    final email = student['email'] as String? ?? '';
    final username = student['username'] as String?;
    final isActive = student['is_active'] as bool? ?? true;
    final expiresAtStr = student['account_expires_at'] as String?;
    final expiresAt = expiresAtStr != null
        ? DateTime.tryParse(expiresAtStr)
        : null;
    final joinedAt = student['created_at'] != null
        ? DateTime.tryParse(student['created_at'] as String)
        : null;

    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    // Expiry status
    bool isExpired = false;
    bool expiresSoon = false;
    int? daysLeft;
    if (expiresAt != null) {
      final now = DateTime.now();
      daysLeft = expiresAt.difference(now).inDays;
      isExpired = expiresAt.isBefore(now);
      expiresSoon = !isExpired && daysLeft <= 30;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isExpired
            ? Border.all(color: AppTheme.error.withValues(alpha: 0.4))
            : expiresSoon
            ? Border.all(color: AppTheme.warning.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isExpired
                      ? AppTheme.errorContainer
                      : AppTheme.primaryContainer,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isExpired ? AppTheme.error : AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (username != null && username.isNotEmpty)
                        Text(
                          '@$username',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        email,
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (joinedAt != null)
                        Text(
                          'Joined ${_fmtDate(joinedAt)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
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
                            ? AppTheme.successContainer
                            : AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Expiry badge
                    if (expiresAt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? AppTheme.errorContainer
                              : expiresSoon
                              ? AppTheme.warningContainer
                              : AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isExpired ? 'Expired' : 'Exp ${_fmtDate(expiresAt)}',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isExpired
                                ? AppTheme.error
                                : expiresAt.difference(DateTime.now()).inDays <=
                                      30
                                ? AppTheme.warning
                                : AppTheme.textSecondary,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'No Expiry',
                          style: TextStyle(
                            fontFamily: 'IBM Plex Mono',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Action row
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(width: 1, height: 32, color: AppTheme.outlineVariant),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onToggleActive,
                    icon: Icon(
                      isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 15,
                    ),
                    label: Text(
                      isActive ? 'Deactivate' : 'Activate',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: isActive
                          ? AppTheme.error
                          : AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
