<?php

namespace Database\Seeders;

use App\Models\Challenge;
use App\Models\Friendship;
use App\Models\HealthRecord;
use App\Models\Message;
use App\Models\ShopItem;
use App\Models\Team;
use App\Models\User;
use App\Models\WorkoutSession;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $password = Hash::make(env('DEMO_PASSWORD', 'password123'));
        $users = collect([
            ['name' => 'Demo User', 'email' => 'demo@example.com', 'points_balance' => 1250, 'level' => 3, 'streak_days' => 3],
            ['name' => 'SummaMove Admin', 'email' => 'admin@summamove.test', 'role' => 'admin', 'points_balance' => 5000, 'level' => 10],
            ['name' => 'Emma Johnson', 'email' => 'emma@summamove.test', 'points_balance' => 2650, 'level' => 6],
            ['name' => 'Lucas van Dijk', 'email' => 'lucas@summamove.test', 'points_balance' => 2420, 'level' => 5],
            ['name' => 'Sophie Martinez', 'email' => 'sophie@summamove.test', 'points_balance' => 2850, 'level' => 6],
            ['name' => 'Noah Bakker', 'email' => 'noah@summamove.test', 'points_balance' => 2180, 'level' => 5],
            ['name' => 'Mila Peters', 'email' => 'mila@summamove.test', 'points_balance' => 2050, 'level' => 5],
            ['name' => 'Anna de Vries', 'email' => 'anna@summamove.test', 'points_balance' => 650, 'level' => 2],
            ['name' => 'Daan Jansen', 'email' => 'daan@summamove.test', 'points_balance' => 720, 'level' => 2],
            ['name' => 'Lisa Vermeer', 'email' => 'lisa@summamove.test', 'points_balance' => 680, 'level' => 2],
        ])->mapWithKeys(function (array $data) use ($password): array {
            $user = User::updateOrCreate(
                ['email' => $data['email']],
                [...$data, 'password' => $password, 'role' => $data['role'] ?? 'user'],
            );

            DB::table('point_transactions')->updateOrInsert(
                ['idempotency_key' => "seed-points:{$user->id}"],
                [
                    'user_id' => $user->id,
                    'amount' => $user->points_balance,
                    'reason' => 'seed_balance',
                    'is_demo' => false,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            );

            return [$user->email => $user];
        });

        $challengeData = [
            ['korte-wandeling', 'Korte wandeling', 'Zet 6.000 stappen vandaag', 'walk', 'Beginner', 'health_metric', 'steps', 6000, 'count', 80, false],
            ['trap-meester', 'Trap meester', 'Loop 10x de trap op', 'stairs', 'Beginner', 'workout', null, 600, 'seconds', 150, false],
            ['ochtendwandeling', 'Ochtendwandeling', 'Zet 10.000 stappen vandaag', 'walk', 'Gemiddeld', 'health_metric', 'steps', 10000, 'count', 120, false],
            ['actieve-dag', 'Actieve dag', 'Beweeg 30 minuten actief', 'timer', 'Gemiddeld', 'workout', null, 1800, 'seconds', 100, false],
            ['fietsen', 'Fietsen', 'Fiets 10 kilometer', 'bike', 'Gemiddeld', 'workout', 'cycling', 1800, 'seconds', 130, false],
            ['hardloop-uitdaging', 'Hardloop uitdaging', 'Ren 5 kilometer', 'run', 'Gevorderd', 'workout', 'running', 1500, 'seconds', 200, false],
            ['squat-challenge', 'Squat challenge', 'Doe 50 squats', 'fitness', 'Beginner', 'workout', null, 600, 'seconds', 110, false],
            ['stretch-routine', 'Stretch routine', 'Doe 15 minuten stretching', 'stretch', 'Beginner', 'workout', 'yoga', 900, 'seconds', 70, false],
            ['springtouw', 'Springtouw', 'Spring 300 keer touw', 'jump', 'Gemiddeld', 'workout', null, 600, 'seconds', 140, false],
            ['weekend-warrior', 'Weekend warrior', 'Zet 15.000 stappen op een dag', 'trophy', 'Gevorderd', 'health_metric', 'steps', 15000, 'count', 180, false],
            ['team-workout', 'Team workout', 'Doe een workout met een vriend', 'group', 'Gemiddeld', 'workout', null, 1200, 'seconds', 150, false],
            ['hydratatie', 'Hydratatie', 'Drink 2 liter water vandaag', 'water', 'Beginner', 'health_metric', 'water_intake', 2000, 'ml', 50, false],
            ['quick-walk', '5 Min Wandelen', 'Loop 5 minuten buiten of binnen', 'walk', 'Beginner', 'workout', 'walking', 300, 'seconds', 30, true],
            ['quick-stairs', 'Trap Sprint', '5x de trap op en neer', 'stairs', 'Beginner', 'workout', null, 300, 'seconds', 40, true],
            ['quick-stretch', 'Stretch Break', '5 minuten rekken en strekken', 'stretch', 'Beginner', 'workout', 'yoga', 300, 'seconds', 25, true],
            ['quick-jacks', 'Jumping Jacks', '50 jumping jacks', 'jump', 'Beginner', 'workout', null, 300, 'seconds', 35, true],
            ['quick-dance', 'Dance Break', 'Dans op je favoriete nummer', 'dance', 'Beginner', 'workout', 'dancing', 300, 'seconds', 30, true],
            ['quick-wall-sit', 'Wall Sit', '3x 30 seconden wall sit', 'fitness', 'Beginner', 'workout', null, 90, 'seconds', 45, true],
        ];

        $challenges = collect($challengeData)->mapWithKeys(function (array $data, int $index): array {
            [$slug, $title, $description, $icon, $difficulty, $type, $metric, $target, $unit, $points, $quick] = $data;
            $challenge = Challenge::updateOrCreate(['slug' => $slug], [
                'title' => $title,
                'description' => $description,
                'icon_key' => $icon,
                'difficulty' => $difficulty,
                'type' => $type,
                'metric_type' => $metric,
                'activity_type' => $type === 'workout' ? $metric : null,
                'target_value' => $target,
                'min_workout_seconds' => $type === 'workout' ? $target : null,
                'unit' => $unit,
                'points' => $points,
                'is_quick' => $quick,
                'sort_order' => $index,
                'instructions' => $quick ? ['Start de activiteit', 'Blijf in beweging', 'Synchroniseer je workout'] : null,
            ]);

            return [$slug => $challenge];
        });

        $shopData = [
            ['sportief', 'Sportief', 'directions_run', 'free', 0, 'Gratis'],
            ['student', 'Student', 'school', 'free', 0, 'Gratis'],
            ['zakelijk', 'Zakelijk', 'business', 'free', 0, 'Gratis'],
            ['fitness-fan', 'Fitness Fan', 'fitness_center', 'sport', 100, '5 challenges voltooien'],
            ['hardloper', 'Hardloper', 'sprint', 'sport', 150, '3x hardloop challenge'],
            ['fietser', 'Fietser', 'directions_bike', 'sport', 150, '50km gefietst'],
            ['yoga-master', 'Yoga Master', 'self_improvement', 'sport', 120, '10 stretch sessies'],
            ['basketballer', 'Basketballer', 'sports_basketball', 'team', 200, '5 team challenges'],
            ['voetballer', 'Voetballer', 'sports_soccer', 'team', 200, '3 duo-challenges'],
            ['zwemmer', 'Zwemmer', 'pool', 'allround', 250, '10 verschillende challenges'],
            ['bokser', 'Bokser', 'sports_mma', 'allround', 250, '7 dagen streak'],
            ['superheld', 'Superheld', 'shield', 'top', 300, '100.000 stappen totaal'],
            ['kampioen', 'Kampioen', 'emoji_events', 'top', 400, 'Top 3 leaderboard'],
            ['legendary', 'Legendary', 'star', 'top', 500, '30 dagen streak'],
            ['phoenix', 'Phoenix', 'local_fire_department', 'top', 600, '50 challenges voltooid'],
        ];
        $items = collect($shopData)->mapWithKeys(function (array $data, int $index): array {
            [$slug, $title, $icon, $category, $cost, $requirement] = $data;
            $item = ShopItem::updateOrCreate(['slug' => $slug], [
                'title' => $title,
                'icon_key' => $icon,
                'category' => $category,
                'points_cost' => $cost,
                'requirement' => $requirement,
                'sort_order' => $index,
            ]);

            return [$slug => $item];
        });

        $demo = $users['demo@example.com'];
        foreach (['sportief', 'student', 'zakelijk'] as $slug) {
            $demo->shopItems()->syncWithoutDetaching([$items[$slug]->id => ['purchased_at' => now()]]);
        }
        foreach (['trap-meester', 'ochtendwandeling', 'actieve-dag', 'hydratatie'] as $slug) {
            $demo->challengeAssignments()->updateOrCreate(
                ['challenge_id' => $challenges[$slug]->id],
                ['target_value' => $challenges[$slug]->target_value, 'started_at' => now()],
            );
        }

        foreach (['emma@summamove.test', 'lucas@summamove.test', 'sophie@summamove.test', 'noah@summamove.test', 'mila@summamove.test'] as $email) {
            Friendship::updateOrCreate(
                ['requester_id' => $demo->id, 'addressee_id' => $users[$email]->id],
                ['status' => 'accepted', 'accepted_at' => now()],
            );
        }
        foreach (['anna@summamove.test', 'daan@summamove.test', 'lisa@summamove.test'] as $email) {
            Friendship::updateOrCreate(
                ['requester_id' => $users[$email]->id, 'addressee_id' => $demo->id],
                ['status' => 'pending'],
            );
        }

        Message::firstOrCreate([
            'sender_id' => $users['emma@summamove.test']->id,
            'recipient_id' => $demo->id,
            'body' => 'Doe je mee met de hardloop uitdaging?',
        ]);

        $class = Team::updateOrCreate(['name' => 'Klas 3B'], ['description' => 'SummaSport klas', 'points' => 4850]);
        $running = Team::updateOrCreate(['name' => 'Running Club'], ['description' => 'Samen hardlopen', 'points' => 8200]);
        $class->users()->syncWithoutDetaching($users->take(6)->pluck('id'));
        $running->users()->syncWithoutDetaching([$demo->id, $users['emma@summamove.test']->id, $users['lucas@summamove.test']->id]);

        foreach ([
            ['first-win', 'Eerste Win', 'emoji_events'],
            ['seven-day-streak', '7 Dagen Streak', 'local_fire_department'],
            ['ten-challenges', '10 Challenges', 'military_tech'],
            ['top-five', 'Top 5 Speler', 'leaderboard'],
            ['most-progress', 'Meeste Vooruitgang', 'trending_up'],
            ['team-player', 'Team Player', 'groups'],
        ] as [$slug, $title, $icon]) {
            $achievementId = DB::table('achievements')->updateOrInsert(
                ['slug' => $slug],
                ['title' => $title, 'icon_key' => $icon, 'active' => true, 'created_at' => now(), 'updated_at' => now()],
            );
        }

        foreach ($users->where('role', 'user') as $user) {
            $device = $user->devices()->firstOrCreate(
                ['client_device_id' => "seed-device-{$user->id}"],
                ['platform' => 'android', 'active_source' => 'health_connect', 'app_version' => 'seed'],
            );
            HealthRecord::updateOrCreate(
                ['user_id' => $user->id, 'source' => 'health_connect', 'metric_type' => 'steps', 'external_id' => "seed-steps-{$user->id}"],
                ['device_id' => $device->id, 'value' => 3000 + ($user->id * 850), 'unit' => 'count', 'measured_at' => now(), 'synced_at' => now()],
            );
            WorkoutSession::updateOrCreate(
                ['user_id' => $user->id, 'source' => 'health_connect', 'external_id' => "seed-workout-{$user->id}"],
                [
                    'device_id' => $device->id,
                    'activity_type' => 'running',
                    'started_at' => now()->subMinutes(30),
                    'ended_at' => now(),
                    'active_duration_seconds' => 1800,
                    'energy_burned_kcal' => 220,
                    'synced_at' => now(),
                ],
            );
        }
    }
}
