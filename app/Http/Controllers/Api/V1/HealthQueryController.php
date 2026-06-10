<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\DailySummaryRequest;
use App\Http\Requests\HealthStatusRequest;
use App\Models\HealthRecord;
use App\Models\WorkoutSession;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;

class HealthQueryController extends Controller
{
    public function status(HealthStatusRequest $request): JsonResponse
    {
        $device = $request->user()->devices()
            ->where('client_device_id', $request->string('device_id')->toString())
            ->firstOrFail();

        return response()->json([
            'data' => [
                'device' => $device,
                'connections' => $device->connections,
                'last_sync' => $device->last_synced_at,
            ],
        ]);
    }

    public function dailySummary(DailySummaryRequest $request): JsonResponse
    {
        $timezone = $request->string('timezone')->toString();
        $start = CarbonImmutable::createFromFormat('Y-m-d', $request->string('date'), $timezone)->startOfDay();
        $end = $start->endOfDay();
        $utcStart = $start->utc();
        $utcEnd = $end->utc();
        $userId = $request->user()->id;

        $records = HealthRecord::where('user_id', $userId)
            ->where(function ($query) use ($utcStart, $utcEnd): void {
                $query->whereBetween('measured_at', [$utcStart, $utcEnd])
                    ->orWhereBetween('measured_from', [$utcStart, $utcEnd])
                    ->orWhere(function ($interval) use ($utcStart, $utcEnd): void {
                        $interval->where('measured_from', '<=', $utcEnd)
                            ->where('measured_to', '>=', $utcStart);
                    });
            })
            ->get();

        $heartRates = $records->where('metric_type', 'heart_rate')->sortBy('measured_at');
        $sum = fn (string $metric): ?float => $records->where('metric_type', $metric)->isEmpty()
            ? null
            : (float) $records->where('metric_type', $metric)->sum('value');

        $workoutDuration = WorkoutSession::where('user_id', $userId)
            ->whereBetween('started_at', [$utcStart, $utcEnd])
            ->sum('active_duration_seconds');

        return response()->json([
            'data' => [
                'date' => $request->string('date')->toString(),
                'timezone' => $timezone,
                'steps' => $sum('steps'),
                'active_energy_burned_kcal' => $sum('active_energy_burned'),
                'dietary_energy_consumed_kcal' => $sum('dietary_energy_consumed'),
                'water_intake_ml' => $sum('water_intake'),
                'workout_duration_seconds' => $workoutDuration > 0 ? (int) $workoutDuration : null,
                'heart_rate' => [
                    'latest' => $heartRates->isEmpty() ? null : (float) $heartRates->last()->value,
                    'average' => $heartRates->isEmpty() ? null : round((float) $heartRates->avg('value'), 2),
                    'minimum' => $heartRates->isEmpty() ? null : (float) $heartRates->min('value'),
                    'maximum' => $heartRates->isEmpty() ? null : (float) $heartRates->max('value'),
                ],
            ],
        ]);
    }
}
