import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../l10n/app_localizations_context.dart';
import '../widgets/brand_kit.dart';

/// Support, contact and legal.
///
/// Both the App Store and Google Play require a reachable support contact and a
/// privacy policy URL for a published app, and they check that the address in
/// the listing actually resolves to something a person can use. This screen is
/// where the app itself points at that contact, so a reviewer following the
/// trail from the store listing lands somewhere real rather than on a mailto.
///
/// It is deliberately reachable **signed in or out**: someone locked out of
/// their account is exactly who needs support, so it must not sit behind the
/// auth redirect.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  /// The support address shown in the store listings.
  static const supportEmail = supportEmailAddress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final router = GoRouter.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpAndSupport),
        // A back arrow only where there is a stack to go back through.
        //
        // Inside the shell on desktop the sidebar is the navigation, and an
        // arrow that pops to whatever happened to be underneath is worse than
        // no arrow: it makes the page feel like a modal. On a phone there is a
        // bottom bar but the page is pushed, so Back is genuinely useful — and
        // when it was opened cold from a store link there is nothing to pop, so
        // it falls back to Home rather than stranding the visitor.
        leading: router.canPop()
            ? HoverTintIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: l10n.back,
                onPressed: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go(Routes.home);
                  }
                },
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Text(
            l10n.supportHeading,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.fg,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.supportIntro(l10n.supportResponseTime),
            style: TextStyle(fontSize: 13.5, height: 1.55, color: colors.muted),
          ),
          const SizedBox(height: 22),
          _ContactCard(
            email: supportEmail,
            onTap: () => _copyEmail(context),
          ),
          const SizedBox(height: 26),
          _SectionTitle(l10n.supportCommonQuestions),
          const SizedBox(height: 12),
          _Faq(
            question: l10n.supportFaqGoogleQuestion,
            answer: l10n.supportFaqGoogleAnswer,
          ),
          _Faq(
            question: l10n.supportFaqSharingQuestion,
            answer: l10n.supportFaqSharingAnswer,
          ),
          _Faq(
            question: l10n.supportFaqDeclinedQuestion,
            answer: l10n.supportFaqDeclinedAnswer,
          ),
          _Faq(
            question: l10n.supportFaqDeleteQuestion,
            answer: l10n.supportFaqDeleteAnswer,
          ),
          _Faq(
            question: l10n.supportFaqBlockQuestion,
            answer: l10n.supportFaqBlockAnswer,
          ),
          _Faq(
            question: l10n.supportFaqAdsQuestion,
            answer: l10n.supportFaqAdsAnswer,
          ),
          const SizedBox(height: 26),
          _SectionTitle(l10n.supportLegal),
          const SizedBox(height: 12),
          _LinkRow(
            label: l10n.privacyPolicy,
            onTap: () => openLegalPage(context, LegalDocument.privacy),
          ),
          _LinkRow(
            label: l10n.termsOfService,
            onTap: () => openLegalPage(context, LegalDocument.terms),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 17, color: colors.subtle),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    l10n.supportNotice,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: colors.subtle),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Copies the address and offers the mail client.
  ///
  /// Copy first, then offer to open: on desktop web a `mailto:` silently does
  /// nothing at all if no mail handler is registered, and the person is left
  /// staring at a screen that ignored their tap. Copying always works, so the
  /// address is in hand either way.
  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.supportEmailCopied(supportEmail)),
        action: SnackBarAction(
          label: context.l10n.openMail,
          onPressed: () => _open(context, 'mailto:$supportEmail'),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw const _CouldNotOpen();
    } catch (_) {
      // Never a dead tap: if nothing can handle the link, say so and leave the
      // address on the clipboard instead of failing silently.
      await Clipboard.setData(ClipboardData(text: url));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.linkCopiedClipboard)),
      );
    }
  }
}

class _CouldNotOpen implements Exception {
  const _CouldNotOpen();
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.email, required this.onTap});

  final String email;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.mail_outline_rounded,
                    size: 19, color: colors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.supportEmailLabel,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.fg),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: TextStyle(fontSize: 13, color: colors.accent),
                    ),
                  ],
                ),
              ),
              Icon(Icons.content_copy_rounded, size: 16, color: colors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.3,
        color: colors.subtle,
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Theme(
      // The default expansion-tile chrome paints a divider and a coloured
      // leading icon that fight the card style used everywhere else here.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      // The card colour and border belong on the tile's own `shape`, not on a
      // wrapper. A decorated box above a tile hides the ink splash, so these
      // FAQ rows gave no press feedback at all — and Flutter flags exactly that
      // in debug builds.
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ExpansionTile(
          backgroundColor: colors.surface,
          collapsedBackgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: colors.muted,
          collapsedIconColor: colors.subtle,
          title: Text(
            question,
            style: TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w500, color: colors.fg),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style:
                    TextStyle(fontSize: 13, height: 1.55, color: colors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13.5, color: colors.fg),
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 15, color: colors.subtle),
            ],
          ),
        ),
      ),
    );
  }
}
