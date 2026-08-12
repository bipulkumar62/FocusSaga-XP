import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focussaga_xp/shared/widgets/character_idle_widget.dart';

void main() {
  group('CharacterIdleSpec', () {
    test('exposes exactly the six original warriors', () {
      expect(CharacterIdleSpec.all, hasLength(6));
      expect(
        CharacterIdleSpec.all.map((s) => s.id),
        ['kairo', 'tetsu', 'rin', 'kuro', 'sora', 'arashi'],
      );
    });

    test('every warrior has a class title and a non-black accent', () {
      for (final spec in CharacterIdleSpec.all) {
        expect(spec.classTitle, isNotEmpty);
        expect(spec.accent, isNot(const Color(0xFF000000)));
        expect(spec.previewPath, 'characters/${spec.id}/preview.png');
      }
    });

    test('forName finds heroes by display name (case-insensitive)', () {
      expect(CharacterIdleSpec.forName('Kairo')?.id, 'kairo');
      expect(CharacterIdleSpec.forName('arashi')?.id, 'arashi');
      expect(CharacterIdleSpec.forName('  SORA  ')?.id, 'sora');
    });

    test('forName returns null for unknown names', () {
      expect(CharacterIdleSpec.forName('Pikachu'), isNull);
      expect(CharacterIdleSpec.forName(''), isNull);
      expect(CharacterIdleSpec.forName(null), isNull);
    });
  });

  group('CharacterIdleWidget', () {
    testWidgets('renders a known hero without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CharacterIdleWidget(
              characterName: 'Kairo',
              width: 96,
              height: 96,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('paused mode renders a static hero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CharacterIdleWidget(
              characterName: 'Arashi',
              width: 64,
              height: 64,
              paused: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('unknown names fall back to the warrior silhouette',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CharacterIdleWidget(characterName: 'Totoro'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byType(CharacterSilhouette),
        findsOneWidget,
        reason: 'unknown hero must render the deterministic silhouette',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CharacterSilhouette', () {
    testWidgets('is deterministic per name and always renders', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CharacterSilhouette(characterName: 'Kairo'),
          ),
        ),
      );
      expect(find.byIcon(Icons.sports_martial_arts), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
