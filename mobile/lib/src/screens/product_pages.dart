import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/app_state.dart';
import '../widgets/app_widgets.dart';

class ChallengesPage extends ConsumerStatefulWidget {
  const ChallengesPage({super.key});

  @override
  ConsumerState<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends ConsumerState<ChallengesPage> {
  late Future<List<dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = ref.read(productRepositoryProvider).challenges();
  }

  void reload() =>
      setState(() => future = ref.read(productRepositoryProvider).challenges());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AsyncPage<List<dynamic>>(
        future: future,
        onRetry: reload,
        builder: (context, rows) => RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const PageTitle('Challenges'),
              const SizedBox(height: 14),
              ...rows.where((row) => row['is_quick'] != true).map((row) =>
                  _ChallengeCard(row: Map<String, dynamic>.from(row as Map))),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickChallengesPage extends ConsumerWidget {
  const QuickChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('5 Min Challenges')),
      body: AsyncPage<List<dynamic>>(
        future: ref.read(productRepositoryProvider).challenges(),
        builder: (context, rows) => ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 54, color: Color(0xFFE91E63)),
                  SizedBox(width: 16),
                  Expanded(
                      child: Text('Snelle workouts voor tussen de lessen door.',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...rows.where((row) => row['is_quick'] == true).map((row) =>
                _ChallengeCard(row: Map<String, dynamic>.from(row as Map))),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final assignment = row['assignment'] as Map?;
    final completed = assignment?['status'] == 'completed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => context.push('/challenge/${row['id']}'),
        child: Row(
          children: [
            Icon(iconFor(row['icon_key']?.toString()),
                size: 44,
                color: completed ? Colors.green : const Color(0xFF2E258F)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row['title'].toString(),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(row['description'].toString(),
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text('${row['difficulty']} • ${row['points']} punten'),
                ],
              ),
            ),
            Icon(completed ? Icons.check_circle : Icons.chevron_right,
                color: completed ? Colors.green : null),
          ],
        ),
      ),
    );
  }
}

class ChallengeDetailPage extends ConsumerStatefulWidget {
  const ChallengeDetailPage({required this.id, super.key});

  final int id;

  @override
  ConsumerState<ChallengeDetailPage> createState() =>
      _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends ConsumerState<ChallengeDetailPage> {
  late Future<Map<String, dynamic>> future;
  Timer? timer;
  int seconds = 300;

  @override
  void initState() {
    super.initState();
    future = ref.read(productRepositoryProvider).challenge(widget.id);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> start(Map<String, dynamic> challenge) async {
    await ref.read(productRepositoryProvider).startChallenge(widget.id);
    if (challenge['is_quick'] == true) {
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || seconds <= 0) {
          timer.cancel();
          return;
        }
        setState(() => seconds--);
      });
    }
    setState(() =>
        future = ref.read(productRepositoryProvider).challenge(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenge')),
      body: AsyncPage<Map<String, dynamic>>(
        future: future,
        builder: (context, row) {
          final assignment = row['assignment'] as Map?;
          final target = (row['target_value'] as num).toDouble();
          final progress = ((assignment?['progress'] as num?) ?? 0).toDouble();
          final fraction =
              target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
          return ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Icon(iconFor(row['icon_key']?.toString()),
                  size: 94, color: const Color(0xFFE91E63)),
              const SizedBox(height: 16),
              Text(row['title'].toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(row['description'].toString(), textAlign: TextAlign.center),
              const SizedBox(height: 22),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('Voortgang',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text('${(fraction * 100).round()}%')
                    ]),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: fraction),
                    const SizedBox(height: 10),
                    Text(
                        '${progress.round()} van ${target.round()} ${row['unit'] ?? ''}'),
                    if (row['is_quick'] == true)
                      Text(
                          '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')} resterend'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: assignment?['status'] == 'completed'
                    ? null
                    : () => start(row),
                icon: const Icon(Icons.play_arrow),
                label: Text(assignment == null
                    ? 'Start challenge'
                    : 'Synchroniseer voortgang'),
              ),
              const SizedBox(height: 12),
              const Text(
                  'Voortgang wordt uitsluitend bevestigd via health-data of een passende workout.',
                  textAlign: TextAlign.center),
            ],
          );
        },
      ),
    );
  }
}

class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  late Future<List<dynamic>> friends;
  late Future<List<dynamic>> requests;
  late Future<List<dynamic>> teams;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    final repo = ref.read(productRepositoryProvider);
    friends = repo.friends();
    requests = repo.friendRequests();
    teams = repo.teams();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const Padding(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: PageTitle('Vrienden')),
            const TabBar(tabs: [
              Tab(text: 'Vrienden'),
              Tab(text: 'Teams'),
              Tab(text: 'Verzoeken')
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  AsyncPage<List<dynamic>>(
                    future: friends,
                    builder: (context, rows) => ListView(
                        padding: const EdgeInsets.all(16),
                        children: rows
                            .map((row) => _friendCard(
                                Map<String, dynamic>.from(row as Map)))
                            .toList()),
                  ),
                  AsyncPage<List<dynamic>>(
                    future: teams,
                    builder: (context, rows) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: rows
                          .map((row) => AppCard(
                              child: ListTile(
                                  leading: const Icon(Icons.groups),
                                  title: Text(row['name'].toString()),
                                  subtitle: Text(
                                      '${row['users_count']} leden • ${row['points']} punten'))))
                          .toList(),
                    ),
                  ),
                  AsyncPage<List<dynamic>>(
                    future: requests,
                    builder: (context, rows) => ListView(
                        padding: const EdgeInsets.all(16),
                        children: rows
                            .map((row) => _requestCard(
                                Map<String, dynamic>.from(row as Map)))
                            .toList()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _friendCard(Map<String, dynamic> row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                  child:
                      Icon(iconFor(row['active_character_key']?.toString()))),
              title: Text(row['name'].toString()),
              subtitle: Text('${row['points_balance']} punten'),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(productRepositoryProvider)
                          .challengeFriend(row['id'] as int);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Challenge verstuurd.')));
                      }
                    },
                    child: const Text('Uitdagen'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: FilledButton(
                        onPressed: () => context.push('/messages/${row['id']}'),
                        child: const Text('Bericht'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> row) {
    final user = Map<String, dynamic>.from(row['user'] as Map);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
          title: Text(user['name'].toString()),
          subtitle: Text('${user['points_balance']} punten'),
          trailing: Wrap(
            children: [
              IconButton(
                tooltip: 'Accepteren',
                onPressed: () async {
                  await ref
                      .read(productRepositoryProvider)
                      .acceptFriendRequest(row['id'] as int);
                  setState(reload);
                },
                icon: const Icon(Icons.check, color: Colors.green),
              ),
              IconButton(
                tooltip: 'Weigeren',
                onPressed: () async {
                  await ref
                      .read(productRepositoryProvider)
                      .declineFriendRequest(row['id'] as int);
                  setState(reload);
                },
                icon: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({required this.friendId, super.key});

  final int friendId;

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final controller = TextEditingController();
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() =>
      future = ref.read(productRepositoryProvider).messages(widget.friendId);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Berichten')),
      body: Column(
        children: [
          Expanded(
            child: AsyncPage<Map<String, dynamic>>(
              future: future,
              builder: (context, data) => ListView(
                padding: const EdgeInsets.all(16),
                children: (data['messages'] as List)
                    .map((message) => Align(
                          alignment: message['sender_id'] == widget.friendId
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(message['body'].toString()))),
                        ))
                    .toList(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                              hintText: 'Schrijf een bericht',
                              border: OutlineInputBorder()))),
                  IconButton.filled(
                    tooltip: 'Versturen',
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) {
                        return;
                      }
                      await ref
                          .read(productRepositoryProvider)
                          .sendMessage(widget.friendId, controller.text.trim());
                      controller.clear();
                      setState(reload);
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  late Future<Map<String, dynamic>> future;
  String category = 'free';

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() => future = ref.read(productRepositoryProvider).shop();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AsyncPage<Map<String, dynamic>>(
        future: future,
        builder: (context, data) {
          final items = (data['items'] as List)
              .where((item) => item['category'] == category)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              PageTitle('Character Shop',
                  trailing: Chip(
                      avatar: const Icon(Icons.stars),
                      label: Text('${data['points_balance']}'))),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'free', label: Text('Gratis')),
                    ButtonSegment(value: 'sport', label: Text('Sport')),
                    ButtonSegment(value: 'team', label: Text('Team')),
                    ButtonSegment(value: 'allround', label: Text('All-round')),
                    ButtonSegment(value: 'top', label: Text('Top')),
                  ],
                  selected: {category},
                  onSelectionChanged: (value) =>
                      setState(() => category = value.first),
                ),
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      onTap: item['owned'] == true || item['points_cost'] == 0
                          ? () async {
                              await ref
                                  .read(productRepositoryProvider)
                                  .equip(item['id'] as int);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Character ingesteld.')));
                              }
                            }
                          : () async {
                              await ref
                                  .read(productRepositoryProvider)
                                  .purchase(item['id'] as int);
                              setState(reload);
                            },
                      child: ListTile(
                        leading: CircleAvatar(
                            child: Icon(iconFor(item['icon_key']?.toString()))),
                        title: Text(item['title'].toString()),
                        subtitle: Text(item['requirement']?.toString() ?? ''),
                        trailing: Text(item['owned'] == true
                            ? 'In bezit'
                            : item['points_cost'] == 0
                                ? 'Gratis'
                                : '${item['points_cost']} pts'),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class RankingsPage extends ConsumerStatefulWidget {
  const RankingsPage({super.key});

  @override
  ConsumerState<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends ConsumerState<RankingsPage> {
  String period = 'today';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: PageTitle('Leaderboard')),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'today', label: Text('Vandaag')),
                ButtonSegment(value: 'week', label: Text('Week')),
                ButtonSegment(value: 'progress', label: Text('Vooruitgang')),
                ButtonSegment(value: 'friends', label: Text('Vrienden')),
              ],
              selected: {period},
              onSelectionChanged: (value) =>
                  setState(() => period = value.first),
            ),
          ),
          Expanded(
            child: AsyncPage<Map<String, dynamic>>(
              key: ValueKey(period),
              future: ref.read(productRepositoryProvider).rankings(period),
              builder: (context, data) => ListView(
                padding: const EdgeInsets.all(16),
                children: (data['rankings'] as List)
                    .map((row) => AppCard(
                          child: ListTile(
                            leading:
                                CircleAvatar(child: Text('#${row['rank']}')),
                            title: Text(row['name'].toString()),
                            subtitle: Text(period == 'friends'
                                ? '${(row['value'] as num).round()} punten'
                                : '${(row['value'] as num).round()} ${period == 'progress' ? '% verbetering' : 'stappen'}'),
                            trailing: Icon(iconFor(
                                row['active_character_key']?.toString())),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AvatarPage extends ConsumerStatefulWidget {
  const AvatarPage({super.key});

  @override
  ConsumerState<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends ConsumerState<AvatarPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = ref.read(productRepositoryProvider).shop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mijn Characters')),
      body: AsyncPage<Map<String, dynamic>>(
        future: future,
        builder: (context, data) {
          final owned = (data['items'] as List)
              .where(
                  (item) => item['owned'] == true || item['points_cost'] == 0)
              .toList();
          final locked = (data['items'] as List)
              .where(
                  (item) => item['owned'] != true && item['points_cost'] != 0)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Icon(iconFor(data['active_character_key']?.toString()),
                  size: 110, color: const Color(0xFFE91E63)),
              const Center(child: Text('Huidige avatar')),
              const SizedBox(height: 18),
              const Text('Mijn Characters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 10,
                children: owned
                    .map((item) => IconButton.filledTonal(
                          tooltip: item['title'].toString(),
                          onPressed: () async {
                            await ref
                                .read(productRepositoryProvider)
                                .equip(item['id'] as int);
                            setState(() => future =
                                ref.read(productRepositoryProvider).shop());
                          },
                          icon: Icon(iconFor(item['icon_key']?.toString())),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              const Text('Vergrendeld',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Wrap(
                  spacing: 10,
                  children: locked
                      .map((item) => IconButton(
                          onPressed: null,
                          icon: Icon(iconFor(item['icon_key']?.toString()))))
                      .toList()),
              FilledButton.icon(
                  onPressed: () => context.go('/app'),
                  icon: const Icon(Icons.save),
                  label: const Text('Opslaan')),
            ],
          );
        },
      ),
    );
  }
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sportpaspoort')),
      body: AsyncPage<Map<String, dynamic>>(
        future: ref.read(productRepositoryProvider).profile(),
        builder: (context, data) {
          final user = Map<String, dynamic>.from(data['user'] as Map);
          final stats = Map<String, dynamic>.from(data['stats'] as Map);
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Icon(iconFor(user['active_character_key']?.toString()),
                  size: 100, color: const Color(0xFFE91E63)),
              Center(
                  child: Text(user['name'].toString(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold))),
              Center(
                  child: Text(
                      'Level ${user['level']} • ${user['profile_status']}')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          value: '${user['points_balance']}',
                          label: 'Totaal punten')),
                  Expanded(
                      child: _StatCard(
                          value: '${stats['completed_challenges']}',
                          label: 'Voltooid')),
                  Expanded(
                      child: _StatCard(
                          value: '${user['streak_days']}',
                          label: 'Dag streak')),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Deze week',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                        'Stappen: ${(stats['weekly_steps'] as num).round()} / 70.000'),
                    Text(
                        'Actieve minuten: ${stats['weekly_active_minutes']} / 150'),
                  ])),
              const SizedBox(height: 16),
              const Text('Prestaties',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...((data['achievements'] as List).map((achievement) => ListTile(
                    leading: Icon(iconFor(achievement['icon_key']?.toString())),
                    title: Text(achievement['title'].toString()),
                    trailing: Icon(
                        achievement['earned_at'] == null
                            ? Icons.lock_outline
                            : Icons.check_circle,
                        color: achievement['earned_at'] == null
                            ? null
                            : Colors.green),
                  ))),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Text(label,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))
      ]),
    );
  }
}

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final admin = session.isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (session.isOfflineDemo)
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Lokale demo'),
              subtitle: Text('Data staat alleen op dit toestel'),
            ),
          ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Sportpaspoort'),
              onTap: () => context.push('/profile')),
          ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mijn Characters'),
              onTap: () => context.push('/avatar')),
          ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Instellingen'),
              onTap: () => context.push('/settings')),
          ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Health-sync'),
              onTap: () => context.push('/health-sync')),
          if (admin)
            ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin'),
                onTap: () => context.push('/admin')),
        ],
      ),
    );
  }
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = ref.read(productRepositoryProvider).settings();
  }

  Future<void> update(String key, Object value) async {
    final updated =
        await ref.read(productRepositoryProvider).updateSettings({key: value});
    setState(() => future = Future.value(updated));
    if (key == 'theme') {
      ref.read(themeModeProvider).apply(value.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instellingen')),
      body: AsyncPage<Map<String, dynamic>>(
        future: future,
        builder: (context, settings) => ListView(
          children: [
            if (ref.watch(sessionProvider).isOfflineDemo)
              const ListTile(
                leading: Icon(Icons.privacy_tip_outlined),
                title: Text('Lokale demo'),
                subtitle: Text('Wijzigingen resetten bij app-herstart'),
              ),
            SwitchListTile(
                value: settings['notifications'] == true,
                onChanged: (value) => update('notifications', value),
                title: const Text('Notificaties'),
                secondary: const Icon(Icons.notifications_outlined)),
            SwitchListTile(
                value: settings['sound'] == true,
                onChanged: (value) => update('sound', value),
                title: const Text('Geluid'),
                secondary: const Icon(Icons.volume_up_outlined)),
            ListTile(
                leading: const Icon(Icons.contrast),
                title: const Text('Thema'),
                subtitle: Text(settings['theme'].toString()),
                onTap: () => update(
                    'theme', settings['theme'] == 'dark' ? 'light' : 'dark')),
            const ListTile(
                leading: Icon(Icons.language),
                title: Text('Taal'),
                subtitle: Text('Nederlands')),
            ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy'),
                onTap: () => context.push('/privacy')),
            ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () => context.push('/help')),
            ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Uitloggen'),
                onTap: () => ref.read(sessionProvider).logout()),
          ],
        ),
      ),
    );
  }
}

class InfoPage extends StatelessWidget {
  const InfoPage({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(body, style: Theme.of(context).textTheme.bodyLarge)));
  }
}

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  late Future<List<dynamic>> users;
  late Future<List<dynamic>> challenges;
  late Future<List<dynamic>> shopItems;
  late Future<List<dynamic>> teams;
  late Future<List<dynamic>> audits;
  late Future<Map<String, dynamic>> dashboard;

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    final repo = ref.read(productRepositoryProvider);
    users = repo.adminUsers();
    challenges = repo.adminChallenges();
    shopItems = repo.adminShopItems();
    teams = repo.adminTeams();
    audits = repo.adminAudits();
    dashboard = repo.adminDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SummaMove Admin')),
      body: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Dashboard'),
                Tab(text: 'Gebruikers'),
                Tab(text: 'Challenges'),
                Tab(text: 'Shop'),
                Tab(text: 'Teams'),
                Tab(text: 'Demodata'),
                Tab(text: 'Audit'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  AsyncPage<Map<String, dynamic>>(
                    future: dashboard,
                    builder: (context, data) => GridView.count(
                      padding: const EdgeInsets.all(18),
                      crossAxisCount: 2,
                      children: data.entries
                          .map((entry) => _StatCard(
                              value: entry.value.toString(),
                              label: entry.key.replaceAll('_', ' ')))
                          .toList(),
                    ),
                  ),
                  AsyncPage<List<dynamic>>(
                    future: users,
                    builder: (context, rows) => ListView(
                      padding: const EdgeInsets.all(12),
                      children: rows
                          .map((user) => AppCard(
                                child: ListTile(
                                  title: Text(user['name'].toString()),
                                  subtitle: Text(
                                      '${user['email']} • ${user['points_balance']} punten'),
                                  trailing: IconButton(
                                    tooltip: 'Punten toevoegen',
                                    onPressed: () =>
                                        _pointsDialog(user['id'] as int),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  AsyncPage<List<dynamic>>(
                    future: challenges,
                    builder: (context, rows) =>
                        ListView(padding: const EdgeInsets.all(12), children: [
                      FilledButton.icon(
                          onPressed: _createChallengeDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Challenge maken')),
                      const SizedBox(height: 8),
                      ...rows.map((challenge) => AppCard(
                            child: ListTile(
                              leading: Icon(
                                  iconFor(challenge['icon_key']?.toString())),
                              title: Text(challenge['title'].toString()),
                              subtitle: Text(
                                  '${challenge['type']} • ${challenge['points']} punten'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Toekennen',
                                    onPressed: () =>
                                        _assignDialog(challenge['id'] as int),
                                    icon: const Icon(Icons.person_add_alt_1),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Challenge beheren',
                                    onSelected: (action) async {
                                      if (action == 'edit') {
                                        await _createChallengeDialog(challenge);
                                      } else if (await _confirmDelete(
                                          'Challenge deactiveren?')) {
                                        await ref
                                            .read(productRepositoryProvider)
                                            .adminDeleteChallenge(
                                                challenge['id'] as int);
                                        setState(reload);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Wijzigen')),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Deactiveren')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ]),
                  ),
                  _adminContentList(
                    future: shopItems,
                    createLabel: 'Shopitem maken',
                    onCreate: _createShopDialog,
                    onEdit: _createShopDialog,
                    onDelete: (row) => ref
                        .read(productRepositoryProvider)
                        .adminDeleteShopItem(row['id'] as int),
                    icon: Icons.shopping_bag_outlined,
                  ),
                  _adminContentList(
                    future: teams,
                    createLabel: 'Team maken',
                    onCreate: _createTeamDialog,
                    onEdit: _createTeamDialog,
                    onDelete: (row) => ref
                        .read(productRepositoryProvider)
                        .adminDeleteTeam(row['id'] as int),
                    icon: Icons.groups_outlined,
                  ),
                  _demoHealthForm(),
                  AsyncPage<List<dynamic>>(
                    future: audits,
                    builder: (context, rows) => ListView(
                      padding: const EdgeInsets.all(12),
                      children: rows
                          .map((audit) => ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(audit['action'].toString()),
                                subtitle: Text(audit['created_at'].toString()),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminContentList({
    required Future<List<dynamic>> future,
    required String createLabel,
    required VoidCallback onCreate,
    required Future<void> Function(Map<String, dynamic> row) onEdit,
    required Future<void> Function(Map<String, dynamic> row) onDelete,
    required IconData icon,
  }) {
    return AsyncPage<List<dynamic>>(
      future: future,
      builder: (context, rows) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(createLabel)),
          const SizedBox(height: 8),
          ...rows.map((raw) {
            final row = Map<String, dynamic>.from(raw as Map);
            return AppCard(
              child: ListTile(
                leading: Icon(icon),
                title: Text((row['title'] ?? row['name']).toString()),
                subtitle: Text(
                    (row['category'] ?? row['description'] ?? '').toString()),
                trailing: PopupMenuButton<String>(
                  tooltip: 'Beheren',
                  onSelected: (action) async {
                    if (action == 'edit') {
                      await onEdit(row);
                    } else if (await _confirmDelete('Item verwijderen?')) {
                      await onDelete(row);
                      setState(reload);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Wijzigen')),
                    PopupMenuItem(value: 'delete', child: Text('Verwijderen')),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _createChallengeDialog([Map<String, dynamic>? existing]) async {
    final title = TextEditingController(text: existing?['title']?.toString());
    final description =
        TextEditingController(text: existing?['description']?.toString());
    final target = TextEditingController(
        text: existing?['target_value']?.toString() ?? '1000');
    final points =
        TextEditingController(text: existing?['points']?.toString() ?? '100');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text(existing == null ? 'Challenge maken' : 'Challenge wijzigen'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Titel')),
            TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Beschrijving')),
            TextField(
                controller: target,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Doelstappen')),
            TextField(
                controller: points,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Punten')),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuleren')),
          FilledButton(
            onPressed: () async {
              final body = <String, dynamic>{
                'slug': existing?['slug'] ??
                    '${title.text.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
                'title': title.text,
                'description': description.text,
                'icon_key': existing?['icon_key'] ?? 'walk',
                'difficulty': existing?['difficulty'] ?? 'Beginner',
                'type': existing?['type'] ?? 'health_metric',
                'metric_type': existing?['metric_type'] ?? 'steps',
                'target_value': num.parse(target.text),
                'unit': existing?['unit'] ?? 'count',
                'points': int.parse(points.text),
              };
              final repo = ref.read(productRepositoryProvider);
              if (existing == null) {
                await repo.adminCreateChallenge(body);
              } else {
                await repo.adminUpdateChallenge(existing['id'] as int, body);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              setState(reload);
            },
            child: Text(existing == null ? 'Maken' : 'Opslaan'),
          ),
        ],
      ),
    );
    title.dispose();
    description.dispose();
    target.dispose();
    points.dispose();
  }

  Future<void> _createShopDialog([Map<String, dynamic>? existing]) async {
    final title = TextEditingController(text: existing?['title']?.toString());
    final cost = TextEditingController(
        text: existing?['points_cost']?.toString() ?? '100');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Shopitem maken' : 'Shopitem wijzigen'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Titel')),
          TextField(
              controller: cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Puntenprijs')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuleren')),
          FilledButton(
            onPressed: () async {
              final body = <String, dynamic>{
                'slug': existing?['slug'] ??
                    '${title.text.toLowerCase().replaceAll(' ', '-')}-${DateTime.now().millisecondsSinceEpoch}',
                'title': title.text,
                'icon_key': existing?['icon_key'] ?? 'star',
                'category': existing?['category'] ?? 'top',
                'points_cost': int.parse(cost.text),
              };
              final repo = ref.read(productRepositoryProvider);
              if (existing == null) {
                await repo.adminCreateShopItem(body);
              } else {
                await repo.adminUpdateShopItem(existing['id'] as int, body);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              setState(reload);
            },
            child: Text(existing == null ? 'Maken' : 'Opslaan'),
          ),
        ],
      ),
    );
    title.dispose();
    cost.dispose();
  }

  Future<void> _createTeamDialog([Map<String, dynamic>? existing]) async {
    final name = TextEditingController(text: existing?['name']?.toString());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Team maken' : 'Team wijzigen'),
        content: TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Naam')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuleren')),
          FilledButton(
            onPressed: () async {
              final body = <String, dynamic>{
                'name': name.text,
                'description':
                    existing?['description'] ?? 'Aangemaakt via Flutter-admin'
              };
              final repo = ref.read(productRepositoryProvider);
              if (existing == null) {
                await repo.adminCreateTeam(body);
              } else {
                await repo.adminUpdateTeam(existing['id'] as int, body);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              setState(reload);
            },
            child: Text(existing == null ? 'Maken' : 'Opslaan'),
          ),
        ],
      ),
    );
    name.dispose();
  }

  Future<bool> _confirmDelete(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: const Text('Deze actie wordt direct opgeslagen.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuleren')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Bevestigen')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _assignDialog(int challengeId) async {
    final rows = await users;
    if (!mounted) {
      return;
    }
    var userId = rows.first['id'] as int;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Challenge toekennen'),
          content: DropdownButtonFormField<int>(
            initialValue: userId,
            items: rows
                .map((user) => DropdownMenuItem<int>(
                    value: user['id'] as int,
                    child: Text(user['name'].toString())))
                .toList(),
            onChanged: (value) => setLocal(() => userId = value ?? userId),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuleren')),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(productRepositoryProvider)
                    .adminAssign(userId, challengeId);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Toekennen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pointsDialog(int userId) async {
    final amount = TextEditingController(text: '100');
    final reason = TextEditingController(text: 'Admin correctie');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Punten aanpassen'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Aantal')),
          TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Reden')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren')),
          FilledButton(
            onPressed: () async {
              await ref.read(productRepositoryProvider).adminAdjustPoints(
                  userId, int.parse(amount.text), reason.text);
              if (context.mounted) {
                Navigator.pop(context);
              }
              setState(reload);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    amount.dispose();
    reason.dispose();
  }

  Widget _demoHealthForm() {
    return AsyncPage<List<dynamic>>(
      future: users,
      builder: (context, rows) {
        int userId = rows.first['id'] as int;
        bool addWorkout = false;
        String metric = 'steps';
        String activity = 'walking';
        final value = TextEditingController(text: '5000');
        final duration = TextEditingController(text: '1800');
        return StatefulBuilder(
          builder: (context, setLocal) => ListView(
            padding: const EdgeInsets.all(18),
            children: [
              DropdownButtonFormField<int>(
                initialValue: userId,
                decoration: const InputDecoration(labelText: 'Gebruiker'),
                items: rows
                    .map((user) => DropdownMenuItem<int>(
                        value: user['id'] as int,
                        child: Text(user['name'].toString())))
                    .toList(),
                onChanged: (selected) =>
                    setLocal(() => userId = selected ?? userId),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Metric')),
                  ButtonSegment(value: true, label: Text('Workout')),
                ],
                selected: {addWorkout},
                onSelectionChanged: (selected) =>
                    setLocal(() => addWorkout = selected.first),
              ),
              if (!addWorkout) ...[
                DropdownButtonFormField<String>(
                  initialValue: metric,
                  decoration: const InputDecoration(labelText: 'Metric'),
                  items: const [
                    DropdownMenuItem(value: 'steps', child: Text('Stappen')),
                    DropdownMenuItem(
                        value: 'water_intake', child: Text('Water')),
                    DropdownMenuItem(
                        value: 'active_energy_burned',
                        child: Text('Actieve calorieën')),
                  ],
                  onChanged: (selected) =>
                      setLocal(() => metric = selected ?? metric),
                ),
                TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Waarde')),
              ] else ...[
                DropdownButtonFormField<String>(
                  initialValue: activity,
                  decoration: const InputDecoration(labelText: 'Activiteit'),
                  items: const [
                    DropdownMenuItem(value: 'walking', child: Text('Wandelen')),
                    DropdownMenuItem(
                        value: 'running', child: Text('Hardlopen')),
                    DropdownMenuItem(value: 'cycling', child: Text('Fietsen')),
                  ],
                  onChanged: (selected) =>
                      setLocal(() => activity = selected ?? activity),
                ),
                TextField(
                    controller: duration,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Duur in seconden')),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final payload = addWorkout
                      ? <String, dynamic>{
                          'user_id': userId,
                          'activity_type': activity,
                          'active_duration_seconds': int.parse(duration.text),
                        }
                      : <String, dynamic>{
                          'user_id': userId,
                          'metric_type': metric,
                          'value': num.parse(value.text),
                          'unit': metric == 'steps'
                              ? 'count'
                              : metric == 'water_intake'
                                  ? 'ml'
                                  : 'kcal',
                        };
                  await ref
                      .read(productRepositoryProvider)
                      .adminDemoHealth(payload);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Demodata toegevoegd.')));
                  }
                },
                icon: const Icon(Icons.science_outlined),
                label: Text(addWorkout
                    ? 'Demo-workout toevoegen'
                    : 'Health-demodata toevoegen'),
              ),
            ],
          ),
        );
      },
    );
  }
}
