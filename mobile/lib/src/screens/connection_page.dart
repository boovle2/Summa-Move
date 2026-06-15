import 'package:flutter/material.dart';

import '../health/health_source_adapter.dart';
import '../health/method_channel_health_adapter.dart';
import '../health/mock_health_source_adapter.dart';
import '../models/health_models.dart';
import '../services/api_client.dart';
import '../services/health_sync_service.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({
    required this.api,
    required this.sync,
    required this.onAuthenticated,
    required this.onLoggedOut,
    super.key,
  });

  final ApiClient api;
  final HealthSyncService sync;
  final ValueChanged<String> onAuthenticated;
  final VoidCallback onLoggedOut;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final _name = TextEditingController(text: 'Demo User');
  final _email = TextEditingController(text: 'demo@example.com');
  final _password = TextEditingController(text: 'password123');
  HealthSource _source = HealthSource.mock;
  bool _busy = false;
  String _status = 'Log in om handmatig te synchroniseren.';

  HealthSourceAdapter get _adapter => switch (_source) {
        HealthSource.mock => MockHealthSourceAdapter(),
        HealthSource.healthConnect => HealthConnectAdapter(),
        HealthSource.healthKit => HealthKitAdapter(),
        HealthSource.samsungHealth => SamsungHealthAdapter(),
      };

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Object?> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      if (mounted) setState(() => _status = result?.toString() ?? 'Klaar.');
    } catch (error) {
      if (mounted) setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync en account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Naam'),
          ),
          const SizedBox(height: 12),
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
                      final name = await widget.api.login(
                        email: _email.text,
                        password: _password.text,
                        deviceName: 'summamove-flutter-demo',
                      );
                      widget.onAuthenticated(name);
                      return 'Ingelogd.';
                    }),
            child: const Text('Inloggen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final name = await widget.api.register(
                        name: _name.text,
                        email: _email.text,
                        password: _password.text,
                        deviceName: 'summamove-flutter-demo',
                      );
                      widget.onAuthenticated(name);
                      return 'Account aangemaakt en ingelogd.';
                    }),
            child: const Text('Account aanmaken'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await widget.api.logout();
                      widget.onLoggedOut();
                      return 'Uitgelogd.';
                    }),
            child: const Text('Uitloggen'),
          ),
          const Divider(height: 32),
          DropdownButtonFormField<HealthSource>(
            initialValue: _source,
            decoration: const InputDecoration(labelText: 'Actieve health-bron'),
            items: HealthSource.values
                .map((source) =>
                    DropdownMenuItem(value: source, child: Text(source.label)))
                .toList(),
            onChanged: _busy
                ? null
                : (source) => setState(() => _source = source ?? _source),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed:
                _busy ? null : () => _run(() => widget.sync.sync(_adapter)),
            icon: const Icon(Icons.sync),
            label: const Text('Handmatig synchroniseren'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () =>
                    _run(() => widget.sync.dailySummary(date: DateTime.now())),
            icon: const Icon(Icons.today),
            label: const Text('Dagoverzicht ophalen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(widget.sync.status),
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
