import 'package:flutter/services.dart';

import '../../../core/app_export.dart';

class DemoCredentialsWidget extends StatelessWidget {
  final String studentEmail;
  final String studentPassword;
  final String adminEmail;
  final String adminPassword;
  final Function(String email, String password) onAutofill;

  const DemoCredentialsWidget({
    super.key,
    required this.studentEmail,
    required this.studentPassword,
    required this.adminEmail,
    required this.adminPassword,
    required this.onAutofill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.infoContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.info,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Test Accounts',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _CredentialRow(
            role: 'Student',
            roleColor: AppTheme.secondary,
            roleBgColor: AppTheme.secondaryContainer,
            email: studentEmail,
            password: studentPassword,
            onUse: () => onAutofill(studentEmail, studentPassword),
          ),
          const Divider(height: 1, indent: 16),
          _CredentialRow(
            role: 'Admin',
            roleColor: AppTheme.primary,
            roleBgColor: AppTheme.primaryContainer,
            email: adminEmail,
            password: adminPassword,
            onUse: () => onAutofill(adminEmail, adminPassword),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final String role;
  final Color roleColor;
  final Color roleBgColor;
  final String email;
  final String password;
  final VoidCallback onUse;

  const _CredentialRow({
    required this.role,
    required this.roleColor,
    required this.roleBgColor,
    required this.email,
    required this.password,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'IBM Plex Mono',
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  password,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'IBM Plex Mono',
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: '$email\n$password'));
            },
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.copy_rounded,
                size: 15,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton(
            onPressed: onUse,
            style: FilledButton.styleFrom(
              backgroundColor: roleColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Use',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
