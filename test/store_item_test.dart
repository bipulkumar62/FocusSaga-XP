import 'package:flutter_test/flutter_test.dart';
import 'package:focussaga_xp/features/store/domain/store_item.dart';

void main() {
  group('StoreItem.fromJson', () {
    test('parses a background with ownership state', () {
      final item = StoreItem.fromJson(
        {
          'id': 'bg-1',
          'name': 'Moonlit Rice Fields',
          'description': 'Silver light over sleepy paddies.',
          'image_url': 'backgrounds/moonlit-rice-fields.png',
          'price_coins': 150,
        },
        kind: StoreItemKind.background,
        owned: true,
        equipped: true,
      );
      expect(item.kind, StoreItemKind.background);
      expect(item.priceCoins, 150);
      expect(item.owned, isTrue);
      expect(item.equipped, isTrue);
      expect(item.imageUrl, 'backgrounds/moonlit-rice-fields.png');
    });

    test('parses a character with level gate and owned-row id', () {
      final item = StoreItem.fromJson(
        {
          'id': 'char-2',
          'name': 'Yuki',
          'description': 'An ice spirit fox.',
          'image_url': null,
          'price_coins': 300,
          'unlock_level': 3,
        },
        kind: StoreItemKind.character,
        owned: false,
        equipped: false,
      );
      expect(item.kind.apiValue, 'character');
      expect(item.unlockLevel, 3);
      expect(item.owned, isFalse);
      expect(item.equipped, isFalse);
      expect(item.ownedRowId, isNull);
    });
  });

  group('StoreCatalog', () {
    test('filters by kind', () {
      const catalog = StoreCatalog(items: [
        StoreItem(
          kind: StoreItemKind.character,
          id: 'c1',
          name: 'A',
          description: '',
          priceCoins: 0,
          owned: false,
          equipped: false,
        ),
        StoreItem(
          kind: StoreItemKind.background,
          id: 'b1',
          name: 'B',
          description: '',
          priceCoins: 0,
          owned: false,
          equipped: false,
        ),
      ]);
      expect(catalog.forKind(StoreItemKind.character).length, 1);
      expect(catalog.forKind(StoreItemKind.timerSkin), isEmpty);
    });
  });
}
