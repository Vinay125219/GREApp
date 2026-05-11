import '../../../core/app_export.dart';

class AdminQuickActionsWidget extends StatelessWidget {
  const AdminQuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      _QuickAction(
        label: 'Students',
        icon: Icons.person_add_rounded,
        color: AppTheme.primary,
        bg: AppTheme.primaryContainer,
        route: AppRoutes.adminStudentsScreen,
      ),
      _QuickAction(
        label: 'New Test',
        icon: Icons.add_task_rounded,
        color: AppTheme.secondary,
        bg: AppTheme.secondaryContainer,
        route: AppRoutes.adminContentScreen,
      ),
      _QuickAction(
        label: 'Content',
        icon: Icons.library_books_rounded,
        color: AppTheme.accent,
        bg: AppTheme.accentContainer,
        route: AppRoutes.adminContentScreen,
      ),
      _QuickAction(
        label: 'Analytics',
        icon: Icons.bar_chart_rounded,
        color: AppTheme.warning,
        bg: AppTheme.warningContainer,
        route: AppRoutes.adminAnalyticsScreen,
      ),
      _QuickAction(
        label: 'Reports',
        icon: Icons.assessment_rounded,
        color: AppTheme.info,
        bg: AppTheme.infoContainer,
        route: AppRoutes.adminReportingScreen,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions.asMap().entries.map((e) {
            final idx = e.key;
            final action = e.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: idx < actions.length - 1 ? 8 : 0,
                ),
                child: _QuickActionButton(action: action),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final String route;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.route,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, action.route),
      borderRadius: BorderRadius.circular(12),
      splashColor: action.color.withValues(alpha: 0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, size: 20, color: action.color),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
