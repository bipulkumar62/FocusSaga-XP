import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/character_idle_widget.dart';
import '../domain/store_item.dart';

/// Store tab — buy backgrounds, timer skins, reward animations and
/// characters; equip what you own.
class StoreTab extends ConsumerStatefulWidget {
  const StoreTab({super.key});

  @override
  ConsumerState<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends ConsumerState<StoreTab> {
  StoreItemKind _kind = StoreItemKind.character;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(storeCatalogProvider);
    final profile = ref.watch(currentProfileProvider);
    final coins = profile.value?.coins;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final kind in StoreItemKind.values) ...[
                          ChoiceChip(
                            avatar: Icon(kind.icon, size: 18),
                            label: Text(kind.label),
                            selected: _kind == kind,
                            onSelected: (_) => setState(() => _kind = kind),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: catalog.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load the store: $e',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(storeCatalogProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (store) {
                final items = store.forKind(_kind);
                if (items.isEmpty) {
                  return const Center(child: Text('Nothing here yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _StoreCard(
                    item: items[index],
                    coins: coins,
                    onBuy: () => _buy(items[index]),
                    onEquip: () => _equip(items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buy(StoreItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buy ${item.name}?'),
        content: Text(
          'This costs ${item.priceCoins} coins and will be yours forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Buy · ${item.priceCoins} coins'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(storeRepositoryProvider).buy(item.kind, item.id);
      if (!mounted) return;
      ref.invalidate(storeCatalogProvider);
      ref.invalidate(currentProfileProvider);
      ref.invalidate(ownedCharactersProvider);
      _snack('${item.name} is yours!');
    } on PostgrestException catch (e) {
      _snack(_friendlyError(e.message));
    } catch (e) {
      _snack('Could not buy: $e');
    }
  }

  Future<void> _equip(StoreItem item) async {
    try {
      await ref.read(storeRepositoryProvider).equip(item);
      if (!mounted) return;
      ref.invalidate(storeCatalogProvider);
      _snack('${item.name} equipped');
    } on PostgrestException catch (e) {
      _snack(_friendlyError(e.message));
    } catch (e) {
      _snack('Could not equip: $e');
    }
  }

  String _friendlyError(String message) {
    if (message.contains('insufficient coins')) return 'Not enough coins.';
    if (message.contains('already owned')) return 'You already own this.';
    if (message.contains('level too low')) {
      return 'Your player level is too low for this character.';
    }
    if (message.contains('duplicate key')) return 'You already own this.';
    if (message.contains('item not found')) return 'Item not available.';
    return message;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.item,
    required this.coins,
    required this.onBuy,
    required this.onEquip,
  });

  final StoreItem item;
  final int? coins;
  final VoidCallback onBuy;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAfford = coins != null && coins! >= item.priceCoins;
    final levelLocked = item.kind == StoreItemKind.character &&
        item.unlockLevel != null &&
        item.unlockLevel! > 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StoreArt(item: item),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.classTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.classTitle!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _statusArea(theme, canAfford, levelLocked),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusArea(ThemeData theme, bool canAfford, bool levelLocked) {
    // ---- equipped ----
    if (item.equipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded,
                size: 16, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Text(
              'Equipped',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // ---- owned -> equip ----
    if (item.owned) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: onEquip,
          icon: const Icon(Icons.favorite_rounded, size: 18),
          label: const Text('Equip'),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
    }

    // ---- level gate (characters) ----
    if (levelLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Player level ${item.unlockLevel}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // ---- buy ----
    return Row(
      children: [
        Icon(Icons.monetization_on_rounded,
            size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          '${item.priceCoins}',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: canAfford ? onBuy : null,
          icon: const Icon(Icons.shopping_cart_rounded, size: 18),
          label: const Text('Buy'),
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

/// Placeholder art tile per category until real images ship.
class _StoreArt extends StatelessWidget {
  const _StoreArt({required this.item});

  final StoreItem item;

  static const List<Color> _palette = [
    Color(0xFFEF6C57),
    Color(0xFFF2A03D),
    Color(0xFF57B06F),
    Color(0xFF4E8FE6),
  ];

  @override
  Widget build(BuildContext context) {
    // Characters render their animated idle hero; every other category
    // keeps the local networked image / tinted tile.
    if (item.kind == StoreItemKind.character) {
      return CharacterIdleWidget(
        characterName: item.name,
        width: 64,
        height: 64,
        paused: true,
      );
    }
    final color = _palette[item.kind.index % _palette.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 64,
        height: 64,
        child: ColoredBox(
          color: color,
          child: item.imageUrl == null
              ? Icon(item.kind.icon, size: 32, color: Colors.white)
              : Image.asset(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(item.kind.icon, size: 32, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
