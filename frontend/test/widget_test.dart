// This is a basic Flutter widget test for CDA Career Companion.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cda_student_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CdaCareerCompanionApp()));
    await tester.pumpAndSettle();

    // Verify app widget is rendered.
    expect(find.byType(CdaCareerCompanionApp), findsOneWidget);
  });
}
