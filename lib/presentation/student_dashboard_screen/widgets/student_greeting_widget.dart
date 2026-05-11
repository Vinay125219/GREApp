import '../../../core/app_export.dart';

class StudentGreetingWidget extends StatelessWidget {
  final String userName;

  const StudentGreetingWidget({super.key, this.userName = ''});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getInitials() {
    if (userName.trim().isEmpty) return '?';
    return userName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = userName.trim().isEmpty
        ? 'there'
        : userName.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $displayName 👋',
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back to your dashboard',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: Text(
              _getInitials(),
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
