import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_navigation.dart';
import './widgets/admin_batch_chart_widget.dart';
import './widgets/admin_kpi_grid_widget.dart';
import './widgets/admin_pending_doubts_widget.dart';
import './widgets/admin_quick_actions_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppRoutes.adminStudentsScreen);
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.adminContentScreen);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.adminAnalyticsScreen);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.adminSettingsScreen);
        break;
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of the admin panel?',
        ),
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
                  (route) => false,
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
    final isWide = context.isWide;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: isWide ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
      bottomNavigationBar: isWide
          ? null
          : AdminBottomNavigation(
              currentIndex: _currentNavIndex,
              onDestinationSelected: _onNavTap,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.adminContentScreen),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Content',
          style: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          floating: true,
          snap: true,
          toolbarHeight: 60,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GREApp Admin',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Institute Control Panel',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textSecondary,
              ),
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.notificationsScreen),
            ),
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppTheme.textSecondary,
              ),
              onPressed: _handleLogout,
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdminGreeting(),
                const SizedBox(height: 20),
                const AdminKpiGridWidget(),
                const SizedBox(height: 20),
                const AdminBatchChartWidget(),
                const SizedBox(height: 20),
                const AdminPendingDoubtsWidget(),
                const SizedBox(height: 20),
                const AdminQuickActionsWidget(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        SafeArea(
          right: false,
          bottom: false,
          child: AdminNavigationRail(
            currentIndex: _currentNavIndex,
            onDestinationSelected: _onNavTap,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AdaptivePageBody(
                  padding: context.adaptivePagePadding(
                    bottom: MediaQuery.of(context).padding.bottom + 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdminGreeting(),
                      const SizedBox(height: 20),
                      const AdminKpiGridWidget(),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: AdminBatchChartWidget()),
                          const SizedBox(width: 16),
                          const Expanded(child: AdminPendingDoubtsWidget()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const AdminQuickActionsWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, Admin 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s your institute overview',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
