import '../core/app_export.dart';

class StudentBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const StudentBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      animationDuration: const Duration(milliseconds: 300),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'Courses',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Tests',
        ),
        NavigationDestination(
          icon: Icon(Icons.help_outline_rounded),
          selectedIcon: Icon(Icons.help_rounded),
          label: 'Doubts',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

class StudentNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const StudentNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppTheme.surface,
      useIndicator: true,
      indicatorColor: AppTheme.primaryContainer,
      labelType: context.isDesktop
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      extended: context.isDesktop,
      minExtendedWidth: 188,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primary),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded, color: AppTheme.primary),
          label: Text('Courses'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded, color: AppTheme.primary),
          label: Text('Tests'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.help_outline_rounded),
          selectedIcon: Icon(Icons.help_rounded, color: AppTheme.primary),
          label: Text('Doubts'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
          label: Text('Profile'),
        ),
      ],
    );
  }
}

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      animationDuration: const Duration(milliseconds: 300),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(Icons.space_dashboard_rounded),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Students',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(Icons.library_books_rounded),
          label: 'Content',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_rounded),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}

class AdminNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppTheme.surface,
      useIndicator: true,
      indicatorColor: AppTheme.primaryContainer,
      labelType: context.isDesktop
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      extended: context.isDesktop,
      minExtendedWidth: 196,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.space_dashboard_outlined),
          selectedIcon: Icon(
            Icons.space_dashboard_rounded,
            color: AppTheme.primary,
          ),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded, color: AppTheme.primary),
          label: Text('Students'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.library_books_outlined),
          selectedIcon: Icon(
            Icons.library_books_rounded,
            color: AppTheme.primary,
          ),
          label: Text('Content'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.bar_chart_rounded),
          selectedIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
          label: Text('Analytics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.primary),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
