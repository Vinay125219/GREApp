import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  int _testsTaken = 0;
  int _coursesEnrolled = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.instance.fetchCurrentUserProfile();
      final kpi = await SupabaseService.instance.fetchStudentKpi();
      final courses = await SupabaseService.instance.fetchCourseProgress(
        pageSize: 100,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _testsTaken = kpi.testsTaken;
          _coursesEnrolled = courses.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.loginScreen,
                  (r) => false,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _profile?['full_name'] as String? ?? 'Student';
    final email = _profile?['email'] as String? ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();
    final joinedAt = _profile?['created_at'] != null
        ? DateTime.tryParse(_profile!['created_at'] as String)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              scrolledUnderElevation: 1,
              floating: true,
              snap: true,
              toolbarHeight: 56,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'My Profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
                  onPressed: _handleLogout,
                  tooltip: 'Sign Out',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile card
                          Container(
                            padding: const EdgeInsets.all(20),
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
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: AppTheme.primaryContainer,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontFamily: 'IBM Plex Sans',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                      if (joinedAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Joined ${_formatDate(joinedAt)}',
                                          style: theme.textTheme.labelSmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stats row
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Tests Taken',
                                  value: '$_testsTaken',
                                  icon: Icons.assignment_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Courses',
                                  value: '$_coursesEnrolled',
                                  icon: Icons.menu_book_rounded,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Settings section
                          Text(
                            'Settings',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.notificationsScreen,
                            ),
                          ),
                          _SettingsItem(
                            icon: Icons.help_outline_rounded,
                            label: 'My Doubts',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.studentDoubtsScreen,
                            ),
                          ),
                          _SettingsItem(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.info_outline_rounded,
                            label: 'About GREApp',
                            onTap: () {},
                          ),
                          const SizedBox(height: 20),
                          // Logout button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: AppTheme.error,
                              ),
                              label: const Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: AppTheme.error,
                                  fontFamily: 'IBM Plex Sans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.error),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'IBM Plex Mono',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textMuted,
          size: 20,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
