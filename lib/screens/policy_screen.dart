import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
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
    final title = isPrivacy ? 'Privacy Policy' : 'Terms of Service';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: HoverTintIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
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
            'Last updated: February 2026 · Compliant with EU GDPR & Canada PIPEDA',
            style: TextStyle(fontSize: 12.5, color: colors.subtle),
          ),
          const SizedBox(height: 24),
          if (isPrivacy) ...[
            const _Section(
              title: '1. Introduction & Data Controller',
              body:
                  'Date Dawn ("we", "our", or "us") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile and web applications, in full compliance with the EU General Data Protection Regulation (GDPR) and the Personal Information Protection and Electronic Documents Act (PIPEDA) of Canada.\n\nData Controller Contact: $supportEmailAddress',
            ),
            const _Section(
              title: '2. Information We Collect',
              body:
                  '• Account Data: Email address and display name provided during authentication (Firebase Auth).\n• User Content: Countdowns, titles, dates, descriptions, and circle memberships you explicitly create or share.\n• Device & Notification Data: Push notification tokens to deliver countdown reminders and invitation alerts.\n\nWe do NOT collect browsing history, advertising identifiers, location data, or sell any personal information to third parties.',
            ),
            const _Section(
              title: '3. Legal Basis for Processing (EU GDPR)',
              body:
                  'We process your data under the following lawful bases:\n• Contractual Necessity: Providing countdown syncing, circle sharing, and invitation features.\n• Consent: When you grant push notification permissions or opt-in to shared circles.\n• Legitimate Interests: Ensuring application security, reliability, and preventing abuse.',
            ),
            const _Section(
              title: '4. Sharing & Blocking',
              body:
                  'Date Dawn lets people interact one-to-one: you can invite someone to a countdown, and both of you can leave notes on one you share. That content is visible only to the people on that countdown — never public, never shown to anyone else.\n\nYou can block another person at any time: open a countdown you share with them and long-press their name (or secondary-click it on desktop). Blocking removes you from each other\'s countdowns, cancels invitations between you, and stops them inviting you again. The person is not told. The list of people you have blocked is private to you, and you can unblock anyone from Settings → Blocked people.',
            ),
            const _Section(
              title: '5. Data Storage & Security',
              body:
                  'Your data is securely stored and processed using Firebase (Google Cloud Platform) infrastructure adhering to high industry security standards. Data transmitted between your device and our servers is encrypted in transit using TLS.',
            ),
            const _Section(
                title: '6. Your Rights (Access, Correction & Erasure)',
                body:
                    'Under GDPR and PIPEDA, you have the right to:\n• Access: Request a copy of the personal data we hold about you.\n• Rectification: Update or correct your profile information in Settings.\n• Erasure (Right to be Forgotten): Request complete deletion of your account and all associated countdowns and notifications at any time by contacting $supportEmailAddress.'),
          ] else ...[
            const _Section(
              title: '1. Acceptance of Terms',
              body:
                  'By accessing or using Date Dawn, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.',
            ),
            const _Section(
              title: '2. Use of the Service',
              body:
                  'Date Dawn is provided for personal, non-commercial countdown and shared moment tracking. You agree not to misuse the service, upload malicious content, harass other users through shared circles or invitations, or attempt to bypass security controls.',
            ),
            const _Section(
              title: '3. User Content & Ownership',
              body:
                  'You retain all ownership rights to the countdown events, titles, and content you create. You grant Date Dawn a limited license solely to store and sync your content across your authenticated devices and shared circle members.',
            ),
            const _Section(
              title: '4. Termination & Account Deletion',
              body:
                  'You may stop using Date Dawn at any time and request account deletion by emailing support. We reserve the right to suspend or terminate accounts that violate these terms or abuse platform infrastructure.',
            ),
            const _Section(
              title: '5. Limitation of Liability',
              body:
                  'Date Dawn is provided "as is" without warranties of any kind. We shall not be liable for any indirect, incidental, or consequential damages arising from your use of the application.',
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
