import 'package:uuid/uuid.dart';

import '../health/health_source_adapter.dart';
import '../models/health_models.dart';
import 'api_client.dart';

class HealthSyncService {
  HealthSyncService({
    required this.api,
    required this.deviceId,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final ApiClient api;
  final String deviceId;
  final Uuid _uuid;

  Future<Map<String, dynamic>> sync(HealthSourceAdapter adapter) async {
    if (!await adapter.isAvailable()) {
      throw StateError('${adapter.source.label} is niet beschikbaar.');
    }
    if (!await adapter.requestPermissions(supportedMetrics)) {
      throw StateError('Read-permissions zijn niet toegekend.');
    }

    await api.put('/devices/$deviceId', {
      'platform': adapter.source == HealthSource.healthKit ? 'ios' : 'android',
      'active_source': adapter.source.apiValue,
      'app_version': '0.1.0',
      'granted_metrics': supportedMetrics,
    });

    final status = await this.status();
    final connections = ((status['data'] as Map<String, dynamic>)['connections'] as List)
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item));
    final activeConnection = connections.firstWhere(
      (connection) => connection['source'] == adapter.source.apiValue,
      orElse: () => <String, dynamic>{},
    );

    final now = DateTime.now().toUtc();
    final changes = await adapter.readChanges(
      from: now.subtract(const Duration(days: 1)),
      to: now,
      cursor: activeConnection['cursor'] as String?,
    );

    return api.post('/health/sync', {
      'sync_id': _uuid.v4(),
      'device_id': deviceId,
      'source': adapter.source.apiValue,
      'cursor': changes.cursor,
      'records': changes.records.map((record) => record.toJson()).toList(),
      'workouts': changes.workouts.map((workout) => workout.toJson()).toList(),
    });
  }

  Future<Map<String, dynamic>> dailySummary({
    required DateTime date,
    String timezone = 'Europe/Amsterdam',
  }) {
    final day =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return api.get('/health/daily-summary?date=$day&timezone=$timezone');
  }

  Future<Map<String, dynamic>> status() {
    return api.get('/health/status?device_id=$deviceId');
  }
}
