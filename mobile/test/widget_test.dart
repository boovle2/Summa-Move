import 'package:flutter_test/flutter_test.dart';
import 'package:summamove_mobile/main.dart';

void main() {
  testWidgets('shows the SummaMove sync controls', (tester) async {
    await tester.pumpWidget(const SummaMoveApp());

    expect(find.text('SummaMove health-sync'), findsOneWidget);
    expect(find.text('Inloggen'), findsOneWidget);
    expect(find.text('Handmatig synchroniseren'), findsOneWidget);
  });
}
