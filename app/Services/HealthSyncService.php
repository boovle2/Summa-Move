<?php

namespace App\Services;

use App\Models\Device;
use App\Models\HealthRecord;
use App\Models\SyncRun;
use App\Models\User;
use App\Models\WorkoutSession;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Throwable;

class HealthSyncService
{
    /**
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    public function sync(User $user, Device $device, array $payload): array
    {
        $connection = $device->connections()->where('source', $payload['source'])->first();
        $grantedMetrics = $connection?->granted_metrics ?? [];
        $requestedMetrics = collect($payload['records'])
            ->pluck('metric_type')
            ->when($payload['workouts'] !== [], fn ($metrics) => $metrics->push('workout_session'))
            ->unique();
        $notGranted = $requestedMetrics->diff($grantedMetrics);

        if ($notGranted->isNotEmpty()) {
            throw ValidationException::withMessages([
                'records' => ['Metrics not granted for this device: '.$notGranted->implode(', ').'.'],
            ]);
        }

        $existingRun = SyncRun::where('user_id', $user->id)
            ->where('sync_id', $payload['sync_id'])
            ->first();

        if ($existingRun?->status === 'completed') {
            return $this->result($existingRun);
        }

        $records = $payload['records'];
        $workouts = $payload['workouts'];
        $run = $existingRun ?? SyncRun::create([
            'user_id' => $user->id,
            'device_id' => $device->id,
            'sync_id' => $payload['sync_id'],
            'source' => $payload['source'],
            'status' => 'processing',
            'cursor_in' => $payload['cursor'] ?? null,
            'received_count' => count($records) + count($workouts),
            'started_at' => now(),
        ]);

        try {
            DB::transaction(function () use ($user, $device, $payload, $records, $workouts, $run): void {
                $stored = 0;
                $duplicates = 0;
                $syncedAt = now();

                foreach ($records as $record) {
                    $record = $this->normalizeTimes($record, ['measured_at', 'measured_from', 'measured_to']);
                    $model = HealthRecord::updateOrCreate(
                        [
                            'user_id' => $user->id,
                            'source' => $payload['source'],
                            'metric_type' => $record['metric_type'],
                            'external_id' => $record['external_id'],
                        ],
                        [
                            ...$record,
                            'device_id' => $device->id,
                            'synced_at' => $syncedAt,
                        ],
                    );

                    $model->wasRecentlyCreated ? $stored++ : $duplicates++;
                }

                foreach ($workouts as $workout) {
                    $workout = $this->normalizeTimes($workout, ['started_at', 'ended_at']);
                    $model = WorkoutSession::updateOrCreate(
                        [
                            'user_id' => $user->id,
                            'source' => $payload['source'],
                            'external_id' => $workout['external_id'],
                        ],
                        [
                            ...$workout,
                            'device_id' => $device->id,
                            'synced_at' => $syncedAt,
                        ],
                    );

                    $model->wasRecentlyCreated ? $stored++ : $duplicates++;
                }

                $connection = $device->connections()->updateOrCreate(
                    ['source' => $payload['source']],
                    [
                        'cursor' => $payload['cursor'] ?? null,
                        'last_successful_sync_at' => $syncedAt,
                    ],
                );

                $device->update([
                    'active_source' => $payload['source'],
                    'last_synced_at' => $syncedAt,
                ]);

                $run->update([
                    'status' => 'completed',
                    'cursor_out' => $connection->cursor,
                    'stored_count' => $stored,
                    'duplicate_count' => $duplicates,
                    'completed_at' => $syncedAt,
                ]);
            });
        } catch (Throwable $exception) {
            $run->update([
                'status' => 'failed',
                'error_message' => 'Sync failed before completion.',
                'completed_at' => now(),
            ]);

            throw $exception;
        }

        return $this->result($run->fresh());
    }

    /**
     * @return array<string, mixed>
     */
    private function result(SyncRun $run): array
    {
        return [
            'sync_id' => $run->sync_id,
            'status' => $run->status,
            'stored' => $run->stored_count,
            'duplicates' => $run->duplicate_count,
            'rejected' => $run->rejected_count,
            'next_cursor' => $run->cursor_out,
        ];
    }

    /**
     * @param  array<string, mixed>  $item
     * @param  array<int, string>  $keys
     * @return array<string, mixed>
     */
    private function normalizeTimes(array $item, array $keys): array
    {
        foreach ($keys as $key) {
            if (! empty($item[$key])) {
                $item[$key] = CarbonImmutable::parse($item[$key])->utc();
            }
        }

        return $item;
    }
}
