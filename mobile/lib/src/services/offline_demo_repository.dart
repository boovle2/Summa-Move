import 'product_repository.dart';

class OfflineDemoRepository implements ProductRepository {
  int _activeUserId = 1;
  int _syncRuns = 1;

  final List<Map<String, dynamic>> _users = [
    {
      'id': 1,
      'name': 'Demo User',
      'email': 'demo@example.com',
      'role': 'user',
      'points_balance': 1250,
      'level': 3,
      'streak_days': 3,
      'profile_status': 'Actief',
      'active_character_key': 'directions_run',
    },
    {
      'id': 2,
      'name': 'SummaMove Admin',
      'email': 'admin@summamove.test',
      'role': 'admin',
      'points_balance': 5000,
      'level': 10,
      'streak_days': 12,
      'profile_status': 'Beheerder',
      'active_character_key': 'shield',
    },
    {
      'id': 3,
      'name': 'Emma Johnson',
      'email': 'emma@summamove.test',
      'role': 'user',
      'points_balance': 2650,
      'level': 6,
      'streak_days': 8,
      'profile_status': 'Actief',
      'active_character_key': 'fitness_center',
    },
    {
      'id': 4,
      'name': 'Lucas van Dijk',
      'email': 'lucas@summamove.test',
      'role': 'user',
      'points_balance': 2420,
      'level': 5,
      'streak_days': 5,
      'profile_status': 'Actief',
      'active_character_key': 'directions_bike',
    },
    {
      'id': 5,
      'name': 'Sophie Martinez',
      'email': 'sophie@summamove.test',
      'role': 'user',
      'points_balance': 2850,
      'level': 6,
      'streak_days': 10,
      'profile_status': 'Actief',
      'active_character_key': 'sports_soccer',
    },
    {
      'id': 6,
      'name': 'Noah Bakker',
      'email': 'noah@summamove.test',
      'role': 'user',
      'points_balance': 2180,
      'level': 5,
      'streak_days': 4,
      'profile_status': 'Actief',
      'active_character_key': 'sports_basketball',
    },
  ];

  final List<Map<String, dynamic>> _challenges = [
    _challenge(1, 'korte-wandeling', 'Korte wandeling',
        'Zet 6.000 stappen vandaag', 'walk', 'Beginner', 'health_metric',
        metricType: 'steps', target: 6000, unit: 'count', points: 80),
    _challenge(2, 'trap-meester', 'Trap meester', 'Loop 10x de trap op',
        'stairs', 'Beginner', 'workout',
        target: 600, unit: 'seconds', points: 150),
    _challenge(3, 'ochtendwandeling', 'Ochtendwandeling',
        'Zet 10.000 stappen vandaag', 'walk', 'Gemiddeld', 'health_metric',
        metricType: 'steps', target: 10000, unit: 'count', points: 120),
    _challenge(4, 'actieve-dag', 'Actieve dag', 'Beweeg 30 minuten actief',
        'timer', 'Gemiddeld', 'workout',
        target: 1800, unit: 'seconds', points: 100),
    _challenge(5, 'hydratatie', 'Hydratatie', 'Drink 2 liter water vandaag',
        'water', 'Beginner', 'health_metric',
        metricType: 'water_intake', target: 2000, unit: 'ml', points: 50),
    _challenge(6, 'quick-walk', '5 Min Wandelen',
        'Loop 5 minuten buiten of binnen', 'walk', 'Beginner', 'workout',
        activityType: 'walking',
        target: 300,
        unit: 'seconds',
        points: 30,
        quick: true),
    _challenge(7, 'quick-stretch', 'Stretch Break',
        '5 minuten rekken en strekken', 'stretch', 'Beginner', 'workout',
        activityType: 'yoga',
        target: 300,
        unit: 'seconds',
        points: 25,
        quick: true),
  ];

  final List<Map<String, dynamic>> _assignments = [
    {
      'id': 1,
      'user_id': 1,
      'challenge_id': 1,
      'status': 'started',
      'progress': 5450,
      'target_value': 6000,
      'started_at': '2026-06-16T08:00:00Z',
      'completed_at': null,
    },
    {
      'id': 2,
      'user_id': 1,
      'challenge_id': 4,
      'status': 'started',
      'progress': 1200,
      'target_value': 1800,
      'started_at': '2026-06-16T08:15:00Z',
      'completed_at': null,
    },
    {
      'id': 3,
      'user_id': 1,
      'challenge_id': 5,
      'status': 'started',
      'progress': 750,
      'target_value': 2000,
      'started_at': '2026-06-16T08:30:00Z',
      'completed_at': null,
    },
  ];

  final List<Map<String, dynamic>> _shopItems = [
    _shopItem(1, 'sportief', 'Sportief', 'directions_run', 'free', 0, 'Gratis'),
    _shopItem(2, 'student', 'Student', 'school', 'free', 0, 'Gratis'),
    _shopItem(3, 'zakelijk', 'Zakelijk', 'business', 'free', 0, 'Gratis'),
    _shopItem(4, 'fitness-fan', 'Fitness Fan', 'fitness_center', 'sport', 100,
        '5 challenges voltooien'),
    _shopItem(5, 'hardloper', 'Hardloper', 'sprint', 'sport', 150,
        '3x hardloop challenge'),
    _shopItem(6, 'fietser', 'Fietser', 'directions_bike', 'sport', 150,
        '50km gefietst'),
    _shopItem(7, 'basketballer', 'Basketballer', 'sports_basketball', 'team',
        200, '5 team challenges'),
    _shopItem(8, 'kampioen', 'Kampioen', 'emoji_events', 'top', 400,
        'Top 3 leaderboard'),
    _shopItem(
        9, 'legendary', 'Legendary', 'star', 'top', 500, '30 dagen streak'),
  ];

  final Map<int, Set<int>> _ownedItemIds = {
    1: {1, 2, 3},
    2: {1, 2, 3, 8, 9},
  };

  final Map<int, Map<String, dynamic>> _settingsByUser = {
    1: {
      'notifications': true,
      'sound': true,
      'theme': 'light',
      'language': 'nl',
    },
    2: {
      'notifications': false,
      'sound': true,
      'theme': 'dark',
      'language': 'nl',
    },
  };

  final Map<int, Map<String, dynamic>> _dailySummaryByUser = {
    1: {
      'steps': 5450,
      'water_intake_ml': 750,
      'active_energy_burned_kcal': 320,
      'workout_duration_seconds': 1200,
    },
    2: {
      'steps': 8200,
      'water_intake_ml': 1200,
      'active_energy_burned_kcal': 410,
      'workout_duration_seconds': 1800,
    },
  };

  final Map<int, List<int>> _friendIdsByUser = {
    1: [3, 4, 5, 6],
    2: [1, 3],
  };

  final List<Map<String, dynamic>> _friendRequests = [
    {
      'id': 1,
      'addressee_id': 1,
      'user': {
        'id': 6,
        'name': 'Noah Bakker',
        'points_balance': 2180,
        'level': 5,
        'active_character_key': 'sports_basketball',
        'profile_status': 'Actief',
      },
    },
  ];

  final List<Map<String, dynamic>> _teams = [
    {
      'id': 1,
      'name': 'Klas 3B',
      'description': 'SummaSport klas',
      'points': 4850,
      'users_count': 5,
    },
    {
      'id': 2,
      'name': 'Running Club',
      'description': 'Samen hardlopen',
      'points': 8200,
      'users_count': 3,
    },
  ];

  final Map<int, List<Map<String, dynamic>>> _messagesByFriend = {
    3: [
      {
        'id': 1,
        'sender_id': 3,
        'recipient_id': 1,
        'body': 'Doe je mee met de hardloop uitdaging?',
        'created_at': '2026-06-16T08:00:00Z',
      },
      {
        'id': 2,
        'sender_id': 1,
        'recipient_id': 3,
        'body': 'Ja, ik start hem straks na school.',
        'created_at': '2026-06-16T08:05:00Z',
      },
    ],
  };

  final List<Map<String, dynamic>> _audits = [
    {
      'id': 1,
      'action': 'offline_demo.started',
      'created_at': '2026-06-16T09:00:00Z',
    },
  ];

  void useDemoUser() {
    _activeUserId = 1;
  }

  void useDemoAdmin() {
    _activeUserId = 2;
  }

  @override
  Future<Map<String, dynamic>> home() async {
    final user = _activeUser;
    final featured = _firstAssignmentWhere(
      (row) => row['user_id'] == _activeUserId && row['status'] == 'started',
    );

    return {
      'user': _userSummary(user),
      'daily_summary': _dailySummaryFor(_activeUserId),
      'featured_challenge': featured == null
          ? null
          : {
              ..._copy(featured),
              'challenge':
                  _copy(_findChallenge(featured['challenge_id'] as int)),
            },
    };
  }

  @override
  Future<Map<String, dynamic>> profile() async {
    final user = _activeUser;
    final completed = _assignments
        .where((row) =>
            row['user_id'] == _activeUserId && row['status'] == 'completed')
        .length;
    final daily = _dailySummaryFor(_activeUserId);

    return {
      'user': _userSummary(user),
      'stats': {
        'completed_challenges': completed,
        'weekly_steps': (daily['steps'] as num?) ?? 0,
        'weekly_active_minutes':
            (((daily['workout_duration_seconds'] as num?) ?? 0) / 60).round(),
      },
      'favorite_sports': ['Wandelen', 'Fietsen', 'Fitness'],
      'achievements': [
        {
          'id': 1,
          'title': 'Eerste Win',
          'icon_key': 'emoji_events',
          'earned_at': completed > 0 ? '2026-06-16T09:00:00Z' : null,
        },
        {
          'id': 2,
          'title': '7 Dagen Streak',
          'icon_key': 'local_fire_department',
          'earned_at':
              (user['streak_days'] as num) >= 7 ? '2026-06-16T09:00:00Z' : null,
        },
        {
          'id': 3,
          'title': 'Team Player',
          'icon_key': 'groups',
          'earned_at': null,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> settings() async =>
      _copy(_settingsByUser[_activeUserId] ?? _defaultSettings());

  @override
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body) async {
    final current = _settingsByUser.putIfAbsent(
      _activeUserId,
      _defaultSettings,
    );
    current.addAll(body);
    return _copy(current);
  }

  @override
  Future<List<dynamic>> challenges() async => _challenges
      .where((row) => row['active'] == true)
      .map((row) => _challengeWithAssignment(row, _activeUserId))
      .toList();

  @override
  Future<Map<String, dynamic>> challenge(int id) async =>
      _challengeWithAssignment(_findChallenge(id), _activeUserId);

  @override
  Future<void> startChallenge(int id) async {
    final challenge = _findChallenge(id);
    final assignment = _assignmentFor(_activeUserId, id);
    if (assignment == null) {
      _assignments.add({
        'id': _nextId(_assignments),
        'user_id': _activeUserId,
        'challenge_id': id,
        'status': 'started',
        'progress': 0,
        'target_value': challenge['target_value'],
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'completed_at': null,
      });
    } else if (assignment['status'] != 'completed') {
      assignment['status'] = 'started';
      assignment['started_at'] ??= DateTime.now().toUtc().toIso8601String();
    }
    _recalculateUser(_activeUserId);
  }

  @override
  Future<List<dynamic>> friends() async =>
      _friendIdsByUser[_activeUserId]
          ?.map(_findUser)
          .map(_publicUserSummary)
          .toList() ??
      [];

  @override
  Future<List<dynamic>> friendRequests() async => _friendRequests
      .where((row) => row['addressee_id'] == _activeUserId)
      .map(_copyRequest)
      .toList();

  @override
  Future<List<dynamic>> teams() async => _teams.map(_copy).toList();

  @override
  Future<void> acceptFriendRequest(int id) async {
    final index = _friendRequests.indexWhere((row) => row['id'] == id);
    if (index == -1) {
      return;
    }
    final request = _friendRequests.removeAt(index);
    final user = Map<String, dynamic>.from(request['user'] as Map);
    _friendIdsByUser
        .putIfAbsent(_activeUserId, () => <int>[])
        .add(user['id'] as int);
  }

  @override
  Future<void> declineFriendRequest(int id) async {
    _friendRequests.removeWhere((row) => row['id'] == id);
  }

  @override
  Future<void> challengeFriend(int id) async {
    await startChallenge(1);
    _audit('friend.challenge.sent');
  }

  @override
  Future<Map<String, dynamic>> messages(int id) async => {
        'friend': _publicUserSummary(_findUser(id)),
        'messages': (_messagesByFriend[id] ?? []).map(_copy).toList(),
      };

  @override
  Future<void> sendMessage(int id, String body) async {
    _messagesByFriend.putIfAbsent(id, () => []).add({
      'id': _nextId(_messagesByFriend.values.expand((rows) => rows)),
      'sender_id': _activeUserId,
      'recipient_id': id,
      'body': body,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<Map<String, dynamic>> shop() async {
    final user = _activeUser;
    final owned = _ownedItemIds.putIfAbsent(_activeUserId, () => {1, 2, 3});

    return {
      'points_balance': user['points_balance'],
      'active_character_key': user['active_character_key'],
      'items': _shopItems
          .where((row) => row['active'] == true)
          .map((row) => {..._copy(row), 'owned': owned.contains(row['id'])})
          .toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> purchase(int id) async {
    final item = _findShopItem(id);
    final user = _activeUser;
    final owned = _ownedItemIds.putIfAbsent(_activeUserId, () => {1, 2, 3});
    if (owned.contains(id)) {
      return shop();
    }
    final cost = item['points_cost'] as int;
    if ((user['points_balance'] as int) < cost) {
      throw StateError('Niet genoeg punten.');
    }
    user['points_balance'] = (user['points_balance'] as int) - cost;
    user['level'] = _levelFor(user['points_balance'] as int);
    owned.add(id);
    _audit('shop_item.purchased');
    return shop();
  }

  @override
  Future<void> equip(int id) async {
    final item = _findShopItem(id);
    final owned = _ownedItemIds.putIfAbsent(_activeUserId, () => {1, 2, 3});
    if (item['points_cost'] != 0 && !owned.contains(id)) {
      throw StateError('Character is nog niet vrijgespeeld.');
    }
    _activeUser['active_character_key'] = item['icon_key'];
  }

  @override
  Future<Map<String, dynamic>> rankings(String period) async {
    final values = <int, num>{
      1: switch (period) {
        'week' => 38200,
        'progress' => 55,
        'friends' => 1250,
        _ => 5450,
      },
      3: switch (period) {
        'week' => 44100,
        'progress' => 63,
        'friends' => 2650,
        _ => 7200,
      },
      4: switch (period) {
        'week' => 39700,
        'progress' => 48,
        'friends' => 2420,
        _ => 6800,
      },
      5: switch (period) {
        'week' => 46600,
        'progress' => 71,
        'friends' => 2850,
        _ => 8100,
      },
      6: switch (period) {
        'week' => 33500,
        'progress' => 42,
        'friends' => 2180,
        _ => 5900,
      },
    };
    final rows = _users
        .where((user) => user['role'] == 'user')
        .where((user) =>
            period != 'friends' ||
            user['id'] == _activeUserId ||
            (_friendIdsByUser[_activeUserId] ?? []).contains(user['id']))
        .map((user) => {
              ..._publicUserSummary(user),
              'value': values[user['id']] ?? 0,
            })
        .toList()
      ..sort((a, b) => (b['value'] as num).compareTo(a['value'] as num));

    return {
      'period': period,
      'rankings': rows
          .asMap()
          .entries
          .map((entry) => {...entry.value, 'rank': entry.key + 1})
          .toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> adminDashboard() async => {
        'users': _users.length,
        'challenges': _challenges.where((row) => row['active'] == true).length,
        'completed_assignments':
            _assignments.where((row) => row['status'] == 'completed').length,
        'sync_runs': _syncRuns,
      };

  @override
  Future<List<dynamic>> adminUsers() async => _users.map(_copy).toList();

  @override
  Future<List<dynamic>> adminChallenges() async =>
      _challenges.map(_copy).toList();

  @override
  Future<List<dynamic>> adminShopItems() async =>
      _shopItems.map(_copy).toList();

  @override
  Future<List<dynamic>> adminTeams() async => _teams.map(_copy).toList();

  @override
  Future<List<dynamic>> adminAudits() async => _audits.map(_copy).toList();

  @override
  Future<void> adminCreateChallenge(Map<String, dynamic> body) async {
    _challenges.add({
      'id': _nextId(_challenges),
      'active': true,
      'sort_order': _challenges.length,
      'is_quick': false,
      'instructions': null,
      ...body,
    });
    _audit('challenge.created');
  }

  @override
  Future<void> adminUpdateChallenge(int id, Map<String, dynamic> body) async {
    _findChallenge(id).addAll(body);
    _audit('challenge.updated');
  }

  @override
  Future<void> adminDeleteChallenge(int id) async {
    _findChallenge(id)['active'] = false;
    _audit('challenge.deactivated');
  }

  @override
  Future<void> adminCreateShopItem(Map<String, dynamic> body) async {
    _shopItems.add({
      'id': _nextId(_shopItems),
      'active': true,
      'sort_order': _shopItems.length,
      'requirement': body['requirement'] ?? 'Aangemaakt in lokale demo',
      ...body,
    });
    _audit('shop_item.created');
  }

  @override
  Future<void> adminUpdateShopItem(int id, Map<String, dynamic> body) async {
    _findShopItem(id).addAll(body);
    _audit('shop_item.updated');
  }

  @override
  Future<void> adminDeleteShopItem(int id) async {
    _findShopItem(id)['active'] = false;
    _audit('shop_item.deactivated');
  }

  @override
  Future<void> adminCreateTeam(Map<String, dynamic> body) async {
    _teams.add({
      'id': _nextId(_teams),
      'points': 0,
      'users_count': 0,
      ...body,
    });
    _audit('team.created');
  }

  @override
  Future<void> adminUpdateTeam(int id, Map<String, dynamic> body) async {
    _findTeam(id).addAll(body);
    _audit('team.updated');
  }

  @override
  Future<void> adminDeleteTeam(int id) async {
    _teams.removeWhere((row) => row['id'] == id);
    _audit('team.deleted');
  }

  @override
  Future<void> adminAssign(int userId, int challengeId) async {
    final challenge = _findChallenge(challengeId);
    final assignment = _assignmentFor(userId, challengeId);
    if (assignment == null) {
      _assignments.add({
        'id': _nextId(_assignments),
        'user_id': userId,
        'challenge_id': challengeId,
        'status': 'started',
        'progress': 0,
        'target_value': challenge['target_value'],
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'completed_at': null,
      });
    } else {
      assignment
        ..['status'] = 'started'
        ..['progress'] = 0
        ..['target_value'] = challenge['target_value']
        ..['completed_at'] = null;
    }
    _audit('challenge.assigned');
  }

  @override
  Future<void> adminAdjustPoints(int userId, int amount, String reason) async {
    final user = _findUser(userId);
    user['points_balance'] = (user['points_balance'] as int) + amount;
    user['level'] = _levelFor(user['points_balance'] as int);
    _audit('points.adjusted');
  }

  @override
  Future<void> adminDemoHealth(Map<String, dynamic> body) async {
    final userId = body['user_id'] as int? ?? _activeUserId;
    final summary = _dailySummaryByUser.putIfAbsent(userId, _emptyDailySummary);

    if (body['metric_type'] != null) {
      final metric = body['metric_type'].toString();
      final value = (body['value'] as num?) ?? 0;
      final key = switch (metric) {
        'steps' => 'steps',
        'water_intake' => 'water_intake_ml',
        'active_energy_burned' => 'active_energy_burned_kcal',
        _ => null,
      };
      if (key != null) {
        summary[key] = ((summary[key] as num?) ?? 0) + value;
      }
    }

    if (body['active_duration_seconds'] != null) {
      summary['workout_duration_seconds'] =
          ((summary['workout_duration_seconds'] as num?) ?? 0) +
              (body['active_duration_seconds'] as num);
    }

    _syncRuns++;
    _recalculateUser(userId);
    _audit('demo_health.created');
  }

  Map<String, dynamic> get _activeUser => _findUser(_activeUserId);

  Map<String, dynamic> _findUser(int id) =>
      _users.firstWhere((row) => row['id'] == id);

  Map<String, dynamic> _findChallenge(int id) =>
      _challenges.firstWhere((row) => row['id'] == id);

  Map<String, dynamic> _findShopItem(int id) =>
      _shopItems.firstWhere((row) => row['id'] == id);

  Map<String, dynamic> _findTeam(int id) =>
      _teams.firstWhere((row) => row['id'] == id);

  Map<String, dynamic>? _assignmentFor(int userId, int challengeId) =>
      _firstAssignmentWhere(
        (row) => row['user_id'] == userId && row['challenge_id'] == challengeId,
      );

  Map<String, dynamic>? _firstAssignmentWhere(
    bool Function(Map<String, dynamic> row) test,
  ) {
    for (final row in _assignments) {
      if (test(row)) {
        return row;
      }
    }
    return null;
  }

  Map<String, dynamic> _challengeWithAssignment(
    Map<String, dynamic> row,
    int userId,
  ) {
    final assignment = _assignmentFor(userId, row['id'] as int);
    return {
      ..._copy(row),
      'assignment': assignment == null ? null : _copy(assignment),
    };
  }

  Map<String, dynamic> _dailySummaryFor(int userId) =>
      _copy(_dailySummaryByUser[userId] ?? _emptyDailySummary());

  Map<String, dynamic> _copy(Map<String, dynamic> row) =>
      Map<String, dynamic>.from(row);

  Map<String, dynamic> _copyRequest(Map<String, dynamic> request) => {
        ..._copy(request),
        'user': Map<String, dynamic>.from(request['user'] as Map),
      };

  Map<String, dynamic> _userSummary(Map<String, dynamic> user) => {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'role': user['role'],
        'points_balance': user['points_balance'],
        'level': user['level'],
        'streak_days': user['streak_days'],
        'profile_status': user['profile_status'],
        'active_character_key': user['active_character_key'],
      };

  Map<String, dynamic> _publicUserSummary(Map<String, dynamic> user) => {
        'id': user['id'],
        'name': user['name'],
        'points_balance': user['points_balance'],
        'level': user['level'],
        'streak_days': user['streak_days'],
        'profile_status': user['profile_status'],
        'active_character_key': user['active_character_key'],
      };

  Map<String, dynamic> _defaultSettings() => {
        'notifications': true,
        'sound': true,
        'theme': 'light',
        'language': 'nl',
      };

  Map<String, dynamic> _emptyDailySummary() => {
        'steps': null,
        'water_intake_ml': null,
        'active_energy_burned_kcal': null,
        'workout_duration_seconds': null,
      };

  void _recalculateUser(int userId) {
    final summary = _dailySummaryFor(userId);
    for (final assignment
        in _assignments.where((row) => row['user_id'] == userId)) {
      final challenge = _findChallenge(assignment['challenge_id'] as int);
      final target = (challenge['target_value'] as num?) ?? 0;
      final progress = switch (challenge['type']) {
        'health_metric' => _metricProgress(
            summary,
            challenge['metric_type']?.toString(),
          ),
        'workout' => (summary['workout_duration_seconds'] as num?) ?? 0,
        _ => 0,
      };
      assignment['progress'] = progress;
      if (target > 0 &&
          progress >= target &&
          assignment['status'] != 'completed') {
        assignment['status'] = 'completed';
        assignment['completed_at'] = DateTime.now().toUtc().toIso8601String();
        final user = _findUser(userId);
        user['points_balance'] =
            (user['points_balance'] as int) + (challenge['points'] as int);
        user['level'] = _levelFor(user['points_balance'] as int);
        _audit('challenge.completed');
      }
    }
  }

  num _metricProgress(Map<String, dynamic> summary, String? metricType) {
    return switch (metricType) {
      'steps' => (summary['steps'] as num?) ?? 0,
      'water_intake' => (summary['water_intake_ml'] as num?) ?? 0,
      'active_energy_burned' =>
        (summary['active_energy_burned_kcal'] as num?) ?? 0,
      _ => 0,
    };
  }

  int _nextId(Iterable<Map<String, dynamic>> rows) =>
      rows.isEmpty ? 1 : rows.map((row) => row['id'] as int).reduce(max) + 1;

  int _levelFor(int points) => points < 0 ? 1 : (points ~/ 500) + 1;

  void _audit(String action) {
    _audits.insert(0, {
      'id': _nextId(_audits),
      'action': action,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static int max(int a, int b) => a > b ? a : b;

  static Map<String, dynamic> _challenge(
    int id,
    String slug,
    String title,
    String description,
    String icon,
    String difficulty,
    String type, {
    String? metricType,
    String? activityType,
    required num target,
    required String unit,
    required int points,
    bool quick = false,
  }) =>
      {
        'id': id,
        'slug': slug,
        'title': title,
        'description': description,
        'icon_key': icon,
        'difficulty': difficulty,
        'type': type,
        'metric_type': metricType,
        'activity_type': activityType,
        'target_value': target,
        'min_workout_seconds': type == 'workout' ? target : null,
        'unit': unit,
        'points': points,
        'is_quick': quick,
        'active': true,
        'sort_order': id,
        'instructions': quick
            ? ['Start de activiteit', 'Blijf in beweging', 'Synchroniseer']
            : null,
      };

  static Map<String, dynamic> _shopItem(
    int id,
    String slug,
    String title,
    String icon,
    String category,
    int cost,
    String requirement,
  ) =>
      {
        'id': id,
        'slug': slug,
        'title': title,
        'description': requirement,
        'icon_key': icon,
        'category': category,
        'points_cost': cost,
        'requirement': requirement,
        'active': true,
        'sort_order': id,
      };
}
