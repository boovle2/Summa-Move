<?php

namespace Tests\Feature\Api;

use App\Models\Challenge;
use App\Models\Friendship;
use App\Models\ShopItem;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_admin_can_access_admin_api(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'user']));
        $this->getJson('/api/v1/admin/dashboard')->assertForbidden();

        Sanctum::actingAs(User::factory()->create(['role' => 'admin']));
        $this->getJson('/api/v1/admin/dashboard')->assertOk()->assertJsonStructure(['data' => ['users', 'challenges']]);
    }

    public function test_health_sync_completes_challenge_and_awards_points_once(): void
    {
        $user = User::factory()->create(['points_balance' => 0]);
        $challenge = Challenge::create([
            'slug' => 'test-steps',
            'title' => 'Test steps',
            'description' => 'Walk',
            'type' => 'health_metric',
            'metric_type' => 'steps',
            'target_value' => 100,
            'unit' => 'count',
            'points' => 50,
        ]);
        $user->challengeAssignments()->create(['challenge_id' => $challenge->id, 'target_value' => 100, 'started_at' => now()]);
        $device = $user->devices()->create(['client_device_id' => 'phone', 'platform' => 'android', 'active_source' => 'health_connect']);
        $device->connections()->create(['source' => 'health_connect', 'granted_metrics' => ['steps']]);
        Sanctum::actingAs($user, ['health:sync']);

        $payload = [
            'sync_id' => (string) Str::uuid(),
            'device_id' => 'phone',
            'source' => 'health_connect',
            'records' => [[
                'external_id' => 'steps',
                'metric_type' => 'steps',
                'value' => 100,
                'unit' => 'count',
                'measured_at' => now()->toIso8601String(),
            ]],
            'workouts' => [],
        ];

        $this->postJson('/api/v1/health/sync', $payload)->assertOk();
        $payload['sync_id'] = (string) Str::uuid();
        $this->postJson('/api/v1/health/sync', $payload)->assertOk();

        $this->assertSame(50, $user->fresh()->points_balance);
        $this->assertDatabaseCount('point_transactions', 1);
        $this->assertDatabaseHas('challenge_assignments', ['status' => 'completed']);
    }

    public function test_admin_demo_health_affects_challenge_but_not_ranking(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['points_balance' => 0]);
        $challenge = Challenge::create([
            'slug' => 'demo-steps',
            'title' => 'Demo steps',
            'description' => 'Walk',
            'type' => 'health_metric',
            'metric_type' => 'steps',
            'target_value' => 100,
            'unit' => 'count',
            'points' => 25,
        ]);
        $user->challengeAssignments()->create(['challenge_id' => $challenge->id, 'target_value' => 100, 'started_at' => now()]);
        Sanctum::actingAs($admin);

        $this->postJson('/api/v1/admin/demo-health', [
            'user_id' => $user->id,
            'metric_type' => 'steps',
            'value' => 100,
            'unit' => 'count',
        ])->assertCreated();

        $this->assertSame(25, $user->fresh()->points_balance);
        $this->assertDatabaseHas('challenge_assignments', ['user_id' => $user->id, 'is_demo' => true, 'status' => 'completed']);

        Sanctum::actingAs($user);
        $this->getJson('/api/v1/rankings?period=today')->assertOk()
            ->assertJsonPath('data.rankings.0.value', 0);
    }

    public function test_shop_purchase_is_atomic_and_rejects_insufficient_balance(): void
    {
        $user = User::factory()->create(['points_balance' => 50]);
        $item = ShopItem::create([
            'slug' => 'expensive',
            'title' => 'Expensive',
            'icon_key' => 'star',
            'category' => 'top',
            'points_cost' => 100,
        ]);
        Sanctum::actingAs($user);

        $this->postJson("/api/v1/shop/items/{$item->id}/purchase")->assertUnprocessable();
        $this->assertSame(50, $user->fresh()->points_balance);
        $this->assertDatabaseCount('shop_item_user', 0);
    }

    public function test_messages_require_accepted_friendship(): void
    {
        $user = User::factory()->create();
        $friend = User::factory()->create();
        $stranger = User::factory()->create();
        Friendship::create(['requester_id' => $user->id, 'addressee_id' => $friend->id, 'status' => 'accepted']);
        Sanctum::actingAs($user);

        $this->postJson("/api/v1/messages/{$friend->id}", ['body' => 'Hoi'])->assertCreated();
        $this->postJson("/api/v1/messages/{$stranger->id}", ['body' => 'Hoi'])->assertForbidden();
    }

    public function test_user_can_update_settings(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->putJson('/api/v1/me/settings', ['theme' => 'dark', 'notifications' => false])
            ->assertOk()
            ->assertJsonPath('data.theme', 'dark')
            ->assertJsonPath('data.notifications', false);
    }

    public function test_rankings_do_not_expose_user_email_addresses(): void
    {
        $viewer = User::factory()->create();
        $other = User::factory()->create();
        Sanctum::actingAs($viewer);

        $this->getJson('/api/v1/rankings?period=today')
            ->assertOk()
            ->assertJsonMissing(['email' => $other->email]);
    }

    public function test_team_detail_only_exposes_public_member_fields(): void
    {
        $viewer = User::factory()->create();
        $other = User::factory()->create(['settings' => ['theme' => 'dark']]);
        $team = Team::create(['name' => 'Privacy test']);
        $team->users()->attach([$viewer->id, $other->id]);
        Sanctum::actingAs($viewer);

        $this->getJson("/api/v1/teams/{$team->id}")
            ->assertOk()
            ->assertJsonMissing(['email' => $other->email])
            ->assertJsonMissing(['settings' => ['theme' => 'dark']]);
    }

    public function test_demo_health_cannot_become_a_real_reward_when_challenge_starts_later(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $user = User::factory()->create(['points_balance' => 0]);
        $challenge = Challenge::create([
            'slug' => 'late-demo-steps',
            'title' => 'Late demo steps',
            'description' => 'Walk',
            'type' => 'health_metric',
            'metric_type' => 'steps',
            'target_value' => 100,
            'unit' => 'count',
            'points' => 25,
        ]);
        Sanctum::actingAs($admin);
        $this->postJson('/api/v1/admin/demo-health', [
            'user_id' => $user->id,
            'metric_type' => 'steps',
            'value' => 100,
            'unit' => 'count',
        ])->assertCreated();

        Sanctum::actingAs($user);
        $this->postJson("/api/v1/challenges/{$challenge->id}/start")->assertOk();

        $this->assertSame(0, $user->fresh()->points_balance);
        $this->assertDatabaseHas('challenge_assignments', [
            'user_id' => $user->id,
            'challenge_id' => $challenge->id,
            'status' => 'started',
            'is_demo' => false,
        ]);
    }
}
