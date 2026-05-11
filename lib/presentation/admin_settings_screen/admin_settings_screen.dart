import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await SupabaseService.instance.fetchCurrentUserProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
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
    final name = _profile?['full_name'] as String? ?? 'Admin';
    final email = _profile?['email'] as String? ?? '';
    final initials = name.trim().isEmpty
        ? 'A'
        : name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

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
                'Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                          // Admin profile card
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
                                  radius: 32,
                                  backgroundColor: AppTheme.primaryContainer,
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontFamily: 'IBM Plex Sans',
                                      fontSize: 20,
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
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Text(
                                          'Admin',
                                          style: TextStyle(
                                            fontFamily: 'IBM Plex Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Institute Settings',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsTile(
                            icon: Icons.business_rounded,
                            label: 'Institute Profile',
                            subtitle: 'Name, logo, contact info',
                            onTap: () {},
                          ),
                          _SettingsTile(
                            icon: Icons.groups_rounded,
                            label: 'Batch Management',
                            subtitle: 'Create and manage batches',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.adminContentScreen,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.campaign_rounded,
                            label: 'Send Announcement',
                            subtitle: 'Notify all students',
                            onTap: () {},
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Account',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsTile(
                            icon: Icons.lock_outline_rounded,
                            label: 'Change Password',
                            subtitle: 'Update your password',
                            onTap: () {},
                          ),
                          _SettingsTile(
                            icon: Icons.notifications_outlined,
                            label: 'Notifications',
                            subtitle: 'Manage notification preferences',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.notificationsScreen,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            label: 'About GREApp',
                            subtitle: 'Version 1.0.0',
                            onTap: () {},
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Developer Tools',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SettingsTile(
                            icon: Icons.assessment_rounded,
                            label: 'Reports & Analytics',
                            subtitle:
                                'Test results, student progress, batch analytics',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.adminReportingScreen,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.verified_user_outlined,
                            label: 'DB Integrity Checks',
                            subtitle: 'RLS policies & data consistency audit',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.adminIntegrityScreen,
                            ),
                          ),
                          const SizedBox(height: 20),
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
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
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            color: AppTheme.textMuted,
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
