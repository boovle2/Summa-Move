import 'api_client.dart';

class ProductRepository {
  ProductRepository(this.api);

  final ApiClient api;

  Future<Map<String, dynamic>> home() => _dataMap('/me/home');
  Future<Map<String, dynamic>> profile() => _dataMap('/me/profile');
  Future<Map<String, dynamic>> settings() => _dataMap('/me/settings');
  Future<Map<String, dynamic>> updateSettings(
          Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(
          (await api.put('/me/settings', body))['data'] as Map);
  Future<List<dynamic>> challenges() => _dataList('/challenges');
  Future<Map<String, dynamic>> challenge(int id) => _dataMap('/challenges/$id');
  Future<void> startChallenge(int id) => api.post('/challenges/$id/start', {});
  Future<List<dynamic>> friends() => _dataList('/friends');
  Future<List<dynamic>> friendRequests() => _dataList('/friend-requests');
  Future<List<dynamic>> teams() => _dataList('/teams');
  Future<void> acceptFriendRequest(int id) =>
      api.post('/friend-requests/$id/accept', {});
  Future<void> declineFriendRequest(int id) =>
      api.post('/friend-requests/$id/decline', {});
  Future<void> challengeFriend(int id) =>
      api.post('/friends/$id/challenge', {});
  Future<Map<String, dynamic>> messages(int id) => _dataMap('/messages/$id');
  Future<void> sendMessage(int id, String body) =>
      api.post('/messages/$id', {'body': body});
  Future<Map<String, dynamic>> shop() => _dataMap('/shop/items');
  Future<Map<String, dynamic>> purchase(int id) async =>
      Map<String, dynamic>.from(
          (await api.post('/shop/items/$id/purchase', {}))['data'] as Map);
  Future<void> equip(int id) => api.put('/characters/$id/equip', {});
  Future<Map<String, dynamic>> rankings(String period) =>
      _dataMap('/rankings?period=$period');

  Future<Map<String, dynamic>> adminDashboard() => _dataMap('/admin/dashboard');
  Future<List<dynamic>> adminUsers() => _dataList('/admin/users');
  Future<List<dynamic>> adminChallenges() => _dataList('/admin/challenges');
  Future<List<dynamic>> adminShopItems() => _dataList('/admin/shop-items');
  Future<List<dynamic>> adminTeams() => _dataList('/admin/teams');
  Future<List<dynamic>> adminAudits() => _dataList('/admin/audits');
  Future<void> adminCreateChallenge(Map<String, dynamic> body) =>
      api.post('/admin/challenges', body);
  Future<void> adminUpdateChallenge(int id, Map<String, dynamic> body) =>
      api.put('/admin/challenges/$id', body);
  Future<void> adminDeleteChallenge(int id) =>
      api.delete('/admin/challenges/$id');
  Future<void> adminCreateShopItem(Map<String, dynamic> body) =>
      api.post('/admin/shop-items', body);
  Future<void> adminUpdateShopItem(int id, Map<String, dynamic> body) =>
      api.put('/admin/shop-items/$id', body);
  Future<void> adminDeleteShopItem(int id) =>
      api.delete('/admin/shop-items/$id');
  Future<void> adminCreateTeam(Map<String, dynamic> body) =>
      api.post('/admin/teams', body);
  Future<void> adminUpdateTeam(int id, Map<String, dynamic> body) =>
      api.put('/admin/teams/$id', body);
  Future<void> adminDeleteTeam(int id) => api.delete('/admin/teams/$id');
  Future<void> adminAssign(int userId, int challengeId) => api.post(
      '/admin/assignments', {'user_id': userId, 'challenge_id': challengeId});
  Future<void> adminAdjustPoints(int userId, int amount, String reason) =>
      api.post('/admin/point-adjustments',
          {'user_id': userId, 'amount': amount, 'reason': reason});
  Future<void> adminDemoHealth(Map<String, dynamic> body) =>
      api.post('/admin/demo-health', body);

  Future<Map<String, dynamic>> _dataMap(String path) async =>
      Map<String, dynamic>.from((await api.get(path))['data'] as Map);
  Future<List<dynamic>> _dataList(String path) async =>
      List<dynamic>.from((await api.get(path))['data'] as List);
}
