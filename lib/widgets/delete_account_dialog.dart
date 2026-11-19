import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.expectedEmail});

  final String expectedEmail;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AlertDialog(
      title: Text(l10n.deleteAccount),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountWarning),
          const SizedBox(height: 20),
          Text(l10n.deleteAccountConfirmationPrompt),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmation,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n.deleteAccountConfirmationLabel,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.danger),
          onPressed: widget.expectedEmail.isNotEmpty &&
                  _confirmation.text == widget.expectedEmail
              ? () => Navigator.of(context).pop(_confirmation.text)
              : null,
          child: Text(l10n.permanentlyDeleteAccount),
        ),
      ],
    );
  }
}
