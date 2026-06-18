import 'package:flutter_test/flutter_test.dart';
import 'package:summamove_mobile/src/models/daily_summary.dart';

void main() {
  test('daily summary formats Laravel health values for the homepage', () {
    final summary = DailySummary.fromResponse({
      'data': {
        'steps': 3450,
        'workout_duration_seconds': 1080,
        'active_energy_burned_kcal': 212.7,
      },
    });

    expect(summary.stepsLabel, '3450');
    expect(summary.activeMinutesLabel, '18');
    expect(summary.caloriesLabel, '213');
  });

  test('daily summary keeps missing metrics visibly unknown', () {
    final summary = DailySummary.fromResponse({
      'data': {
        'steps': null,
        'workout_duration_seconds': null,
        'active_energy_burned_kcal': null,
      },
    });

    expect(summary.stepsLabel, '--');
    expect(summary.activeMinutesLabel, '--');
    expect(summary.caloriesLabel, '--');
  });
}
