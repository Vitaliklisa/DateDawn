import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';
import '../widgets/brand_kit.dart';

/// EU (GDPR) and Canada (PIPEDA) compliant Privacy Policy and Terms of Service screen.
///
/// **Back is explicit, not a `pop`.** The page is opened with `go` inside the
/// shell (a `push` of a sibling route there is silently ignored — see
/// `Routes.privacy`), so there is no stack of Flutter routes to pop. Closing
/// goes through [closeLegalPage], which knows which page opened this one and
/// falls back to Support when the URL was loaded cold.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.isPrivacy});

  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final title =
        isPrivacy ? l10n.privacyPolicyTitle : l10n.termsOfServiceTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: HoverTintIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: l10n.back,
          onPressed: () => closeLegalPage(context),
        ),
      ),
      // As a layer over the shell the page has to cover everything beneath it,
      // or the page it was opened from shows through and stays tappable.
      backgroundColor: colors.canvas,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        children: [
          const SizedBox(height: 6),
          Text(
            l10n.policyLastUpdated,
            style: TextStyle(fontSize: 12.5, color: colors.subtle),
          ),
          const SizedBox(height: 24),
          if (isPrivacy) ...[
            _Section(
              title: l10n.privacyIntroTitle,
              body: l10n.privacyIntroBody(supportEmailAddress),
            ),
            _Section(
              title: l10n.privacyCollectTitle,
              body: l10n.privacyCollectBody,
            ),
            _Section(
              title: l10n.privacyBasisTitle,
              body: l10n.privacyBasisBody,
            ),
            _Section(
              title: l10n.privacySharingTitle,
              body: l10n.privacySharingBody,
            ),
            _Section(
              title: l10n.privacyStorageTitle,
              body: l10n.privacyStorageBody,
            ),
            _Section(
              title: l10n.privacyRightsTitle,
              body: l10n.privacyRightsBody(supportEmailAddress),
            ),
          ] else ...[
            _Section(
              title: l10n.termsAcceptanceTitle,
              body: l10n.termsAcceptanceBody,
            ),
            _Section(
              title: l10n.termsUseTitle,
              body: l10n.termsUseBody,
            ),
            _Section(
              title: l10n.termsOwnershipTitle,
              body: l10n.termsOwnershipBody,
            ),
            _Section(
              title: l10n.termsTerminationTitle,
              body: l10n.termsTerminationBody,
            ),
            _Section(
              title: l10n.termsLiabilityTitle,
              body: l10n.termsLiabilityBody,
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              color: colors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
