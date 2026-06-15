class DailySummary {
  const DailySummary({
    required this.steps,
    required this.workoutDurationSeconds,
    required this.activeEnergyBurnedKcal,
  });

  final num? steps;
  final int? workoutDurationSeconds;
  final num? activeEnergyBurnedKcal;

  factory DailySummary.fromResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>;

    return DailySummary(
      steps: data['steps'] as num?,
      workoutDurationSeconds: data['workout_duration_seconds'] as int?,
      activeEnergyBurnedKcal: data['active_energy_burned_kcal'] as num?,
    );
  }

  String get stepsLabel => steps == null ? '--' : steps!.round().toString();
  String get activeMinutesLabel => workoutDurationSeconds == null
      ? '--'
      : (workoutDurationSeconds! / 60).round().toString();
  String get caloriesLabel => activeEnergyBurnedKcal == null
      ? '--'
      : activeEnergyBurnedKcal!.round().toString();
}
