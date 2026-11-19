import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';
import '../services/deletion_service.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmation = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final expectedEmail = user == null
        ? ''
        : ref.read(authServiceProvider).currentEmail ?? user.email;
    final colors = context.colors;
    final l10n = context.l10n;
    final canDelete = !_isSubmitting &&
        expectedEmail.isNotEmpty &&
        _confirmation.text == expectedEmail;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => context.go(Routes.settings),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(l10n.deleteAccount),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: colors.danger.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 44,
                        color: colors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.deleteAccount,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.deleteAccountWarning,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        _Consequence(
                            text: l10n.deleteAccountProfileConsequence),
                        const SizedBox(height: 14),
                        _Consequence(text: l10n.deleteAccountAccessConsequence),
                        const SizedBox(height: 14),
                        _Consequence(
                          text: l10n.deleteAccountIrreversibleConsequence,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.deleteAccountConfirmationPrompt,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('delete-account-confirmation'),
                    controller: _confirmation,
                    enabled: !_isSubmitting,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.deleteAccountConfirmationLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('delete-account-submit'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: canDelete
                          ? () => _deleteAccount(expectedEmail)
                          : null,
                      child: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.deleteAccountPermanentlyAction),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(String expectedEmail) async {
    final confirmation = _confirmation.text;
    if (_isSubmitting ||
        expectedEmail.isEmpty ||
        confirmation != expectedEmail) {
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(authServiceProvider)
          .deleteAccount(confirmation: confirmation);

      String? cleanupWarning;
      try {
        await clearLocalAccountPreferences();
      } catch (error, stackTrace) {
        debugPrint(
            '[datedawn] Could not clear local account preferences: $error');
        debugPrintStack(stackTrace: stackTrace);
        cleanupWarning = l10n.accountDeletedCleanupWarning;
      }
      container.invalidate(themeModeProvider);
      container.invalidate(timeFormatProvider);

      if (mounted) context.go(Routes.login);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
      if (cleanupWarning != null) {
        messenger.showSnackBar(SnackBar(content: Text(cleanupWarning)));
      }
    } on DeletionFailure catch (failure) {
      final message = failure.statusCode == 500 || failure.statusCode == 504
          ? l10n.serverTimedOutTryAgain
          : failure.message;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } on AuthFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    } catch (error, stackTrace) {
      debugPrint('[datedawn] Account deletion failed unexpectedly: $error');
      debugPrintStack(stackTrace: stackTrace);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountDeletionFailed)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Icon(Icons.circle, size: 8, color: colors.danger),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: colors.fg, height: 1.45),
          ),
        ),
      ],
    );
  }
}
