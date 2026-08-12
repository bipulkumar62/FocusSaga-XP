import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/global_background_scaffold.dart';

/// Name entry screen. Shown once after the tutorial when the profile still
/// has no real name ("Guest Learner" / null / empty), and reachable later
/// from the Profile tab to edit the name.
///
/// Validation: trimmed, 2..24 characters, never empty.
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  static const String routeName = 'profile-setup';

  static const int minNameLength = 2;
  static const int maxNameLength = 24;

  /// True when [name] is a real player name (not null / empty / the
  /// anonymous guest fallback).
  static bool needsNameSetup(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return true;
    return trimmed.toLowerCase() == 'guest learner';
  }

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider).value;
    final current = profile?.displayName;
    if (current != null && !ProfileSetupPage.needsNameSetup(current)) {
      _controller.text = current;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(currentProfileProvider).value;
    final currentName = profile?.displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your name'),
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: GlobalBackgroundScaffold(
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.badge_rounded,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'What should we call you?',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'This is the name other players see on the leaderboard. '
                'You can change it anytime in your profile.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: ProfileSetupPage.maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Focus Ninja',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: const OutlineInputBorder(),
                  errorText: _errorText,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Saving…' : 'Save name'),
              ),
              if (ProfileSetupPage.needsNameSetup(currentName))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Pick a name to continue — you can change it later.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.length < ProfileSetupPage.minNameLength) {
      setState(() {
        _errorText = 'Name must be at least '
            '${ProfileSetupPage.minNameLength} characters';
      });
      return;
    }

    final user = ref.read(authUserProvider);
    if (user == null) {
      setState(() => _errorText = 'Not signed in yet — try again in a moment.');
      return;
    }

    setState(() {
      _errorText = null;
      _saving = true;
    });

    try {
      await ref.read(profileRepositoryProvider).updateDisplayName(user.id, name);
      if (!mounted) return;
      ref.invalidate(currentProfileProvider);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/focus');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = 'Could not save your name: $e';
      });
    }
  }
}
