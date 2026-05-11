import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/login_form_widget.dart';
import './widgets/login_header_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with Riverpod/Bloc for production auth state
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // SystemChrome.setSystemUIOverlayStyle is a no-op on Flutter Web
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    }
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Ensure Supabase is initialized before attempting login
      if (!SupabaseService.isInitialized) {
        await SupabaseService.initialize();
      }

      if (!SupabaseService.isInitialized) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Authentication service is not configured. Please contact support.';
        });
        return;
      }

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final user = response.user;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Invalid credentials. Please check your email and password.';
        });
        return;
      }

      // Determine role from user metadata
      final role = (user.userMetadata?['role'] as String? ?? '').toLowerCase();

      setState(() => _isLoading = false);

      if (role == 'admin' || role == 'super_admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboardScreen);
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentDashboardScreen,
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Invalid credentials. Please check your email and password.';
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[LoginScreen] Login error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const LoginHeaderWidget(),
          const SizedBox(height: 40),
          LoginFormWidget(
            formKey: _formKey,
            usernameController: _usernameController,
            passwordController: _passwordController,
            obscurePassword: _obscurePassword,
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onLogin: _handleLogin,
            onForgotPassword: _showForgotPasswordDialog,
          ),
          const SizedBox(height: 8),
          _buildCredentialsCard(),
          const SizedBox(height: 32),
          _buildFooter(Theme.of(context)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailCtrl = TextEditingController(
      text: _usernameController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    bool isSending = false;
    bool sent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          content: sent
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_read_rounded,
                      size: 48,
                      color: AppTheme.success,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Password reset email sent to ${emailCtrl.text}. Check your inbox.',
                      style: const TextStyle(
                        fontFamily: 'IBM Plex Sans',
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Enter your email address and we\'ll send you a link to reset your password.',
                        style: TextStyle(
                          fontFamily: 'IBM Plex Sans',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!v.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
          actions: sent
              ? [
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSending
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSending = true);
                            try {
                              await Supabase.instance.client.auth
                                  .resetPasswordForEmail(
                                    emailCtrl.text.trim(),
                                    redirectTo:
                                        'https://coachlms1429.builtwithrocket.new/reset-password',
                                  );
                              setDialogState(() {
                                sent = true;
                                isSending = false;
                              });
                            } catch (e) {
                              setDialogState(() => isSending = false);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Reset Link'),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    final theme = Theme.of(context);
    final formPanel = _buildLoginFormPanel();

    if (!context.isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LoginHeaderWidget(),
                const SizedBox(height: 32),
                formPanel,
                const SizedBox(height: 20),
                _buildCredentialsCard(),
                const SizedBox(height: 24),
                _buildFooter(theme),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: AdaptivePageBody(
        maxWidth: 1080,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildDesktopBrandPane(theme)),
            const SizedBox(width: 56),
            SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    formPanel,
                    const SizedBox(height: 20),
                    _buildCredentialsCard(),
                    const SizedBox(height: 24),
                    _buildFooter(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginFormPanel() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LoginFormWidget(
        formKey: _formKey,
        usernameController: _usernameController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onTogglePassword: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        onLogin: _handleLogin,
        onForgotPassword: _showForgotPasswordDialog,
      ),
    );
  }

  Widget _buildDesktopBrandPane(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'GREApp',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Focused preparation for ambitious learners and coaching teams.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['GRE', 'GMAT', 'SAT', 'ACT', 'CAT'].map((exam) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Text(
                  exam,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFF59E0B),
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              'Demo Accounts — tap to autofill',
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _usernameController.text = 'admin@coachlms.in';
                    _passwordController.text = 'CoachAdmin#2026';
                    _obscurePassword = false;
                  });
                },
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                label: const Text(
                  'Admin Login',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _usernameController.text = 'student@coachlms.in';
                    _passwordController.text = 'CoachStudent#2026';
                    _obscurePassword = false;
                  });
                },
                icon: const Icon(Icons.school_rounded, size: 16),
                label: const Text(
                  'Student Login',
                  style: TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondary,
                  side: BorderSide(color: AppTheme.secondary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Secured by ', style: theme.textTheme.labelSmall),
            const Icon(Icons.lock_rounded, size: 11, color: AppTheme.textMuted),
            Text(
              ' Supabase Auth · RLS Enabled',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '© 2026 GREApp Platform. All rights reserved.',
          style: theme.textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
