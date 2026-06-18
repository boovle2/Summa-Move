<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HealthFixtureContractTest extends TestCase
{
    use RefreshDatabase;

    public function test_documented_sync_fixtures_match_the_api_contract(): void
    {
        foreach ([
            ['health-connect-sync.json', 'android'],
            ['healthkit-sync.json', 'ios'],
            ['samsung-health-sync.json', 'android'],
        ] as [$filename, $platform]) {
            $payload = json_decode(
                file_get_contents(base_path("docs/fixtures/$filename")),
                true,
                flags: JSON_THROW_ON_ERROR,
            );
            $user = User::factory()->create();
            $device = $user->devices()->create([
                'client_device_id' => $payload['device_id'],
                'platform' => $platform,
                'active_source' => $payload['source'],
            ]);
            $device->connections()->create([
                'source' => $payload['source'],
                'granted_metrics' => [
                    ...array_column($payload['records'], 'metric_type'),
                    ...($payload['workouts'] === [] ? [] : ['workout_session']),
                ],
            ]);
            Sanctum::actingAs($user, ['health:sync']);

            $this->postJson('/api/v1/health/sync', $payload)
                ->assertOk()
                ->assertJsonPath('data.status', 'completed')
                ->assertJsonPath('data.next_cursor', $payload['cursor']);
        }
    }
}
