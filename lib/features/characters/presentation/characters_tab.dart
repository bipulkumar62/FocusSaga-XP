import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/character_idle_widget.dart';
import '../domain/owned_character.dart';
import 'character_detail_screen.dart';

/// Characters tab — owned characters, equipped one, level + XP bar,
/// evolution forms and equipping.
class CharactersTab extends ConsumerWidget {
  const CharactersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final characters = ref.watch(ownedCharactersProvider);

    return SafeArea(
      child: characters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Could not load characters: $e',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(ownedCharactersProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_martial_arts_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No characters yet.\nFinish a focus session to earn one!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _repairStarters(context, ref),
                      icon: const Icon(Icons.healing_rounded),
                      label: const Text('Restore starter kit'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _CharacterCard(character: list[index]),
          );
        },
      ),
    );
  }

  Future<void> _repairStarters(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(profileRepositoryProvider).repairStarterItems();
      ref.invalidate(ownedCharactersProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Starter kit restored!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not restore starter kit: $e')),
      );
    }
  }
}

class _CharacterCard extends ConsumerWidget {
  const _CharacterCard({required this.character});

  final OwnedCharacter character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final equipped = character.isSelected;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CharacterDetailScreen(character: character),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CharacterIdleWidget(
                characterName: character.name,
                width: 104,
                height: 104,
                paused: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            character.name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (equipped) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: theme.colorScheme.primary),
                        ],
                      ],
                    ),
                    if (character.classTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        character.classTitle!,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      character.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Lv ${character.level}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (equipped) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· Equipped',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: character.levelProgress,
                        minHeight: 6,
                        color: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FormStrip(character: character),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 5 evolution slots: unlocked = filled dot, locked = grey lock.
class _FormStrip extends StatelessWidget {
  const _FormStrip({required this.character});

  final OwnedCharacter character;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final form in character.forms) ...[
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: character.isFormUnlocked(form)
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Icon(
              character.isFormUnlocked(form)
                  ? Icons.circle
                  : Icons.lock_rounded,
              size: 12,
              color: character.isFormUnlocked(form)
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.outline,
            ),
          ),
          if (form != character.forms.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
