import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focussaga_xp/app.dart';

void main() {
  testWidgets('Not logged in -> redirected to splash (guest bootstrap)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FocusSagaXpApp()));
    await tester.pumpAndSettle();

    // No Supabase session/client in the test env, so the splash screen
    // surfaces its error + retry state instead of a Google login.
    expect(find.text('Could not start FocusSaga XP'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}