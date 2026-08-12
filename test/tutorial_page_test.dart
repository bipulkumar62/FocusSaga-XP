import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focussaga_xp/core/theme/app_theme.dart';
import 'package:focussaga_xp/features/tutorial/presentation/tutorial_page.dart';

void main() {
  Future<void> pumpTutorial(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const TutorialPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows slide 1: title, description, dots, Next and Skip',
      (tester) async {
    await pumpTutorial(tester);

    expect(find.text('Set a timer and start focusing'), findsOneWidget);
    expect(
      find.textContaining('Pick a session length'),
      findsOneWidget,
    );
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Get Started'), findsNothing);
    // 5 progress dots, active one wider.
    expect(
      find.byType(AnimatedContainer),
      findsNWidgets(5),
    );
  });

  testWidgets('Next walks through all 5 slides, Back goes back',
      (tester) async {
    await pumpTutorial(tester);

    const slideTitles = [
      'Set a timer and start focusing',
      'Earn XP by completing sessions',
      'Level up characters & unlock forms',
      'Buy backgrounds & timer skins',
      'Daily challenges & rankings',
    ];

    for (var i = 1; i < slideTitles.length; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(slideTitles[i]), findsOneWidget,
          reason: 'slide ${i + 1} should be visible');
    }

    // Last slide: Skip hidden, Get Started shown.
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Buy backgrounds & timer skins'), findsOneWidget);
  });

  testWidgets('Skip is a no-op when signed out but must not throw',
      (tester) async {
    await pumpTutorial(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Still on the tutorial, no exceptions escaped.
    expect(find.text('Set a timer and start focusing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Get Started on the last slide must not throw when signed out',
      (tester) async {
    await pumpTutorial(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
