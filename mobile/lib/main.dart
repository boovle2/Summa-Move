import 'package:flutter/material.dart';

import 'src/health/health_source_adapter.dart';
import 'src/health/method_channel_health_adapter.dart';
import 'src/health/mock_health_source_adapter.dart';
import 'src/models/health_models.dart';
import 'src/services/api_client.dart';
import 'src/services/health_sync_service.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

void main() {
  runApp(const SummaMoveApp());
}

class SummaMoveApp extends StatelessWidget {
  const SummaMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SummaMove',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff167d4d)),
        useMaterial3: true,
      ),
      home: const SyncPage(),
    );
  }
}

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final _email = TextEditingController(text: 'demo@example.com');
  final _password = TextEditingController(text: 'password123');
  final _api = ApiClient(baseUrl: apiBaseUrl);
  HealthSource _source = HealthSource.mock;
  bool _busy = false;
  String _status = 'Log in om handmatig te synchroniseren.';

  late final _sync = HealthSyncService(
    api: _api,
    deviceId: 'summamove-demo-device',
  );

  HealthSourceAdapter get _adapter => switch (_source) {
        HealthSource.mock => MockHealthSourceAdapter(),
        HealthSource.healthConnect => HealthConnectAdapter(),
        HealthSource.healthKit => HealthKitAdapter(),
        HealthSource.samsungHealth => SamsungHealthAdapter(),
      };

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Object?> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      setState(() => _status = result?.toString() ?? 'Klaar.');
    } catch (error) {
      setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SummaMove health-sync')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Wachtwoord'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await _api.login(
                        email: _email.text,
                        password: _password.text,
                        deviceName: 'summamove-flutter-demo',
                      );
                      return 'Ingelogd.';
                    }),
            child: const Text('Inloggen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await _api.register(
                        name: 'Demo User',
                        email: _email.text,
                        password: _password.text,
                        deviceName: 'summamove-flutter-demo',
                      );
                      return 'Account aangemaakt en ingelogd.';
                    }),
            child: const Text('Account aanmaken'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await _api.logout();
                      return 'Uitgelogd.';
                    }),
            child: const Text('Uitloggen'),
          ),
          const Divider(height: 32),
          DropdownButtonFormField<HealthSource>(
            initialValue: _source,
            decoration: const InputDecoration(labelText: 'Actieve health-bron'),
            items: HealthSource.values
                .map(
                  (source) => DropdownMenuItem(
                    value: source,
                    child: Text(source.label),
                  ),
                )
                .toList(),
            onChanged: _busy
                ? null
                : (source) => setState(() => _source = source ?? _source),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run(() => _sync.sync(_adapter)),
            icon: const Icon(Icons.sync),
            label: const Text('Handmatig synchroniseren'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() => _sync.dailySummary(date: DateTime.now())),
            icon: const Icon(Icons.today),
            label: const Text('Dagoverzicht ophalen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(_sync.status),
            icon: const Icon(Icons.info_outline),
            label: const Text('Syncstatus ophalen'),
          ),
          const SizedBox(height: 24),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          SelectableText(_status),
        ],
      ),
    );
  }
}
