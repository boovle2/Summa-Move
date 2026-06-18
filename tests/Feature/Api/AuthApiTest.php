<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_login_and_logout(): void
    {
        $register = $this->postJson('/api/v1/auth/register', [
            'name' => 'Demo User',
            'email' => 'demo@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'device_name' => 'demo-phone',
        ]);

        $register->assertCreated()
            ->assertJsonPath('data.user.email', 'demo@example.com')
            ->assertJsonStructure(['data' => ['token']]);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => 'demo@example.com',
            'password' => 'password123',
            'device_name' => 'second-phone',
        ]);

        $login->assertOk()->assertJsonStructure(['data' => ['token']]);
        $token = $login->json('data.token');

        $this->withToken($token)->deleteJson('/api/v1/auth/logout')->assertOk();
        $this->assertCount(1, User::first()->tokens);
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        User::factory()->create(['email' => 'demo@example.com', 'password' => 'password123']);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'demo@example.com',
            'password' => 'wrong-password',
            'device_name' => 'phone',
        ])->assertUnprocessable();
    }
}
