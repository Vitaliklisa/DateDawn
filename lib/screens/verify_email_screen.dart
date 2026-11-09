import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../providers/app_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _resendCooldown = 60;

  Timer? _timer;
  int _secondsRemaining = _resendCooldown;
  bool _checking = false;
  bool _resending = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: _resendCooldown), () {
      if (mounted) setState(() => _secondsRemaining = 0);
    });
  }

  Future<void> _resend() async {
    if (_resending || _secondsRemaining > 0) return;
    setState(() => _resending = true);
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
      setState(() {
        _secondsRemaining = _resendCooldown;
        _resending = false;
      });
      _startCooldown();
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
                    onPressed:
                        _resending || _secondsRemaining > 0 ? null : _resend,
                    child: Text(
                      _resending
                          ? 'Sending…'
                          : _secondsRemaining > 0
                              ? 'Resend email in ${_secondsRemaining}s'
                              : 'Resend email',
                    ),
                  ),
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
