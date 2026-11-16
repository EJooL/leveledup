import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leveledup_mobile/main.dart';

void main() {
  testWidgets('LeveledUp app renders Login/Register and transitions to MainNavScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LeveledUpApp(),
      ),
    );

    // 1. Verify Login / Register screen renders first
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Sign In to LeveledUp'), findsOneWidget);

    // 2. Tap Sign In button and verify transition to MainNavScreen
    await tester.tap(find.text('Sign In to LeveledUp'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Quests'), findsOneWidget);
    expect(find.text('Skills'), findsOneWidget);
  });
}
