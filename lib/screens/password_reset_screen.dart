import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/firebase_action_code.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';
import '../providers/app_providers.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({required this.actionUri, super.key});

  final Uri actionUri;

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  late final String? _code = findFirebaseActionCode(widget.actionUri);
  String? _email;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _code;
    if (code == null || code.isEmpty) {
      setState(() {
        _error = context.l10n.resetCodeMissing;
        _loading = false;
      });
      return;
    }

    try {
      final email =
          await ref.read(authServiceProvider).verifyPasswordResetCode(code);
      if (!mounted) return;
      setState(() {
        _email = email;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final code = _code;
    if (code == null || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(authServiceProvider).confirmPasswordReset(
              code: code,
              newPassword: _password.text,
            );
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.passwordUpdatedSignIn)),
        );
        context.go(Routes.login);
      } catch (error) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildInvalidLink(context, colors)
                      : _buildPasswordForm(context, colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidLink(BuildContext context, AppPalette colors) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.resetLinkInvalidTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.resetLinkInvalidBody,
          style: TextStyle(height: 1.5, color: colors.muted),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.go(Routes.login),
          child: Text(l10n.backToSignIn),
        ),
      ],
    );
  }

  Widget _buildPasswordForm(BuildContext context, AppPalette colors) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chooseNewPassword,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (_email != null) ...[
            const SizedBox(height: 8),
            Text(
              _email!,
              style: TextStyle(fontSize: 14, color: colors.muted),
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _password,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: l10n.newPassword,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if ((value ?? '').length < 6) {
                return l10n.passwordMinLength;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPassword,
            obscureText: _obscureConfirmation,
            keyboardType: TextInputType.visiblePassword,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.confirmNewPassword,
              suffixIcon: IconButton(
                onPressed: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                value != _password.text ? l10n.passwordsDoNotMatch : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.updatePassword),
          ),
        ],
      ),
    );
  }
}
