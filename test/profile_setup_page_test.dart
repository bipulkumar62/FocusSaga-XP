import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focussaga_xp/core/theme/app_theme.dart';
import 'package:focussaga_xp/features/profile/presentation/profile_setup_page.dart';

/// Name entry: validation rules, guest fallback detection, and the
/// no-session guard. All runs with no Supabase session, like the app's
/// first frame.
void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileSetupPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('needsNameSetup', () {
    test('null and empty are not real names', () {
      expect(ProfileSetupPage.needsNameSetup(null), isTrue);
      expect(ProfileSetupPage.needsNameSetup(''), isTrue);
      expect(ProfileSetupPage.needsNameSetup('   '), isTrue);
    });

    test('the guest fallback is not a real name (any casing)', () {
      expect(ProfileSetupPage.needsNameSetup('Guest Learner'), isTrue);
      expect(ProfileSetupPage.needsNameSetup(' guest learner '), isTrue);
      expect(ProfileSetupPage.needsNameSetup('GUEST LEARNER'), isTrue);
    });

    test('real names pass', () {
      expect(ProfileSetupPage.needsNameSetup('Aditya'), isFalse);
      expect(ProfileSetupPage.needsNameSetup('Focus Ninja'), isFalse);
    });
  });

  testWidgets('renders the name entry form', (tester) async {
    await pumpPage(tester);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Save name'), findsOneWidget);
  });

  testWidgets('empty name is rejected with a validation message',
      (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Save name'));
    await tester.pump();
    expect(
      find.text('Name must be at least 2 characters'),
      findsOneWidget,
    );
  });

  testWidgets('a one-character name is rejected', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'A');
    await tester.tap(find.text('Save name'));
    await tester.pump();
    expect(
      find.text('Name must be at least 2 characters'),
      findsOneWidget,
    );
  });

  testWidgets('input is capped at 24 characters', (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'x' * 60);
    final field =
        tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 24);
  });

  testWidgets('saving without a session shows a friendly message',
      (tester) async {
    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'Aditya');
    await tester.tap(find.text('Save name'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Not signed in yet'),
      findsOneWidget,
    );
  });
}
