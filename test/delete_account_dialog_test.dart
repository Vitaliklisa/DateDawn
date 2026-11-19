import 'package:datedawn/core/theme.dart';
import 'package:datedawn/l10n/generated/app_localizations.dart';
import 'package:datedawn/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('requires an exact confirmation before enabling deletion',
      (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.build(brightness: Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const DeleteAccountDialog(
                      expectedValue: 'Alex@example.com'),
                );
              },
              child: const Text('Open confirmation'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This action is permanent. All your events, circles, and data will be deleted forever.',
      ),
      findsOneWidget,
    );
    final confirmButton =
        find.widgetWithText(FilledButton, 'Permanently Delete Account');
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'alex@example.com');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Alex@example.com');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmButton).onPressed, isNotNull);

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(result, 'Alex@example.com');
  });
}
