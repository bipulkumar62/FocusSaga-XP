import 'package:flutter/material.dart';

import '../../../shared/widgets/global_background_scaffold.dart';
import '../domain/reward_summary.dart';

/// Full-screen reward recap shown after a session is saved.
class RewardSummaryScreen extends StatelessWidget {
  const RewardSummaryScreen({super.key, required this.summary});

  final RewardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GlobalBackgroundScaffold(
          child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(
                  summary.completed
                      ? Icons.emoji_events_rounded
                      : Icons.check_circle_rounded,
                  size: 88,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  summary.completed ? 'Session complete!' : 'Session saved!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  '${summary.actualMinutes} min of focus'
                  '${summary.completed ? ' (+20% completion bonus)' : ''}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                if (summary.leveledUp) ...[
                  _RewardTile(
                    icon: Icons.trending_up_rounded,
                    color: theme.colorScheme.tertiary,
                    title: 'Level ${summary.characterLevelBefore} → '
                        '${summary.characterLevelAfter}',
                    subtitle: '+${summary.levelsGained} level(s) cleared',
                  ),
                  const SizedBox(height: 12),
                ],
                _RewardTile(
                  icon: Icons.bolt_rounded,
                  color: Colors.amber.shade700,
                  title: '+${summary.xpEarned} XP',
                  subtitle: 'Added to your character'
                      ' (${summary.characterXpAfter} XP total)',
                ),
                const SizedBox(height: 12),
                _RewardTile(
                  icon: Icons.monetization_on_rounded,
                  color: theme.colorScheme.primary,
                  title: '+${summary.coinsEarned} coins',
                  subtitle: summary.coinsEarned > 0
                      ? 'From clearing ${summary.levelsGained} level(s)'
                      : 'Keep leveling up to earn coins',
                ),
                const Spacer(flex: 3),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: const Text('Keep going'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
