enum HealthSource {
  mock('health_connect', 'Mock / Health Connect'),
  healthConnect('health_connect', 'Health Connect'),
  healthKit('healthkit', 'Apple HealthKit'),
  samsungHealth('samsung_health', 'Samsung Health');

  const HealthSource(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

const supportedMetrics = <String>[
  'steps',
  'heart_rate',
  'active_energy_burned',
  'dietary_energy_consumed',
  'water_intake',
  'workout_session',
];

class NormalizedHealthRecord {
  const NormalizedHealthRecord({
    required this.externalId,
    required this.metricType,
    required this.value,
    required this.unit,
    this.measuredAt,
    this.measuredFrom,
    this.measuredTo,
    this.timezone,
    this.sourceApp,
  });

  final String externalId;
  final String metricType;
  final num value;
  final String unit;
  final DateTime? measuredAt;
  final DateTime? measuredFrom;
  final DateTime? measuredTo;
  final String? timezone;
  final String? sourceApp;

  factory NormalizedHealthRecord.fromJson(Map<String, dynamic> json) {
    return NormalizedHealthRecord(
      externalId: json['external_id'] as String,
      metricType: json['metric_type'] as String,
      value: json['value'] as num,
      unit: json['unit'] as String,
      measuredAt: _date(json['measured_at']),
      measuredFrom: _date(json['measured_from']),
      measuredTo: _date(json['measured_to']),
      timezone: json['timezone'] as String?,
      sourceApp: json['source_app'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'external_id': externalId,
        'metric_type': metricType,
        'value': value,
        'unit': unit,
        if (measuredAt != null) 'measured_at': measuredAt!.toUtc().toIso8601String(),
        if (measuredFrom != null) 'measured_from': measuredFrom!.toUtc().toIso8601String(),
        if (measuredTo != null) 'measured_to': measuredTo!.toUtc().toIso8601String(),
        if (timezone != null) 'timezone': timezone,
        if (sourceApp != null) 'source_app': sourceApp,
      };
}

class NormalizedWorkout {
  const NormalizedWorkout({
    required this.externalId,
    required this.activityType,
    required this.startedAt,
    required this.endedAt,
    required this.activeDurationSeconds,
    this.energyBurnedKcal,
    this.timezone,
  });

  final String externalId;
  final String activityType;
  final DateTime startedAt;
  final DateTime endedAt;
  final int activeDurationSeconds;
  final num? energyBurnedKcal;
  final String? timezone;

  factory NormalizedWorkout.fromJson(Map<String, dynamic> json) {
    return NormalizedWorkout(
      externalId: json['external_id'] as String,
      activityType: json['activity_type'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: DateTime.parse(json['ended_at'] as String),
      activeDurationSeconds: json['active_duration_seconds'] as int,
      energyBurnedKcal: json['energy_burned_kcal'] as num?,
      timezone: json['timezone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'external_id': externalId,
        'activity_type': activityType,
        'started_at': startedAt.toUtc().toIso8601String(),
        'ended_at': endedAt.toUtc().toIso8601String(),
        'active_duration_seconds': activeDurationSeconds,
        if (energyBurnedKcal != null) 'energy_burned_kcal': energyBurnedKcal,
        if (timezone != null) 'timezone': timezone,
      };
}

class HealthChanges {
  const HealthChanges({
    required this.records,
    required this.workouts,
    this.cursor,
  });

  final List<NormalizedHealthRecord> records;
  final List<NormalizedWorkout> workouts;
  final String? cursor;
}

DateTime? _date(dynamic value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;
