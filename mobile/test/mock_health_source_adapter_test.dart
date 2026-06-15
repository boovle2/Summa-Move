import 'package:flutter_test/flutter_test.dart';
import 'package:summamove_mobile/src/health/mock_health_source_adapter.dart';
import 'package:summamove_mobile/src/models/health_models.dart';

void main() {
  test('mock adapter normalizes all supported metrics', () async {
    final adapter = MockHealthSourceAdapter();
    final changes = await adapter.readChanges(
      from: DateTime.utc(2026, 6, 9),
      to: DateTime.utc(2026, 6, 10),
    );

    expect(await adapter.isAvailable(), isTrue);
    expect(await adapter.requestPermissions(supportedMetrics), isTrue);
    expect(
      changes.records.map((record) => record.metricType).toSet(),
      containsAll(
          supportedMetrics.where((metric) => metric != 'workout_session')),
    );
    expect(changes.workouts, hasLength(1));
    expect(changes.cursor, isNotNull);
  });
}
