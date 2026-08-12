import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/global_background_scaffold.dart';
import 'legal_documents_page.dart';

/// Terms of Use + Privacy Policy acceptance screen.
///
/// The Accept button stays disabled until the user ticks the checkbox.
/// Accepting upserts `terms_acceptance` (terms_accepted = true, versions 1.0)
/// and the router then moves to the tutorial (or home if already done).
class TermsPage extends ConsumerStatefulWidget {
  const TermsPage({super.key});

  static const String routeName = 'terms';

  @override
  ConsumerState<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends ConsumerState<TermsPage> {
  bool _agreed = false;
  bool _saving = false;

  Future<void> _accept() async {
    final user = ref.read(authUserProvider);
    if (user == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).acceptTerms(user.id);
      ref.invalidate(termsStatusProvider);
      // Router redirects to /tutorial (or /home) automatically.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Could not save acceptance: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDocument({required String title, required String body, required LegalDocument doc}) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/legal', extra: doc);
            },
            child: const Text('Read full document'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: GlobalBackgroundScaffold(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before you start',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please review the documents below. You can read them anytime '
                        'later from your profile.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showDocument(
                          title: 'Terms of Use',
                          body: _termsOfUseSummary,
                          doc: LegalDocument.terms,
                        ),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Read Terms of Use'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showDocument(
                          title: 'Privacy Policy',
                          body: _privacyPolicySummary,
                          doc: LegalDocument.privacy,
                        ),
                        icon: const Icon(Icons.privacy_tip_outlined),
                        label: const Text('Read Privacy Policy'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '1. FocusSaga XP helps you build focus habits with gamified '
                        'sessions, XP, levels and rewards.\n\n'
                        '2. Your progress, coins, level and settings are stored securely '
                        'and are only visible to you.\n\n'
                        '3. You can stop using the app at any time by logging out.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              CheckboxListTile(
                value: _agreed,
                onChanged: (value) => setState(() => _agreed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I have read and agree to the Terms of Use and Privacy Policy',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: !_agreed || _saving ? null : _accept,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Accept & Continue'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

const String _termsOfUseSummary = '''
1. By accepting these terms you agree to use FocusSaga XP for personal use and
to follow our fair-use rules — no manipulating, hacking or automating progress,
coins or rewards.

2. Coins, items and rewards are virtual only and have no real-world value.

3. We may update these terms. Continued use after changes means you accept the
updated terms.

4. Questions: support@startupzilla.com
''';

const String _privacyPolicySummary = '''
1. What we collect
- Your display name (defaults to "Guest Learner") and, if ever linked, your email
- Your in-app progress: sessions, XP, coins, level, streak, characters,
challenges, tutorial and terms-acceptance status

2. How we use it
To sync your progress across devices, run leaderboards and personalize your
experience.

3. What we do NOT do
- We never store your password
- We never sell your data
- We do not collect location data

4. Leaderboards
Your display name, level and focused minutes are public to other users.

5. Data control
You can log out anytime. For account deletion, email support@startupzilla.com.
''';