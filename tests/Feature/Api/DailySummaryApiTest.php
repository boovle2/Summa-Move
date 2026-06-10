<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DailySummaryApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_daily_summary_uses_timezone_and_does_not_double_count_workout_energy(): void
    {
        $user = User::factory()->create();
        $device = $user->devices()->create([
            'client_device_id' => 'phone-1',
            'platform' => 'android',
            'active_source' => 'health_connect',
        ]);
        Sanctum::actingAs($user, ['health:read']);

        foreach ([
            ['steps', 4200, 'count', '2026-06-09T22:30:00Z'],
            ['active_energy_burned', 100, 'kcal', '2026-06-10T08:00:00Z'],
            ['heart_rate', 60, 'bpm', '2026-06-10T08:01:00Z'],
            ['heart_rate', 100, 'bpm', '2026-06-10T08:02:00Z'],
        ] as $index => [$metric, $value, $unit, $measuredAt]) {
            $user->healthRecords()->create([
                'device_id' => $device->id,
                'source' => 'health_connect',
                'external_id' => "record-$index",
                'metric_type' => $metric,
                'value' => $value,
                'unit' => $unit,
                'measured_at' => $measuredAt,
                'synced_at' => now(),
            ]);
        }

        $user->workoutSessions()->create([
            'device_id' => $device->id,
            'source' => 'health_connect',
            'external_id' => 'workout-1',
            'activity_type' => 'running',
            'started_at' => '2026-06-10T08:00:00Z',
            'ended_at' => '2026-06-10T08:30:00Z',
            'active_duration_seconds' => 1800,
            'energy_burned_kcal' => 300,
            'synced_at' => now(),
        ]);

        $this->getJson('/api/v1/health/daily-summary?date=2026-06-10&timezone=Europe/Amsterdam')
            ->assertOk()
            ->assertJsonPath('data.steps', 4200)
            ->assertJsonPath('data.active_energy_burned_kcal', 100)
            ->assertJsonPath('data.dietary_energy_consumed_kcal', null)
            ->assertJsonPath('data.workout_duration_seconds', 1800)
            ->assertJsonPath('data.heart_rate.average', 80)
            ->assertJsonPath('data.heart_rate.minimum', 60)
            ->assertJsonPath('data.heart_rate.maximum', 100);
    }
}
