import '../../../core/app_export.dart';

class LoginHeaderWidget extends StatelessWidget {
  const LoginHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome back',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to your GREApp account',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          children: ['GRE', 'GMAT', 'SAT', 'ACT', 'CAT'].map((exam) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                exam,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
