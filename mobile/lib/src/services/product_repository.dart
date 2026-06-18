import 'api_client.dart';

abstract class ProductRepository {
  Future<Map<String, dynamic>> home();
  Future<Map<String, dynamic>> profile();
  Future<Map<String, dynamic>> settings();
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body);
  Future<List<dynamic>> challenges();
  Future<Map<String, dynamic>> challenge(int id);
  Future<void> startChallenge(int id);
  Future<List<dynamic>> friends();
  Future<List<dynamic>> friendRequests();
  Future<List<dynamic>> teams();
  Future<void> acceptFriendRequest(int id);
  Future<void> declineFriendRequest(int id);
  Future<void> challengeFriend(int id);
  Future<Map<String, dynamic>> messages(int id);
  Future<void> sendMessage(int id, String body);
  Future<Map<String, dynamic>> shop();
  Future<Map<String, dynamic>> purchase(int id);
  Future<void> equip(int id);
  Future<Map<String, dynamic>> rankings(String period);
  Future<Map<String, dynamic>> adminDashboard();
  Future<List<dynamic>> adminUsers();
  Future<List<dynamic>> adminChallenges();
  Future<List<dynamic>> adminShopItems();
  Future<List<dynamic>> adminTeams();
  Future<List<dynamic>> adminAudits();
  Future<void> adminCreateChallenge(Map<String, dynamic> body);
  Future<void> adminUpdateChallenge(int id, Map<String, dynamic> body);
  Future<void> adminDeleteChallenge(int id);
  Future<void> adminCreateShopItem(Map<String, dynamic> body);
  Future<void> adminUpdateShopItem(int id, Map<String, dynamic> body);
  Future<void> adminDeleteShopItem(int id);
  Future<void> adminCreateTeam(Map<String, dynamic> body);
  Future<void> adminUpdateTeam(int id, Map<String, dynamic> body);
  Future<void> adminDeleteTeam(int id);
  Future<void> adminAssign(int userId, int challengeId);
  Future<void> adminAdjustPoints(int userId, int amount, String reason);
  Future<void> adminDemoHealth(Map<String, dynamic> body);
}

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this.api);

  final ApiClient api;

  @override
  Future<Map<String, dynamic>> home() => _dataMap('/me/home');

  @override
  Future<Map<String, dynamic>> profile() => _dataMap('/me/profile');

  @override
  Future<Map<String, dynamic>> settings() => _dataMap('/me/settings');

  @override
  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> body,
  ) async =>
      Map<String, dynamic>.from(
        (await api.put('/me/settings', body))['data'] as Map,
      );

  @override
  Future<List<dynamic>> challenges() => _dataList('/challenges');

  @override
  Future<Map<String, dynamic>> challenge(int id) => _dataMap('/challenges/$id');

  @override
  Future<void> startChallenge(int id) => api.post('/challenges/$id/start', {});

  @override
  Future<List<dynamic>> friends() => _dataList('/friends');

  @override
  Future<List<dynamic>> friendRequests() => _dataList('/friend-requests');

  @override
  Future<List<dynamic>> teams() => _dataList('/teams');

  @override
  Future<void> acceptFriendRequest(int id) =>
      api.post('/friend-requests/$id/accept', {});

  @override
  Future<void> declineFriendRequest(int id) =>
      api.post('/friend-requests/$id/decline', {});

  @override
  Future<void> challengeFriend(int id) =>
      api.post('/friends/$id/challenge', {});

  @override
  Future<Map<String, dynamic>> messages(int id) => _dataMap('/messages/$id');

  @override
  Future<void> sendMessage(int id, String body) =>
      api.post('/messages/$id', {'body': body});

  @override
  Future<Map<String, dynamic>> shop() => _dataMap('/shop/items');

  @override
  Future<Map<String, dynamic>> purchase(int id) async =>
      Map<String, dynamic>.from(
        (await api.post('/shop/items/$id/purchase', {}))['data'] as Map,
      );

  @override
  Future<void> equip(int id) => api.put('/characters/$id/equip', {});

  @override
  Future<Map<String, dynamic>> rankings(String period) =>
      _dataMap('/rankings?period=$period');

  @override
  Future<Map<String, dynamic>> adminDashboard() => _dataMap('/admin/dashboard');

  @override
  Future<List<dynamic>> adminUsers() => _dataList('/admin/users');

  @override
  Future<List<dynamic>> adminChallenges() => _dataList('/admin/challenges');

  @override
  Future<List<dynamic>> adminShopItems() => _dataList('/admin/shop-items');

  @override
  Future<List<dynamic>> adminTeams() => _dataList('/admin/teams');

  @override
  Future<List<dynamic>> adminAudits() => _dataList('/admin/audits');

  @override
  Future<void> adminCreateChallenge(Map<String, dynamic> body) =>
      api.post('/admin/challenges', body);

  @override
  Future<void> adminUpdateChallenge(int id, Map<String, dynamic> body) =>
      api.put('/admin/challenges/$id', body);

  @override
  Future<void> adminDeleteChallenge(int id) =>
      api.delete('/admin/challenges/$id');

  @override
  Future<void> adminCreateShopItem(Map<String, dynamic> body) =>
      api.post('/admin/shop-items', body);

  @override
  Future<void> adminUpdateShopItem(int id, Map<String, dynamic> body) =>
      api.put('/admin/shop-items/$id', body);

  @override
  Future<void> adminDeleteShopItem(int id) =>
      api.delete('/admin/shop-items/$id');

  @override
  Future<void> adminCreateTeam(Map<String, dynamic> body) =>
      api.post('/admin/teams', body);

  @override
  Future<void> adminUpdateTeam(int id, Map<String, dynamic> body) =>
      api.put('/admin/teams/$id', body);

  @override
  Future<void> adminDeleteTeam(int id) => api.delete('/admin/teams/$id');

  @override
  Future<void> adminAssign(int userId, int challengeId) => api.post(
        '/admin/assignments',
        {'user_id': userId, 'challenge_id': challengeId},
      );

  @override
  Future<void> adminAdjustPoints(int userId, int amount, String reason) =>
      api.post('/admin/point-adjustments', {
        'user_id': userId,
        'amount': amount,
        'reason': reason,
      });

  @override
  Future<void> adminDemoHealth(Map<String, dynamic> body) =>
      api.post('/admin/demo-health', body);

  Future<Map<String, dynamic>> _dataMap(String path) async =>
      Map<String, dynamic>.from((await api.get(path))['data'] as Map);

  Future<List<dynamic>> _dataList(String path) async =>
      List<dynamic>.from((await api.get(path))['data'] as List);
}
