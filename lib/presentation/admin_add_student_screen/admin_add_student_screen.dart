
import '../../core/app_export.dart';
import '../../services/supabase_service.dart';

class AdminAddStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? existingStudent;

  const AdminAddStudentScreen({super.key, this.existingStudent});

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _noExpiry = false;
  DateTime? _expiryDate;

  bool get _isEditing => widget.existingStudent != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.existingStudent!;
      _fullNameCtrl.text = s['full_name'] as String? ?? '';
      _emailCtrl.text = s['email'] as String? ?? '';
      _usernameCtrl.text = s['username'] as String? ?? '';
      final expiresAt = s['account_expires_at'] as String?;
      if (expiresAt != null) {
        _expiryDate = DateTime.tryParse(expiresAt);
      } else {
        _noExpiry = true;
      }
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        );
        _noExpiry = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && !_noExpiry && _expiryDate == null) {
      _showSnack(
        'Please set an expiry date or select "No Expiry"',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await SupabaseService.instance.updateStudentAccount(
          studentId: widget.existingStudent!['id'] as String,
          fullName: _fullNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim().isEmpty
              ? null
              : _usernameCtrl.text.trim(),
          expiresAt: _noExpiry ? null : _expiryDate,
        );
        if (mounted) {
          _showSnack('Student account updated');
          Navigator.pop(context, true);
        }
      } else {
        await SupabaseService.instance.createStudentAccount(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          fullName: _fullNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim().isEmpty
              ? null
              : _usernameCtrl.text.trim(),
          expiresAt: _noExpiry ? null : _expiryDate,
        );
        if (mounted) {
          _showSnack('Student account created successfully');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnack(_friendlyError(e.toString()), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('already registered') ||
        raw.contains('already exists') ||
        raw.contains('duplicate') ||
        raw.contains('already been registered')) {
      return 'Email or username already exists';
    }
    if (raw.contains('password') && raw.contains('weak')) {
      return 'Password is too weak. Use at least 6 characters';
    }
    if (raw.contains('invalid') && raw.contains('email')) {
      return 'Invalid email address';
    }
    if (raw.contains('Admin access required') ||
        raw.contains('Unauthorized') ||
        raw.contains('403')) {
      return 'Permission denied. Please log in as admin again.';
    }
    // Show the actual error message for easier debugging
    final cleaned = raw.replaceAll('Exception: ', '').trim();
    if (cleaned.isNotEmpty && cleaned.length < 120) return cleaned;
    return 'Something went wrong. Please try again.';
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    _isEditing ? 'Edit Student' : 'Add Student',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Info Section
                      _sectionLabel(
                        'Account Information',
                        Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _fullNameCtrl,
                        label: 'Full Name',
                        hint: 'e.g. Rahul Sharma',
                        icon: Icons.badge_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hint: 'student@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        readOnly: _isEditing,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w.-]+@[\w.-]+\.\w+$',
                          ).hasMatch(v.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _usernameCtrl,
                        label: 'Username (optional)',
                        hint: 'e.g. rahul2024',
                        icon: Icons.alternate_email_rounded,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (v.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9_]+$',
                            ).hasMatch(v.trim())) {
                              return 'Only letters, numbers, and underscores allowed';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Password Section (only for new students)
                      if (!_isEditing) ...[
                        _sectionLabel(
                          'Set Password',
                          Icons.lock_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          hint: 'Min. 8 characters',
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPasswordField(
                          controller: _confirmPasswordCtrl,
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Expiry Section
                      _sectionLabel('Account Expiry', Icons.schedule_rounded),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: Column(
                          children: [
                            // No expiry toggle
                            SwitchListTile(
                              value: _noExpiry,
                              onChanged: (v) => setState(() {
                                _noExpiry = v;
                                if (v) _expiryDate = null;
                              }),
                              title: const Text(
                                'No Expiry',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              subtitle: const Text(
                                'Account remains active indefinitely',
                                style: TextStyle(
                                  fontFamily: 'IBM Plex Sans',
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              activeThumbColor: AppTheme.primary,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                            ),
                            if (!_noExpiry) ...[
                              const Divider(
                                height: 1,
                                color: AppTheme.outlineVariant,
                              ),
                              InkWell(
                                onTap: _pickExpiryDate,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _expiryDate != null
                                              ? AppTheme.primaryContainer
                                              : AppTheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.calendar_today_rounded,
                                          size: 18,
                                          color: _expiryDate != null
                                              ? AppTheme.primary
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Expiry Date',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _expiryDate != null
                                                  ? _formatDate(_expiryDate!)
                                                  : 'Tap to select date',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        _expiryDate != null
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: _expiryDate != null
                                                        ? AppTheme.textPrimary
                                                        : AppTheme.textMuted,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppTheme.textMuted,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Expiry info chip
                      if (!_noExpiry && _expiryDate != null) ...[
                        const SizedBox(height: 10),
                        _expiryInfoChip(),
                      ],

                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Save Changes'
                                      : 'Create Account',
                                  style: const TextStyle(
                                    fontFamily: 'IBM Plex Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'IBM Plex Sans',
        fontSize: 14,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textMuted),
        filled: true,
        fillColor: readOnly ? AppTheme.surfaceVariant : AppTheme.surface,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'IBM Plex Sans',
        fontSize: 14,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: AppTheme.textMuted,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: AppTheme.textMuted,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppTheme.surface,
      ),
    );
  }

  Widget _expiryInfoChip() {
    final daysLeft = _expiryDate!.difference(DateTime.now()).inDays;
    final isShort = daysLeft < 30;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isShort ? AppTheme.warningContainer : AppTheme.successContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: isShort ? AppTheme.warning : AppTheme.success,
          ),
          const SizedBox(width: 6),
          Text(
            'Access valid for $daysLeft day${daysLeft == 1 ? '' : 's'}',
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isShort ? AppTheme.warning : AppTheme.success,
            ),
          ),
        ],
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
