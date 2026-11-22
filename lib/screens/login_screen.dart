import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../widgets/language_selector.dart';

/// Sign in / create account across Android, iOS and web with Firebase Auth.
///
/// Both supported sign-in paths are available on every target: Google and
/// email + password. An authenticated account is required to use the app.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  bool _creating = false;
  bool _busy = false;
  bool _resettingPassword = false;
  bool _obscure = true;
  late final TapGestureRecognizer _authModeRecognizer;

  @override
  void initState() {
    super.initState();
    _authModeRecognizer = TapGestureRecognizer()..onTap = _toggleAuthMode;
  }

  @override
  void dispose() {
    _authModeRecognizer.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    if (_busy) return;
    setState(() {
      _creating = !_creating;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final auth = ref.read(authServiceProvider);
      if (_creating) {
        await auth.registerWithEmail(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
        );
      } else {
        await auth.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
      }
      if (mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_creating ? l10n.accountCreated : l10n.welcomeBack),
          ),
        );
        context.go(Routes.home);
      }
    } on AuthFailure catch (error) {
      if (!mounted) return;
      final isDuplicateSignup =
          _creating && error.code == 'email-already-in-use';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          action: isDuplicateSignup
              ? SnackBarAction(
                  label: context.l10n.signIn,
                  onPressed: _toggleAuthMode,
                )
              : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.signInFailed)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      if (kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android)) {
        await runAction(
          context,
          () => ref.read(authServiceProvider).signInWithGoogleRedirect(),
        );
        return;
      }

      final error = await runAction(
        context,
        () => ref.read(authServiceProvider).signInWithGoogle(),
        successMessage: context.l10n.signedInWithGoogle,
      );
      if (error == null && mounted) {
        context.go(Routes.home);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_busy || _resettingPassword) return;
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forgotPasswordPrompt)),
      );
      return;
    }
    setState(() => _resettingPassword = true);
    try {
      await runAction(
        context,
        () => ref.read(authServiceProvider).sendPasswordReset(email),
        successMessage: context.l10n.resetLinkSent(email),
      );
    } finally {
      if (mounted) setState(() => _resettingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authError = ref.watch(activeAuthStateProvider).error;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: colors.canvas,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSelector(iconOnly: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    Text(
                      _creating
                          ? l10n.createYourAccount
                          : l10n.welcomeToDateDawn,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _creating
                          ? l10n.countdownsSyncDescription
                          : l10n.welcomeDescription,
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: colors.muted),
                    ),
                    const SizedBox(height: 28),
                    if (_creating) ...[
                      _Field(
                        controller: _name,
                        label: l10n.name,
                        hint: l10n.nameHint,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.nameRequired
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _Field(
                      controller: _email,
                      label: l10n.email,
                      hint: l10n.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return l10n.emailRequired;
                        if (!value.contains('@') || !value.contains('.')) {
                          return l10n.emailInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _password,
                      label: l10n.password,
                      hint: '••••••••',
                      obscure: _obscure,
                      keyboardType: TextInputType.visiblePassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                          color: colors.subtle,
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return l10n.passwordRequired;
                        if (_creating && (v ?? '').length < 6) {
                          return l10n.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                    if (!_creating)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy || _resettingPassword
                              ? null
                              : _forgotPassword,
                          child: _resettingPassword
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l10n.forgotPassword,
                                  style: const TextStyle(fontSize: 13),
                                ),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    if (authError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.signInConnectionError,
                        style: TextStyle(fontSize: 13, color: colors.danger),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const _ButtonSpinner()
                          : Text(
                              _creating ? l10n.createAccount : l10n.signIn,
                            ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.or,
                            style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                color: colors.subtle),
                          ),
                        ),
                        Expanded(child: Divider(color: colors.border)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _google,
                      icon: const _GoogleGlyph(),
                      label: Text(l10n.continueWithGoogle),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          key: const ValueKey('auth-mode-switch'),
                          TextSpan(
                            text: _creating
                                ? l10n.alreadyHaveAccount
                                : l10n.newHere,
                            style: TextStyle(fontSize: 13, color: colors.muted),
                            children: [
                              TextSpan(
                                text: _creating ? l10n.signIn : l10n.createOne,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.accent,
                                ),
                                recognizer: _authModeRecognizer,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          softWrap: false,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // The one place this link matters most. Somebody stuck on
                    // the login screen — wrong password, signed in with the
                    // other provider, account they cannot get into — is exactly
                    // who needs support, and until now the only way out was to
                    // guess a URL.
                    TextButton(
                      onPressed: () => context.push(Routes.support),
                      child: Text(
                        l10n.troubleSigningIn,
                        style: TextStyle(fontSize: 12.5, color: colors.subtle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool enableSuggestions;
  final bool autocorrect;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: context.colors.muted,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          enableSuggestions: enableSuggestions,
          autocorrect: autocorrect,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      ],
    );
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
          strokeWidth: 2, color: context.colors.accentFg),
    );
  }
}

/// The four-color Google G, drawn as the official four filled paths.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 25, size.height / 25);

    void fill(Color color, Path path) {
      canvas.drawPath(path, Paint()..color = color);
    }

    fill(
      const Color(0xFF4285F4),
      Path()
        ..moveTo(22.56, 12.25)
        ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10)
        ..lineTo(12, 10)
        ..lineTo(12, 14.26)
        ..lineTo(17.92, 14.26)
        ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
        ..lineTo(15.71, 20.34)
        ..lineTo(19.28, 20.34)
        ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
        ..close(),
    );
    fill(
      const Color(0xFF34A853),
      Path()
        ..moveTo(12, 24)
        ..cubicTo(14.97, 24, 17.46, 23.02, 19.28, 21.34)
        ..lineTo(15.71, 18.57)
        ..cubicTo(14.73, 19.23, 13.48, 19.63, 12, 19.63)
        ..cubicTo(9.14, 19.63, 6.71, 17.7, 5.84, 15.1)
        ..lineTo(2.18, 17.94)
        ..cubicTo(3.99, 21.54, 7.7, 24, 12, 24)
        ..close(),
    );
    fill(
      const Color(0xFFFBBC05),
      Path()
        ..moveTo(5.84, 14.09)
        ..cubicTo(5.57, 13.23, 5.42, 12.32, 5.42, 11.37)
        ..cubicTo(5.42, 10.42, 5.57, 9.51, 5.84, 8.65)
        ..lineTo(5.84, 5.81)
        ..lineTo(2.18, 5.81)
        ..cubicTo(0.65, 8.89, 0.65, 13.85, 2.18, 16.93)
        ..lineTo(5.84, 14.09)
        ..close(),
    );
    fill(
      const Color(0xFFEA4335),
      Path()
        ..moveTo(12, 4.75)
        ..cubicTo(13.62, 4.75, 15.06, 5.31, 16.21, 6.39)
        ..lineTo(19.36, 3.24)
        ..cubicTo(17.46, 1.46, 15.03, 0.5, 12, 0.5)
        ..cubicTo(7.7, 0.5, 3.99, 2.96, 2.18, 6.56)
        ..lineTo(5.84, 9.4)
        ..cubicTo(6.71, 6.8, 9.14, 4.75, 12, 4.75)
        ..close(),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}
