import 'package:flutter/services.dart';

import '../models/health_models.dart';
import 'health_source_adapter.dart';

class MethodChannelHealthAdapter implements HealthSourceAdapter {
  MethodChannelHealthAdapter(this.source);

  static const _channel = MethodChannel('summamove/health');

  @override
  final HealthSource source;

  @override
  Future<bool> isAvailable() async {
    return await _channel.invokeMethod<bool>(
          'isAvailable',
          {'source': source.apiValue},
        ) ??
        false;
  }

  @override
  Future<bool> requestPermissions(List<String> metrics) async {
    return await _channel.invokeMethod<bool>(
          'requestPermissions',
          {'source': source.apiValue, 'metrics': metrics},
        ) ??
        false;
  }

  @override
  Future<HealthChanges> readChanges({
    required DateTime from,
    required DateTime to,
    String? cursor,
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>(
      'readChanges',
      {
        'source': source.apiValue,
        'cursor': cursor,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    if (raw == null) {
      throw StateError('Native health bridge returned no result.');
    }

    return HealthChanges(
      cursor: raw['cursor'] as String?,
      records: _maps(raw['records'])
          .map(NormalizedHealthRecord.fromJson)
          .toList(growable: false),
      workouts: _maps(raw['workouts'])
          .map(NormalizedWorkout.fromJson)
          .toList(growable: false),
    );
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}

class HealthConnectAdapter extends MethodChannelHealthAdapter {
  HealthConnectAdapter() : super(HealthSource.healthConnect);
}

class HealthKitAdapter extends MethodChannelHealthAdapter {
  HealthKitAdapter() : super(HealthSource.healthKit);
}

class SamsungHealthAdapter extends MethodChannelHealthAdapter {
  SamsungHealthAdapter() : super(HealthSource.samsungHealth);
}
