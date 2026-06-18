import 'package:flutter_test/flutter_test.dart';
import 'package:summamove_mobile/src/services/offline_demo_repository.dart';

void main() {
  test('offline repository returns user-facing demo data', () async {
    final repository = OfflineDemoRepository()..useDemoUser();

    final home = await repository.home();
    final challenges = await repository.challenges();
    final shop = await repository.shop();
    final rankings = await repository.rankings('today');

    expect((home['user'] as Map)['name'], 'Demo User');
    expect(challenges, isNotEmpty);
    expect((shop['items'] as List), isNotEmpty);
    expect((rankings['rankings'] as List), isNotEmpty);
  });

  test('offline admin mutations update local data and audit log', () async {
    final repository = OfflineDemoRepository()..useDemoAdmin();

    await repository.adminAdjustPoints(1, 100, 'Demo correctie');
    await repository.adminCreateChallenge({
      'slug': 'demo-challenge',
      'title': 'Demo challenge',
      'description': 'Lokale demo challenge',
      'icon_key': 'walk',
      'difficulty': 'Beginner',
      'type': 'health_metric',
      'metric_type': 'steps',
      'target_value': 1000,
      'unit': 'count',
      'points': 10,
    });

    final users = await repository.adminUsers();
    final challenges = await repository.adminChallenges();
    final audits = await repository.adminAudits();

    final demoUser = users.cast<Map>().firstWhere((user) => user['id'] == 1);
    expect(demoUser['points_balance'], 1350);
    expect(challenges.cast<Map>().any((row) => row['slug'] == 'demo-challenge'),
        isTrue);
    expect(audits.cast<Map>().map((row) => row['action']),
        contains('challenge.created'));
  });

  test('offline demo health completes eligible challenge once', () async {
    final repository = OfflineDemoRepository()..useDemoAdmin();

    await repository.adminDemoHealth({
      'user_id': 1,
      'metric_type': 'steps',
      'value': 1000,
      'unit': 'count',
    });
    await repository.adminDemoHealth({
      'user_id': 1,
      'metric_type': 'steps',
      'value': 1000,
      'unit': 'count',
    });

    final user = (await repository.adminUsers())
        .cast<Map>()
        .firstWhere((row) => row['id'] == 1);
    repository.useDemoUser();
    final challenge = await repository.challenge(1);
    final assignment = challenge['assignment'] as Map;

    expect(assignment['status'], 'completed');
    expect(user['points_balance'], 1330);
  });
}
