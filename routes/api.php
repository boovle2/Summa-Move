<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\HealthQueryController;
use App\Http\Controllers\Api\V1\HealthSyncController;
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
    });
});
