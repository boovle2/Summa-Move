import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summamove_mobile/main.dart';

void main() {
  testWidgets('shows the SummaMove login screen', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: SummaMoveApp()));
    await tester.pumpAndSettle();

    expect(find.text('Summa Move'), findsOneWidget);
    expect(find.text('Inloggen'), findsOneWidget);
    expect(find.text('Gebruik admin-demo'), findsOneWidget);
  });
}
