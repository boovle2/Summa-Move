<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class HealthSyncApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_sync_is_idempotent_and_updates_cursor_after_success(): void
    {
        [$user, $payload] = $this->authenticatedPayload();

        $first = $this->postJson('/api/v1/health/sync', $payload);
        $first->assertOk()
            ->assertJsonPath('data.stored', 3)
            ->assertJsonPath('data.duplicates', 0)
            ->assertJsonPath('data.next_cursor', 'cursor-2');

        $this->postJson('/api/v1/health/sync', $payload)
            ->assertOk()
            ->assertJsonPath('data.stored', 3);

        $payload['sync_id'] = (string) Str::uuid();
        $this->postJson('/api/v1/health/sync', $payload)
            ->assertOk()
            ->assertJsonPath('data.stored', 0)
            ->assertJsonPath('data.duplicates', 3);

        $this->assertDatabaseCount('health_records', 2);
        $this->assertDatabaseCount('workout_sessions', 1);
        $this->assertSame('cursor-2', $user->devices()->first()->connections()->first()->cursor);
    }

    public function test_sync_rejects_invalid_unit_and_does_not_update_cursor(): void
    {
        [$user, $payload] = $this->authenticatedPayload();
        $payload['records'][0]['unit'] = 'kcal';

        $this->postJson('/api/v1/health/sync', $payload)->assertUnprocessable();

        $this->assertNull($user->devices()->first()->connections()->first()->cursor);
        $this->assertDatabaseCount('health_records', 0);
    }

    public function test_sync_rejects_more_than_500_combined_items(): void
    {
        [, $payload] = $this->authenticatedPayload();
        $record = $payload['records'][0];
        $payload['records'] = [];
        $payload['workouts'] = [];

        for ($index = 0; $index < 501; $index++) {
            $payload['records'][] = [...$record, 'external_id' => "steps-$index"];
        }

        $this->postJson('/api/v1/health/sync', $payload)->assertUnprocessable();
    }

    public function test_user_cannot_sync_another_users_device(): void
    {
        [, $payload] = $this->authenticatedPayload();
        Sanctum::actingAs(User::factory()->create(), ['health:sync']);

        $this->postJson('/api/v1/health/sync', $payload)->assertNotFound();
    }

    public function test_sync_rejects_metrics_without_read_permission(): void
    {
        [, $payload] = $this->authenticatedPayload();
        $payload['records'][0]['metric_type'] = 'water_intake';
        $payload['records'][0]['unit'] = 'ml';

        $this->postJson('/api/v1/health/sync', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('records');
    }

    public function test_sync_rejects_invalid_time_order(): void
    {
        [, $payload] = $this->authenticatedPayload();
        $payload['workouts'][0]['ended_at'] = '2026-06-10T08:30:00Z';

        $this->postJson('/api/v1/health/sync', $payload)
            ->assertUnprocessable()
            ->assertJsonValidationErrors('workouts.0.ended_at');
    }

    public function test_v7_sync_stores_offset_timestamps_in_utc_and_keeps_timezone(): void
    {
        [, $payload] = $this->authenticatedPayload();
        $payload['records'] = [[
            'external_id' => 'heart-offset',
            'metric_type' => 'heart_rate',
            'value' => 70,
            'unit' => 'bpm',
            'measured_at' => '2026-06-10T12:00:00+02:00',
            'timezone' => 'Europe/Amsterdam',
        ]];
        $payload['workouts'] = [];

        $this->postJson('/api/v1/health/sync', $payload)->assertOk();

        $this->assertDatabaseHas('health_records', [
            'external_id' => 'heart-offset',
            'measured_at' => '2026-06-10 10:00:00',
            'timezone' => 'Europe/Amsterdam',
        ]);
    }

    /**
     * @return array{0: User, 1: array<string, mixed>}
     */
    private function authenticatedPayload(): array
    {
        $user = User::factory()->create();
        $device = $user->devices()->create([
            'client_device_id' => 'phone-1',
            'platform' => 'android',
            'active_source' => 'health_connect',
        ]);
        $device->connections()->create([
            'source' => 'health_connect',
            'granted_metrics' => ['steps', 'heart_rate', 'workout_session'],
        ]);
        Sanctum::actingAs($user, ['health:sync']);

        return [$user, [
            'sync_id' => (string) Str::uuid(),
            'device_id' => 'phone-1',
            'source' => 'health_connect',
            'cursor' => 'cursor-2',
            'records' => [
                [
                    'external_id' => 'steps-1',
                    'metric_type' => 'steps',
                    'value' => 5000,
                    'unit' => 'count',
                    'measured_from' => '2026-06-10T00:00:00Z',
                    'measured_to' => '2026-06-10T23:59:59Z',
                ],
                [
                    'external_id' => 'heart-1',
                    'metric_type' => 'heart_rate',
                    'value' => 74,
                    'unit' => 'bpm',
                    'measured_at' => '2026-06-10T08:30:00Z',
                ],
            ],
            'workouts' => [
                [
                    'external_id' => 'workout-1',
                    'activity_type' => 'running',
                    'started_at' => '2026-06-10T09:00:00Z',
                    'ended_at' => '2026-06-10T09:30:00Z',
                    'active_duration_seconds' => 1800,
                    'energy_burned_kcal' => 250,
                ],
            ],
        ]];
    }
}
