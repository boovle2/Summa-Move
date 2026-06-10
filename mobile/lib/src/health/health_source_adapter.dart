import '../models/health_models.dart';

abstract interface class HealthSourceAdapter {
  HealthSource get source;

  Future<bool> isAvailable();

  Future<bool> requestPermissions(List<String> metrics);

  Future<HealthChanges> readChanges({
    required DateTime from,
    required DateTime to,
    String? cursor,
  });
}
