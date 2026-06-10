<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeviceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_device_endpoint_requires_authentication(): void
    {
        $this->putJson('/api/v1/devices/phone-1', [
            'platform' => 'android',
        ])->assertUnauthorized();
    }

    public function test_user_can_register_one_active_health_source(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user, ['device:write']);

        $response = $this->putJson('/api/v1/devices/phone-1', [
            'platform' => 'android',
            'active_source' => 'health_connect',
            'app_version' => '1.0.0',
            'granted_metrics' => ['steps', 'heart_rate'],
        ]);

        $response->assertOk()
            ->assertJsonPath('data.client_device_id', 'phone-1')
            ->assertJsonPath('data.active_source', 'health_connect');
        $this->assertDatabaseHas('health_connections', [
            'device_id' => $user->devices()->first()->id,
            'source' => 'health_connect',
        ]);
    }

    public function test_device_rejects_source_that_does_not_match_platform(): void
    {
        Sanctum::actingAs(User::factory()->create(), ['device:write']);

        $this->putJson('/api/v1/devices/iphone-1', [
            'platform' => 'ios',
            'active_source' => 'health_connect',
            'granted_metrics' => ['steps'],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('active_source');
    }
}
