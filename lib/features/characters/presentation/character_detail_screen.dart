import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/character_idle_widget.dart';
import '../../../shared/widgets/global_background_scaffold.dart';
import '../domain/owned_character.dart';
import 'widgets/character_avatar.dart';
/// Full character view: art, description, XP bar, the 5 evolution forms
/// with their unlock levels, and the Equip action.
class CharacterDetailScreen extends ConsumerWidget {
  const CharacterDetailScreen({super.key, required this.character});

  final OwnedCharacter character;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final form = character.currentForm;

    return Scaffold(
      appBar: AppBar(title: Text(character.name)),
      body: SafeArea(
        child: GlobalBackgroundScaffold(
          child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  // ---------- art + name ----------
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CharacterIdleWidget(
                          characterName: character.name,
                          width: 190,
                          height: 190,
                        ),
                        if (character.isSelected)
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.surface,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (character.classTitle != null) ...[
                    Text(
                      character.classTitle!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    character.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (form != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Evolution: ${form.formName}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ---------- level + XP bar ----------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Level ${character.level}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        character.level >= 50
                            ? 'Max level'
                            : '${character.xpIntoLevel} / '
                                '${character.xpForNextLevel} XP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: character.levelProgress,
                      minHeight: 10,
                      color: theme.colorScheme.primary,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---------- evolution forms ----------
                  Text(
                    'Evolution forms',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.72,
                    children: [
                      for (final f in character.forms) _FormSlot(
                        form: f,
                        character: character,
                        isCurrent: form?.id == f.id,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ---------- equip action ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: character.isSelected
                      ? null
                      : () => _equip(context, ref),
                  icon: Icon(character.isSelected
                      ? Icons.check_rounded
                      : Icons.favorite_rounded),
                  label: Text(character.isSelected
                      ? 'Equipped'
                      : 'Equip ${character.name}'),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _equip(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(characterRepositoryProvider).equip(character.id);
      ref.invalidate(ownedCharactersProvider);
      ref.invalidate(storeCatalogProvider);
      ref.invalidate(selectedCharacterProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${character.name} is now equipped')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not equip: $e')),
        );
      }
    }
  }
}

class _FormSlot extends StatelessWidget {
  const _FormSlot({
    required this.form,
    required this.character,
    required this.isCurrent,
  });

  final CharacterForm form;
  final OwnedCharacter character;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = character.isFormUnlocked(form);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: unlocked ? 1 : 0.4,
            child: CharacterAvatar(
              imagePath: form.imageUrl,
              characterName: character.name,
              size: 44,
              paused: true,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Form ${form.formOrder}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          if (unlocked)
            Icon(Icons.check_circle_rounded,
                size: 14, color: theme.colorScheme.primary)
          else
            Text(
              'Lv ${form.unlockLevel}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
