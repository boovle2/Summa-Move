import 'package:flutter/material.dart';

IconData iconFor(String? key) => switch (key) {
      'walk' => Icons.directions_walk,
      'stairs' => Icons.stairs_outlined,
      'timer' => Icons.timer_outlined,
      'bike' || 'directions_bike' => Icons.directions_bike,
      'run' || 'sprint' || 'directions_run' => Icons.directions_run,
      'fitness' || 'fitness_center' => Icons.fitness_center,
      'stretch' || 'self_improvement' => Icons.self_improvement,
      'jump' => Icons.sports_gymnastics,
      'dance' => Icons.music_note,
      'group' || 'groups' => Icons.groups,
      'water' => Icons.water_drop_outlined,
      'school' => Icons.school_outlined,
      'business' => Icons.business_center_outlined,
      'sports_basketball' => Icons.sports_basketball,
      'sports_soccer' => Icons.sports_soccer,
      'pool' => Icons.pool,
      'sports_mma' => Icons.sports_mma,
      'shield' => Icons.shield_outlined,
      'emoji_events' || 'trophy' => Icons.emoji_events_outlined,
      'star' => Icons.star_outline,
      'local_fire_department' => Icons.local_fire_department_outlined,
      'leaderboard' => Icons.leaderboard_outlined,
      'trending_up' => Icons.trending_up,
      _ => Icons.sports_score,
    };

class AppCard extends StatelessWidget {
  const AppCard(
      {required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(18),
      super.key});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child:
          InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class AsyncPage<T> extends StatelessWidget {
  const AsyncPage(
      {required this.future, required this.builder, this.onRetry, super.key});

  final Future<T> future;
  final Widget Function(BuildContext context, T value) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                      'Gegevens konden niet worden geladen.\n${snapshot.error}',
                      textAlign: TextAlign.center),
                  if (onRetry != null)
                    TextButton(
                        onPressed: onRetry,
                        child: const Text('Opnieuw proberen')),
                ],
              ),
            ),
          );
        }
        return builder(context, snapshot.requireData);
      },
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold))),
        if (trailing != null) trailing!,
      ],
    );
  }
}
