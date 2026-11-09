import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/firebase_action_code.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({this.actionUri, super.key});

  final Uri? actionUri;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;
  bool _cooldownActive = false;
  bool _applyingAction = false;
  String? _actionMessage;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    final uri = widget.actionUri;
    if (uri != null) {
      final code = findFirebaseActionCode(uri);
      if (code != null) {
        _applyVerificationCode(code);
      }
    }
  }

  Future<void> _applyVerificationCode(String code) async {
    setState(() => _applyingAction = true);
    try {
      final service = ref.read(authServiceProvider);
      await service.applyEmailVerificationCode(code);
      final user = await service.reloadCurrentUser();
      if (!mounted) return;
      if (user?.emailVerified == true) {
        context.go(Routes.home);
      } else {
        setState(() {
          _actionMessage =
              'Your email is verified. Sign in to continue if needed.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionError = error.toString());
    } finally {
      if (mounted) setState(() => _applyingAction = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _cooldownActive) return;
    setState(() => _resending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
      setState(() {
        _resending = false;
        _cooldownActive = true;
      });
      await Future<void>.delayed(const Duration(seconds: 60));
      if (mounted) setState(() => _cooldownActive = false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      setState(() => _resending = false);
    }
  }

  Future<void> _checkVerification() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final user = await ref.read(authServiceProvider).reloadCurrentUser();
      if (!mounted) return;
      if (user?.emailVerified == true || user?.isGoogleUser == true) {
        context.go(Routes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not verified yet. Check your inbox.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 52,
                    color: colors.accent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to '
                    '${user?.email ?? 'your email address'}. Please verify to '
                    'continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(height: 1.5, color: colors.muted),
                  ),
                  if (_applyingAction) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_actionMessage != null || _actionError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _actionMessage ?? _actionError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color:
                            _actionError == null ? colors.accent : colors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    "Can't find the email? Please check your Spam or Junk folder.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.5,
                      color: colors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _checking ? null : _checkVerification,
                    child: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('I have verified my email'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _resending || _cooldownActive ? null : _resend,
                    child: Text(
                      _resending ? 'Sending…' : 'Resend email',
                    ),
                  ),
                  if (_cooldownActive) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Please wait 60 seconds before requesting another email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.muted),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      final error = await runAction(
                        context,
                        () => ref.read(authServiceProvider).signOut(),
                      );
                      if (error == null && context.mounted) {
                        context.go(Routes.login);
                      }
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
