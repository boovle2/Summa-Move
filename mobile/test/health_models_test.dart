import 'package:flutter_test/flutter_test.dart';
import 'package:summamove_mobile/src/models/health_models.dart';

void main() {
  test('record serialization converts timestamps to UTC', () {
    final record = NormalizedHealthRecord(
      externalId: 'steps-1',
      metricType: 'steps',
      value: 100,
      unit: 'count',
      measuredAt: DateTime.parse('2026-06-10T12:00:00+02:00'),
      timezone: 'Europe/Amsterdam',
    );

    expect(record.toJson()['measured_at'], '2026-06-10T10:00:00.000Z');
    expect(record.toJson()['timezone'], 'Europe/Amsterdam');
  });
}
