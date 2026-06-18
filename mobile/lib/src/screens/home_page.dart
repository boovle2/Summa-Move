import 'package:flutter/material.dart';

import '../services/product_repository.dart';
import '../widgets/app_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.repository,
    required this.userName,
    required this.onOpenMenu,
    required this.onOpenChallenges,
    required this.onOpenAvatar,
    required this.onOpenQuick,
    super.key,
  });

  final ProductRepository repository;
  final String userName;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenChallenges;
  final VoidCallback onOpenAvatar;
  final VoidCallback onOpenQuick;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = widget.repository.home();
  }

  void reload() => setState(() => future = widget.repository.home());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AsyncPage<Map<String, dynamic>>(
        future: future,
        onRetry: reload,
        builder: (context, data) {
          final daily = Map<String, dynamic>.from(data['daily_summary'] as Map);
          final user = Map<String, dynamic>.from(data['user'] as Map);
          final assignment = data['featured_challenge'] as Map?;
          final challenge = assignment?['challenge'] as Map?;

          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Hoi ${widget.userName}!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E258F),
                              ),
                        ),
                        const Text('Wat ga je vandaag doen?'),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton.filledTonal(
                        tooltip: 'Menu',
                        onPressed: widget.onOpenMenu,
                        icon: const Icon(Icons.menu),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF2E258F)]),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.bolt, size: 72, color: Colors.white),
                      const Text('5 Minuten Challenge',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Weinig tijd? Start een snelle workout!',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: widget.onOpenQuick,
                        style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE91E63)),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start nu - slechts 5 minuten'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  onTap: widget.onOpenChallenges,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                              child: Text('Challenge van vandaag',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold))),
                          Chip(
                              label: Text(
                                  challenge?['difficulty']?.toString() ??
                                      'Beginner')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(iconFor(challenge?['icon_key']?.toString()),
                              size: 54, color: const Color(0xFF2E258F)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    challenge?['title']?.toString() ??
                                        'Kies een challenge',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                                Text(challenge?['description']?.toString() ??
                                    'Bekijk alle beschikbare uitdagingen'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(
                  child: Column(
                    children: [
                      const Text('Jouw beweegdoel vandaag',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _goal(Icons.directions_walk, daily['steps'],
                              'van 10.000', 'Stappen', const Color(0xFFE91E63)),
                          _goal(
                              Icons.timer_outlined,
                              daily['workout_duration_seconds'] == null
                                  ? null
                                  : ((daily['workout_duration_seconds']
                                              as num) /
                                          60)
                                      .round(),
                              'van 30 min',
                              'Actief',
                              const Color(0xFF2E258F)),
                          _goal(
                              Icons.local_fire_department_outlined,
                              daily['active_energy_burned_kcal'],
                              'kcal',
                              'Verbrand',
                              Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                        child: _actionCard(
                            Icons.track_changes,
                            'Alle challenges',
                            '${user['points_balance']} punten',
                            widget.onOpenChallenges)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _actionCard(
                            iconFor(user['active_character_key']?.toString()),
                            'Mijn avatar',
                            'Level ${user['level']}',
                            widget.onOpenAvatar)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _goal(IconData icon, Object? value, String subtitle, String label,
      Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 6),
          Text(value == null ? '--' : (value as num).round().toString(),
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 20)),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _actionCard(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      child: SizedBox(
        height: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 38, color: const Color(0xFFE91E63)),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
