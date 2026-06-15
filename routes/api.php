<?php

use App\Http\Controllers\Api\V1\AdminController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ChallengeController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\HealthQueryController;
use App\Http\Controllers\Api\V1\HealthSyncController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ShopController;
use App\Http\Controllers\Api\V1\SocialController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::post('/auth/register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::delete('/auth/logout', [AuthController::class, 'logout']);
        Route::put('/devices/{clientDeviceId}', [DeviceController::class, 'upsert'])->middleware('abilities:device:write');
        Route::post('/health/sync', HealthSyncController::class)->middleware(['abilities:health:sync', 'throttle:60,1']);
        Route::get('/health/status', [HealthQueryController::class, 'status'])->middleware('abilities:health:read');
        Route::get('/health/daily-summary', [HealthQueryController::class, 'dailySummary'])->middleware('abilities:health:read');

        Route::get('/me/home', [ProfileController::class, 'home']);
        Route::get('/me/profile', [ProfileController::class, 'profile']);
        Route::get('/me/settings', [ProfileController::class, 'settings']);
        Route::put('/me/settings', [ProfileController::class, 'updateSettings']);
        Route::get('/rankings', [ProfileController::class, 'rankings']);

        Route::get('/challenges', [ChallengeController::class, 'index']);
        Route::get('/challenges/{challenge}', [ChallengeController::class, 'show']);
        Route::post('/challenges/{challenge}/start', [ChallengeController::class, 'start']);
        Route::get('/challenge-assignments', [ChallengeController::class, 'assignments']);

        Route::get('/friends', [SocialController::class, 'friends']);
        Route::get('/friend-requests', [SocialController::class, 'requests']);
        Route::post('/friend-requests', [SocialController::class, 'sendRequest']);
        Route::post('/friend-requests/{friendRequest}/accept', [SocialController::class, 'accept']);
        Route::post('/friend-requests/{friendRequest}/decline', [SocialController::class, 'decline']);
        Route::post('/friends/{friend}/challenge', [SocialController::class, 'challenge']);
        Route::get('/messages/{friend}', [SocialController::class, 'messages']);
        Route::post('/messages/{friend}', [SocialController::class, 'sendMessage']);
        Route::get('/teams', [SocialController::class, 'teams']);
        Route::get('/teams/{team}', [SocialController::class, 'team']);

        Route::get('/shop/items', [ShopController::class, 'index']);
        Route::post('/shop/items/{item}/purchase', [ShopController::class, 'purchase']);
        Route::put('/characters/{item}/equip', [ShopController::class, 'equip']);

        Route::prefix('admin')->middleware('admin')->group(function (): void {
            Route::get('/dashboard', [AdminController::class, 'dashboard']);
            Route::get('/challenges', [AdminController::class, 'challenges']);
            Route::post('/challenges', [AdminController::class, 'storeChallenge']);
            Route::put('/challenges/{challenge}', [AdminController::class, 'updateChallenge']);
            Route::delete('/challenges/{challenge}', [AdminController::class, 'destroyChallenge']);
            Route::get('/shop-items', [AdminController::class, 'shopItems']);
            Route::post('/shop-items', [AdminController::class, 'storeShopItem']);
            Route::put('/shop-items/{shopItem}', [AdminController::class, 'updateShopItem']);
            Route::delete('/shop-items/{shopItem}', [AdminController::class, 'destroyShopItem']);
            Route::get('/teams', [AdminController::class, 'teams']);
            Route::post('/teams', [AdminController::class, 'storeTeam']);
            Route::put('/teams/{team}', [AdminController::class, 'updateTeam']);
            Route::delete('/teams/{team}', [AdminController::class, 'destroyTeam']);
            Route::get('/users', [AdminController::class, 'users']);
            Route::put('/users/{user}', [AdminController::class, 'updateUser']);
            Route::post('/assignments', [AdminController::class, 'assign']);
            Route::post('/point-adjustments', [AdminController::class, 'adjustPoints']);
            Route::post('/demo-health', [AdminController::class, 'demoHealth']);
            Route::get('/audits', [AdminController::class, 'audits']);
        });
    });
});
