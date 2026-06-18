<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpsertDeviceRequest;
use Illuminate\Http\JsonResponse;

class DeviceController extends Controller
{
    public function upsert(UpsertDeviceRequest $request, string $clientDeviceId): JsonResponse
    {
        $device = $request->user()->devices()->updateOrCreate(
            ['client_device_id' => $clientDeviceId],
            $request->safe()->only(['platform', 'active_source', 'app_version']),
        );

        if ($device->active_source) {
            $device->connections()->updateOrCreate(
                ['source' => $device->active_source],
                ['granted_metrics' => $request->input('granted_metrics', [])],
            );
        }

        return response()->json([
            'data' => $device->load('connections'),
        ]);
    }
}
