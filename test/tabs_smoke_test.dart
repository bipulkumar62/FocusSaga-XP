import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focussaga_xp/core/theme/app_theme.dart';
import 'package:focussaga_xp/features/challenges/presentation/challenges_tab.dart';
import 'package:focussaga_xp/features/characters/presentation/characters_tab.dart';
import 'package:focussaga_xp/features/focus/presentation/focus_tab.dart';
import 'package:focussaga_xp/features/profile/presentation/profile_tab.dart';
import 'package:focussaga_xp/features/ranking/presentation/ranking_tab.dart';
import 'package:focussaga_xp/features/store/presentation/store_tab.dart';
import 'package:focussaga_xp/features/terms/presentation/terms_page.dart';

/// Renders every screen with no Supabase session and asserts its
/// loading/empty/error state shows real UI without layout exceptions.
void main() {
  Future<void> pumpTab(WidgetTester tester, Widget tab) async {
    // Tabs live inside the shell's Scaffold in the real app, so provide one.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: tab),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Focus tab renders its header and Start button', (tester) async {
    await pumpTab(tester, const FocusTab());
    expect(find.text('FocusSaga XP'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('Characters tab shows the empty state', (tester) async {
    await pumpTab(tester, const CharactersTab());
    expect(find.textContaining('No characters yet.'), findsOneWidget);
  });

  testWidgets('Store tab shows the category chips and empty catalog',
      (tester) async {
    await pumpTab(tester, const StoreTab());
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Nothing here yet.'), findsOneWidget);
  });

  testWidgets('Challenges tab shows the empty state', (tester) async {
    await pumpTab(tester, const ChallengesTab());
    expect(find.textContaining('No challenges today.'), findsOneWidget);
  });

  testWidgets('Ranking tab shows Daily/Weekly tabs and empty boards',
      (tester) async {
    await pumpTab(tester, const RankingTab());
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.textContaining('No activity yet today.'), findsOneWidget);
  });

  testWidgets('Profile tab shows guest fallbacks and logout', (tester) async {
    await pumpTab(tester, const ProfileTab());
    expect(find.text('Guest Learner'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Logout'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('Terms page shows its actions', (tester) async {
    await pumpTab(tester, const TermsPage());
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Accept & Continue'), findsOneWidget);
  });
}
