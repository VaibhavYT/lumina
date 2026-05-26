import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_motion.dart';
import 'package:lumina/core/theme/app_radius.dart';
import 'package:lumina/core/theme/app_spacing.dart';
import 'package:lumina/core/utils/haptic_utils.dart';
import 'package:lumina/features/auth/data/auth_repository.dart';
import 'package:lumina/shared/widgets/lumina_button.dart';
import 'package:lumina/shared/widgets/lumina_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticUtils.medium();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final response = _isSignUp
          ? await auth.signUp(
              email: _emailController.text,
              password: _passwordController.text,
              displayName: _nameController.text,
            )
          : await auth.signIn(
              email: _emailController.text,
              password: _passwordController.text,
            );

      if (!mounted) {
        return;
      }

      if (_isSignUp && response.session == null) {
        _showMessage(
          'Account created. Check your email to confirm your account, then sign in.',
        );
        setState(() => _isSignUp = false);
      }
    } on AuthException catch (error) {
      if (mounted) {
        _showMessage(error.message, isError: true);
      }
    } on Object {
      if (mounted) {
        _showMessage('Authentication failed. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode() {
    HapticUtils.selection();
    setState(() => _isSignUp = !_isSignUp);
  }

  void _showMessage(String message, {bool isError = false}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? colors.errorSoft : colors.successSoft,
          content: Text(
            message,
            style: context.textTheme.bodyMedium?.copyWith(
              color: isError ? colors.errorColor : colors.successColor,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: context.isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: colors.backgroundPrimary,
        systemNavigationBarIconBrightness: context.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: colors.backgroundPrimary,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 48 : AppSpacing.pagePadding,
                  AppSpacing.lg,
                  isWide ? 48 : AppSpacing.pagePadding,
                  AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AppSpacing.xl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: isWide
                          ? Row(
                              children: [
                                const Expanded(child: _AuthBrandPanel()),
                                const SizedBox(width: AppSpacing.xl),
                                Expanded(child: _buildFormCard()),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _AuthBrandPanel(compact: true),
                                const SizedBox(height: AppSpacing.lg),
                                _buildFormCard(),
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final colors = context.colors;

    return LuminaCard(
      borderRadius: AppRadius.radiusLg,
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ModePill(
                    label: 'Sign in',
                    isSelected: !_isSignUp,
                    onTap: _isSignUp ? _toggleMode : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ModePill(
                    label: 'Create',
                    isSelected: _isSignUp,
                    onTap: _isSignUp ? null : _toggleMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: Text(
                _isSignUp ? 'Create your account' : 'Welcome back',
                key: ValueKey(_isSignUp),
                style: context.textTheme.displaySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isSignUp
                  ? 'Start syncing your daily growth securely.'
                  : 'Continue where your last session left off.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: AppMotion.fast,
              child: _isSignUp
                  ? Padding(
                      key: const ValueKey('name-field'),
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(PhosphorIcons.user()),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('name-empty')),
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(PhosphorIcons.envelopeSimple()),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Enter your email.';
                }
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Enter a valid email.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: _isSignUp
                  ? const [AutofillHints.newPassword]
                  : const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(PhosphorIcons.lockKey()),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    HapticUtils.selection();
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? PhosphorIcons.eye()
                        : PhosphorIcons.eyeSlash(),
                  ),
                ),
              ),
              validator: (value) {
                final password = value ?? '';
                if (password.isEmpty) {
                  return 'Enter your password.';
                }
                if (_isSignUp && password.length < 8) {
                  return 'Use at least 8 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LuminaButton(
              label: _isSignUp ? 'Create account' : 'Sign in',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _submit,
              icon: _isSignUp
                  ? PhosphorIcons.userPlus()
                  : PhosphorIcons.signIn(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isSignUp
                  ? 'Your account is protected by Supabase Auth. You may need to confirm your email before the first login.'
                  : 'Your session is restored automatically on this device after login.',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBrandPanel extends StatelessWidget {
  const _AuthBrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primaryAccentSoft,
              borderRadius: BorderRadius.circular(AppRadius.radiusMd),
              border: Border.all(color: colors.divider),
            ),
            child: Icon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
              color: colors.primaryAccent,
              size: 30,
            ),
          ),
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
          Text('Lumina', style: context.textTheme.displayLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A private space for mood, energy, habits, and mentor guidance.',
            style: context.textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpacing.xl),
            const _TrustRow(
              icon: Icons.verified_user_outlined,
              title: 'Persistent sessions',
              body: 'Sign in once and return without repeating the login flow.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _TrustRow(
              icon: Icons.sync_lock_outlined,
              title: 'Secure sync',
              body:
                  'Your growth data syncs through protected backend functions.',
            ),
          ],
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.secondaryAccentSoft,
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Icon(icon, color: colors.secondaryAccent, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                body,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryAccent : colors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.divider,
          ),
        ),
        child: Text(
          label,
          style: context.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? context.isDark
                      ? colors.backgroundPrimary
                      : Colors.white
                : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
