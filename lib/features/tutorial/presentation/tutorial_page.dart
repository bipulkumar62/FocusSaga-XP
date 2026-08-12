import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/global_background_scaffold.dart';

/// Onboarding tutorial: 5 swipeable screens.
/// Skip / Get Started both mark `profiles.tutorial_completed = true` and the
/// router then redirects to /home automatically.
class TutorialPage extends ConsumerStatefulWidget {
  const TutorialPage({super.key});

  static const String routeName = 'tutorial';

  @override
  ConsumerState<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends ConsumerState<TutorialPage> {
  static const int _totalPages = 5;

  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final user = ref.read(authUserProvider);
    if (user == null) return;

    setState(() => _finishing = true);
    try {
      await ref.read(profileRepositoryProvider).completeTutorial(user.id);
      ref.invalidate(currentProfileProvider);
      // Router redirects to /home automatically.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Could not finish tutorial: $e')));
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _page == _totalPages - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial'),
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _finishing ? null : _finish,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: GlobalBackgroundScaffold(
        child: SafeArea(
          child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _totalPages,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _TutorialStepView(step: _steps[index]),
              ),
            ),
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _totalPages,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _page
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(width: 60),
                  const Spacer(),
                  FilledButton(
                    onPressed: _finishing ? null : _next,
                    child: _finishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLastPage ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }
}

class _TutorialStepView extends StatelessWidget {
  const _TutorialStepView({required this.step});

  final _TutorialStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        // Scrollable so a short viewport (landscape phones, small web
        // windows) never overflows and blanks the slide.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 64, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 32),
              Text(
                step.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;
}

const List<_TutorialStep> _steps = [
  _TutorialStep(
    icon: Icons.timer_outlined,
    title: 'Set a timer and start focusing',
    description: 'Pick a session length, start the timer, and put your phone away. '
        'One session at a time — that is the whole trick.',
  ),
  _TutorialStep(
    icon: Icons.bolt_rounded,
    title: 'Earn XP by completing sessions',
    description: 'Finish focus sessions to earn XP and coins. The longer you stay '
        'focused, the more you earn — interrupted sessions earn less.',
  ),
  _TutorialStep(
    icon: Icons.emoji_events_outlined,
    title: 'Level up characters & unlock forms',
    description: 'Every level you gain lets your character grow. New forms unlock '
        'as you level up, so your progress shows on your character.',
  ),
  _TutorialStep(
    icon: Icons.storefront_outlined,
    title: 'Buy backgrounds & timer skins',
    description: 'Spend your coins in the shop on backgrounds and timer skins. '
        'Make your focus space feel like yours.',
  ),
  _TutorialStep(
    icon: Icons.leaderboard_outlined,
    title: 'Daily challenges & rankings',
    description: 'Complete daily challenges to earn bonus rewards and climb the '
        'rankings. Consistency beats intensity.',
  ),
];