import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../services/api_client.dart';
import '../services/offline_demo_repository.dart';
import '../services/product_repository.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8001/api/v1',
);

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(baseUrl: apiBaseUrl));
final offlineDemoRepositoryProvider =
    Provider<OfflineDemoRepository>((ref) => OfflineDemoRepository());
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final session = ref.watch(sessionProvider);
  if (session.offlineDemo) {
    final repository = ref.watch(offlineDemoRepositoryProvider);
    if (session.isAdmin) {
      repository.useDemoAdmin();
    } else {
      repository.useDemoUser();
    }
    return repository;
  }

  return ApiProductRepository(ref.read(apiClientProvider));
});
final themeModeProvider = ChangeNotifierProvider<ThemeModeController>(
  (ref) => ThemeModeController(),
);
final sessionProvider = ChangeNotifierProvider<SessionController>(
  (ref) => SessionController(
    ref.read(apiClientProvider),
    onAuthenticated: () async {
      final response = await ref.read(apiClientProvider).get('/me/settings');
      final settings = Map<String, dynamic>.from(response['data'] as Map);
      ref.read(themeModeProvider).apply(settings['theme']?.toString());
    },
  )..restore(),
);

class ThemeModeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;

  void apply(String? value) {
    final next = value == 'dark' ? ThemeMode.dark : ThemeMode.light;
    if (next == mode) {
      return;
    }
    mode = next;
    notifyListeners();
  }
}

class SessionController extends ChangeNotifier {
  SessionController(this.api, {this.onAuthenticated});

  final ApiClient api;
  final Future<void> Function()? onAuthenticated;
  bool initialized = false;
  bool authenticated = false;
  bool offlineDemo = false;
  String name = 'sportieveling';
  String role = 'user';

  bool get isAdmin => role == 'admin';
  bool get isOfflineDemo => offlineDemo;

  Future<void> restore() async {
    offlineDemo = false;
    authenticated = await api.isAuthenticated;
    name = await api.currentUserName ?? name;
    role = await api.currentUserRole ?? role;
    if (authenticated) {
      await _loadAuthenticatedState();
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    offlineDemo = false;
    name = await api.login(
        email: email, password: password, deviceName: 'summamove-flutter');
    role = await api.currentUserRole ?? 'user';
    authenticated = true;
    initialized = true;
    await _loadAuthenticatedState();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    offlineDemo = false;
    this.name = await api.register(
        name: name,
        email: email,
        password: password,
        deviceName: 'summamove-flutter');
    role = await api.currentUserRole ?? 'user';
    authenticated = true;
    initialized = true;
    await _loadAuthenticatedState();
    notifyListeners();
  }

  Future<void> loginOfflineUser() async {
    await api.clearLocalSession();
    name = 'Demo User';
    role = 'user';
    authenticated = true;
    initialized = true;
    offlineDemo = true;
    notifyListeners();
  }

  Future<void> loginOfflineAdmin() async {
    await api.clearLocalSession();
    name = 'SummaMove Admin';
    role = 'admin';
    authenticated = true;
    initialized = true;
    offlineDemo = true;
    notifyListeners();
  }

  Future<void> logout() async {
    if (offlineDemo) {
      await api.clearLocalSession();
    } else {
      await api.logout();
    }
    authenticated = false;
    offlineDemo = false;
    name = 'sportieveling';
    role = 'user';
    notifyListeners();
  }

  Future<void> _loadAuthenticatedState() async {
    try {
      await onAuthenticated?.call();
    } catch (_) {
      // Session restore must still succeed when optional settings fail to load.
    }
  }
}
