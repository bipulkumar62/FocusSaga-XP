import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/daily_challenge.dart';

/// Challenges tab — today's challenges with live progress bars and
/// claimable rewards (coins + XP + rank points).
class ChallengesTab extends ConsumerWidget {
  const ChallengesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(dailyChallengesProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(dailyChallengesProvider.future),
        child: challenges.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: 'Could not load challenges: $e',
            onRetry: () => ref.invalidate(dailyChallengesProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(48),
                    child: Text(
                      'No challenges today.\nPull to refresh.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ChallengeCard(challenge: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});

  final DailyChallenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final claimed = challenge.claimed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    challenge.metric.icon,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        challenge.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (claimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 14,
                            color: theme.colorScheme.onSecondaryContainer),
                        const SizedBox(width: 3),
                        Text(
                          'Claimed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: challenge.progressRatio,
                minHeight: 8,
                color: challenge.isCompleted
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${challenge.progress} / ${challenge.targetValue}'
                    '${challenge.isCompleted ? '  ·  done!' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${challenge.rewardCoins} coins · '
                  '${challenge.rewardXp} XP · '
                  '${challenge.rankPoints} rank',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (challenge.canClaim)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _claim(context, ref),
                  icon: const Icon(Icons.redeem_rounded, size: 18),
                  label: const Text('Claim reward'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _claim(BuildContext context, WidgetRef ref) async {
    try {
      final claim = await ref
          .read(challengeRepositoryProvider)
          .claim(challenge.id);
      if (!context.mounted) return;
      ref.invalidate(dailyChallengesProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(ownedCharactersProvider);
      ref.invalidate(dailyLeaderboardProvider);
      ref.invalidate(weeklyLeaderboardProvider);
      await showDialog<void>(
        context: context,
        builder: (context) => _RewardDialog(claim: claim),
      );
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e.message))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not claim: $e')),
      );
    }
  }

  String _friendlyError(String message) {
    if (message.contains('already claimed')) {
      return 'Reward already claimed.';
    }
    if (message.contains('not completed')) {
      return 'Challenge is not completed yet.';
    }
    return message;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confetti-free reward recap after a successful claim.
class _RewardDialog extends StatelessWidget {
  const _RewardDialog({required this.claim});

  final ChallengeClaim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.redeem_rounded, size: 40),
      title: const Text('Reward claimed!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RewardRow(
            icon: Icons.monetization_on_rounded,
            text: '+${claim.rewardCoins} coins'
                '${claim.levelUpCoins > 0 ? ' (+${claim.levelUpCoins} from level-ups)' : ''}',
          ),
          _RewardRow(
            icon: Icons.bolt_rounded,
            text: '+${claim.rewardXp} XP'
                '${claim.levelsGained > 0 ? '  ·  ${claim.characterLevelAfter} levels!' : ''}',
          ),
          _RewardRow(
            icon: Icons.leaderboard_rounded,
            text: '+${claim.rankPoints} rank points',
          ),
          const SizedBox(height: 8),
          Text(
            'Balance: ${claim.balance} coins',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Awesome!'),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
