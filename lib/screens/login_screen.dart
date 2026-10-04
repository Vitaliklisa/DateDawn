import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/app_providers.dart';

/// Sign in / create account across Android, iOS and web with Firebase Auth.
///
/// Two paths only, both free and both supported on every target: Google, and
/// email + password. A guest can also step straight into the app and upgrade to
/// a real account later without losing their countdowns — the uid is preserved
/// by `linkAnonymousWithEmail`.
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
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await runAction(
        context,
        () async {
          final auth = ref.read(authServiceProvider);
          if (_creating) {
            await auth.registerWithEmail(
              email: _email.text,
              password: _password.text,
              displayName: _name.text,
            );
          } else {
            await auth.signInWithEmail(
                email: _email.text, password: _password.text);
          }
        },
        successMessage: _creating ? 'Account created.' : 'Welcome back.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await runAction(
        context,
        () => ref.read(authServiceProvider).signInWithGoogle(),
        successMessage: 'Signed in with Google.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guest() async {
    setState(() => _busy = true);
    try {
      await runAction(
        context,
        () => ref.read(authServiceProvider).signInAnonymously(),
        successMessage: 'You are in. Sign in later to sync.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Enter your email first, then tap “Forgot password”.')),
      );
      return;
    }
    await runAction(
      context,
      () => ref.read(authServiceProvider).sendPasswordReset(email),
      successMessage: 'Reset link sent to $email.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authError = ref.watch(activeAuthStateProvider).error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
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
                    Text(
                      _creating
                          ? 'Create your account'
                          : 'Welcome to Date Dawn',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _creating
                          ? 'Your countdowns sync to every device you sign in on.'
                          : 'Count down to the moments that matter — on phone, tablet and web.',
                      style: TextStyle(
                          fontSize: 14, height: 1.5, color: colors.muted),
                    ),
                    const SizedBox(height: 28),
                    if (_creating) ...[
                      _Field(
                        controller: _name,
                        label: 'Name',
                        hint: 'Alex Rivera',
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Tell us what to call you.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    _Field(
                      controller: _email,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your email.';
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'That does not look like an email.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      controller: _password,
                      label: 'Password',
                      hint: '••••••••',
                      obscure: _obscure,
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
                        if ((v ?? '').isEmpty) return 'Enter your password.';
                        if (_creating && (v ?? '').length < 6) {
                          return 'Use at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    if (!_creating)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: const Text('Forgot password?',
                              style: TextStyle(fontSize: 13)),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    if (authError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Could not reach the sign-in service. Check your connection.',
                        style: TextStyle(fontSize: 13, color: colors.danger),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const _ButtonSpinner()
                          : Text(_creating ? 'Create account' : 'Sign in'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
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
                      label: const Text('Continue with Google'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy ? null : _guest,
                      child: const Text('Continue as guest'),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          _creating ? 'Already have an account?' : 'New here?',
                          style: TextStyle(fontSize: 13, color: colors.muted),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _creating = !_creating;
                                    _formKey.currentState?.reset();
                                  }),
                          child: Text(
                            _creating ? 'Sign in' : 'Create one',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.accent,
                            ),
                          ),
                        ),
                      ],
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
