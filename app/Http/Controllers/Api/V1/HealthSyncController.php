<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\HealthSyncRequest;
use App\Services\HealthSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class HealthSyncController extends Controller
{
    public function __invoke(HealthSyncRequest $request, HealthSyncService $syncService): JsonResponse
    {
        $device = $request->user()->devices()
            ->where('client_device_id', $request->string('device_id')->toString())
            ->firstOrFail();

        if ($device->active_source !== $request->string('source')->toString()) {
            throw ValidationException::withMessages([
                'source' => ['The sync source must match the active source for this device.'],
            ]);
        }

        return response()->json([
            'data' => $syncService->sync($request->user(), $device, $request->validated()),
        ]);
    }
}
