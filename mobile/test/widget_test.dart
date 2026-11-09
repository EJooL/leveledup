import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leveledup_mobile/main.dart';

void main() {
  testWidgets('LeveledUp app renders Command Hub and navigation tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LeveledUpApp(),
      ),
    );

    expect(find.text('LEVELED UP'), findsOneWidget);
    expect(find.text('Command Hub'), findsOneWidget);
    expect(find.text('ATS Scanner'), findsOneWidget);
    expect(find.text('Quest Log'), findsOneWidget);
    expect(find.text('Skill Tree'), findsOneWidget);
  });
}

