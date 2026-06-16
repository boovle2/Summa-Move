import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summamove_mobile/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: SummaMoveApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the SummaMove login screen with local demo icon',
      (tester) async {
    await pumpApp(tester);

    expect(find.text('Summa Move'), findsOneWidget);
    expect(find.text('Inloggen'), findsOneWidget);
    expect(find.text('Gebruik admin-demo'), findsOneWidget);
    expect(find.byTooltip('Lokale demo'), findsOneWidget);
  });

  testWidgets('local demo customer option starts offline user session',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Lokale demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bekijk als klant'));
    await tester.pumpAndSettle();

    expect(find.text('Hoi Demo User!'), findsOneWidget);
    expect(find.text('Wat ga je vandaag doen?'), findsOneWidget);
  });

  testWidgets('local demo admin option opens admin-only menu entry',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Lokale demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    expect(find.text('Lokale demo'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
