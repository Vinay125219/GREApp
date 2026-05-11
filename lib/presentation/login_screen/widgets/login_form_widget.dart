import '../../../core/app_export.dart';

class LoginFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback? onForgotPassword;

  const LoginFormWidget({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onLogin,
    this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email / Username',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: usernameController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Enter your email or username',
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email or username';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Password field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onLogin(),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: AppTheme.textMuted,
                  ),
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (onForgotPassword != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Error message
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppTheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Login button
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.primary.withValues(
                  alpha: 0.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
