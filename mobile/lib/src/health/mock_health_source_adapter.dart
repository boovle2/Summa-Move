import '../models/health_models.dart';
import 'health_source_adapter.dart';

class MockHealthSourceAdapter implements HealthSourceAdapter {
  @override
  HealthSource get source => HealthSource.mock;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> requestPermissions(List<String> metrics) async =>
      metrics.every(supportedMetrics.contains);

  @override
  Future<HealthChanges> readChanges({
    required DateTime from,
    required DateTime to,
    String? cursor,
  }) async {
    final stamp = to.toUtc();
    final id = stamp.millisecondsSinceEpoch;

    return HealthChanges(
      cursor: 'mock-$id',
      records: [
        NormalizedHealthRecord(
          externalId: 'mock-steps-$id',
          metricType: 'steps',
          value: 8450,
          unit: 'count',
          measuredFrom: from,
          measuredTo: to,
          timezone: 'Europe/Amsterdam',
          sourceApp: 'SummaMove Mock',
        ),
        NormalizedHealthRecord(
          externalId: 'mock-heart-$id',
          metricType: 'heart_rate',
          value: 72,
          unit: 'bpm',
          measuredAt: stamp,
          timezone: 'Europe/Amsterdam',
          sourceApp: 'SummaMove Mock',
        ),
        NormalizedHealthRecord(
          externalId: 'mock-active-energy-$id',
          metricType: 'active_energy_burned',
          value: 315,
          unit: 'kcal',
          measuredFrom: from,
          measuredTo: to,
          timezone: 'Europe/Amsterdam',
          sourceApp: 'SummaMove Mock',
        ),
        NormalizedHealthRecord(
          externalId: 'mock-dietary-energy-$id',
          metricType: 'dietary_energy_consumed',
          value: 640,
          unit: 'kcal',
          measuredAt: stamp,
          timezone: 'Europe/Amsterdam',
          sourceApp: 'SummaMove Mock',
        ),
        NormalizedHealthRecord(
          externalId: 'mock-water-$id',
          metricType: 'water_intake',
          value: 500,
          unit: 'ml',
          measuredAt: stamp,
          timezone: 'Europe/Amsterdam',
          sourceApp: 'SummaMove Mock',
        ),
      ],
      workouts: [
        NormalizedWorkout(
          externalId: 'mock-workout-$id',
          activityType: 'running',
          startedAt: to.subtract(const Duration(minutes: 30)),
          endedAt: to,
          activeDurationSeconds: 1800,
          energyBurnedKcal: 240,
          timezone: 'Europe/Amsterdam',
        ),
      ],
    );
  }
}
