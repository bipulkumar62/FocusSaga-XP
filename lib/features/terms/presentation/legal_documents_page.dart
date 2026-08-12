import 'package:flutter/material.dart';

import '../../../shared/widgets/global_background_scaffold.dart';

/// Which legal document to open first.
enum LegalDocument { terms, privacy }

/// A titled section of a legal document.
class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}

const List<LegalSection> termsOfUseSections = [
  LegalSection(
    '1. Acceptance of these Terms',
    'By creating an account or using FocusSaga XP ("the App") you agree to these '
        'Terms of Use and the Privacy Policy. If you do not agree, please do not '
        'use the App.',
  ),
  LegalSection(
    '2. The Service',
    'FocusSaga XP is a gamified focus timer. It tracks your focus sessions and '
        'awards in-app XP, coins, levels, characters, backgrounds and other virtual '
        'rewards. Your progress is stored securely in our cloud database and synced '
        'to your account.',
  ),
  LegalSection(
    '3. Accounts',
    'You must be at least 13 years old to use the App. You can start without signing '
        'up: an anonymous guest account is created automatically and is shown as '
        '"Guest Learner" on leaderboards. Guest progress lives on the device and in '
        'our database under that guest identity.',
  ),
  LegalSection(
    '4. Virtual currency and rewards',
    'Coins and items are virtual only. They have no real-world value, cannot be '
        'exchanged for money, and are non-refundable. We may change reward rates, '
        'prices or availability at any time.',
  ),
  LegalSection(
    '5. Fair use',
    'You agree not to manipulate, automate, exploit or hack the App, its timers, '
        'progress or rewards. Accounts that do so may be suspended or removed.',
  ),
  LegalSection(
    '6. Intellectual property',
    'The App, its code, characters, artwork, branding and content are owned by us or '
        'our licensors. You may not copy, redistribute or reverse-engineer them.',
  ),
  LegalSection(
    '7. Disclaimers',
    'The App is provided "as is" without warranties of any kind, express or implied. '
        'We do not guarantee that the App will be uninterrupted or error-free.',
  ),
  LegalSection(
    '8. Limitation of liability',
    'To the maximum extent permitted by law, we are not liable for any indirect, '
        'incidental or consequential damages arising from your use of the App.',
  ),
  LegalSection(
    '9. Changes to these Terms',
    'We may update these Terms from time to time. We will record the version you '
        'accepted. Continued use of the App after changes take effect means you '
        'accept the updated Terms.',
  ),
  LegalSection(
    '10. Termination',
    'You may stop using the App at any time by logging out. You can request deletion '
        'of your account and data by emailing support@startupzilla.com.',
  ),
  LegalSection(
    '11. Governing law',
    'These Terms are governed by the laws of India. Any disputes are subject to the '
        'exclusive jurisdiction of the courts of Mumbai.',
  ),
  LegalSection(
    '12. Contact',
    'Questions about these Terms: support@startupzilla.com.',
  ),
];

const List<LegalSection> privacyPolicySections = [
  LegalSection(
    '1. Information we collect',
    'Account information: your display name (defaults to "Guest Learner"), your email '
        'address if you ever link one, and your avatar.\n\n'
        'Activity data: your focus sessions (date, duration, completion), XP, coins, '
        'level, streak, owned characters and backgrounds, challenge progress, tutorial '
        'status and terms acceptance.',
  ),
  LegalSection(
    '2. How we use it',
    'To operate the App: keeping you logged in, saving and syncing your progress, '
        'running levels and leaderboards, and awarding rewards. To personalize your '
        'experience and to improve the App.',
  ),
  LegalSection(
    '3. Sharing',
    'We do not sell your personal data. We use infrastructure providers (such as '
        'Supabase for our database and authentication) that process data on our '
        'behalf. We may disclose data only if required by law.',
  ),
  LegalSection(
    '4. Storage and security',
    'Your data is stored on Supabase servers in the India (ap-south-1) region and is '
        'protected by database access policies. Only you can see your private data. '
        'Leaderboard entries (display name, level, focused minutes) are visible to '
        'other users of the App.',
  ),
  LegalSection(
    '5. Retention and deletion',
    'We keep your data while your account is active. To delete your account and all '
        'associated data, email support@startupzilla.com and we will process the '
        'request promptly.',
  ),
  LegalSection(
    '6. Children\'s privacy',
    'The App is not directed to children under 13, and we do not knowingly collect '
        'personal information from them.',
  ),
  LegalSection(
    '7. Changes to this Policy',
    'We may update this Privacy Policy from time to time. We will record the version '
        'you accepted, and we will highlight material changes when you are asked to '
        're-accept.',
  ),
  LegalSection(
    '8. Contact',
    'Privacy questions: support@startupzilla.com.',
  ),
];

/// Full-page legal documents viewer (Terms of Use + Privacy Policy tabs).
class LegalDocumentsPage extends StatelessWidget {
  const LegalDocumentsPage({super.key, this.initial = LegalDocument.terms});

  static const String routeName = 'legal';

  /// Which tab to open on first.
  final LegalDocument initial;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initial.index,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Legal'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Terms of Use'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: GlobalBackgroundScaffold(
          child: TabBarView(
            children: [
              _DocumentView(sections: termsOfUseSections),
              _DocumentView(sections: privacyPolicySections),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.sections});

  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final section in sections) ...[
          Text(
            section.title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            section.body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }
}
