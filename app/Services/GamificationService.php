<?php

namespace App\Services;

use App\Models\ChallengeAssignment;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class GamificationService
{
    public function recalculate(User $user, bool $isDemo = false): void
    {
        $user->challengeAssignments()
            ->where('status', 'started')
            ->with('challenge')
            ->get()
            ->each(function (ChallengeAssignment $assignment) use ($user, $isDemo): void {
                $challenge = $assignment->challenge;
                $progress = match ($challenge->type) {
                    'health_metric' => $this->healthProgress($user, $challenge->metric_type, $isDemo),
                    'workout' => $this->workoutProgress($user, $challenge->activity_type, $isDemo),
                    default => $assignment->progress,
                };

                $assignment->update([
                    'progress' => $progress,
                    'is_demo' => $assignment->is_demo || $isDemo,
                ]);

                if ($progress >= $assignment->target_value) {
                    $this->complete($user, $assignment, $isDemo);
                }
            });
    }

    public function awardPoints(
        User $user,
        int $amount,
        string $reason,
        string $idempotencyKey,
        bool $isDemo = false,
        array $metadata = [],
    ): void {
        DB::transaction(function () use ($user, $amount, $reason, $idempotencyKey, $isDemo, $metadata): void {
            $created = DB::table('point_transactions')->insertOrIgnore([
                'user_id' => $user->id,
                'idempotency_key' => $idempotencyKey,
                'amount' => $amount,
                'reason' => $reason,
                'is_demo' => $isDemo,
                'metadata' => json_encode($metadata),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            if ($created === 1) {
                $user->increment('points_balance', $amount);
                $user->refresh();
                if ($user->points_balance < 0) {
                    throw new \DomainException('Insufficient points.');
                }
                $user->update(['level' => max(1, intdiv($user->points_balance, 500) + 1)]);
            }
        });
    }

    private function complete(User $user, ChallengeAssignment $assignment, bool $isDemo): void
    {
        $assignment->update([
            'status' => 'completed',
            'completed_at' => now(),
            'is_demo' => $assignment->is_demo || $isDemo,
        ]);

        $this->awardPoints(
            $user,
            $assignment->challenge->points,
            'challenge_completed',
            "challenge-assignment:{$assignment->id}",
            $assignment->is_demo || $isDemo,
            ['challenge_id' => $assignment->challenge_id],
        );
    }

    private function healthProgress(User $user, ?string $metric, bool $includeDemo): float
    {
        return (float) $user->healthRecords()
            ->where('metric_type', $metric)
            ->when(! $includeDemo, fn ($query) => $query->where('source', '!=', 'admin_demo'))
            ->sum('value');
    }

    private function workoutProgress(User $user, ?string $activityType, bool $includeDemo): float
    {
        return (float) $user->workoutSessions()
            ->when(! $includeDemo, fn ($query) => $query->where('source', '!=', 'admin_demo'))
            ->when($activityType, fn ($query) => $query->where('activity_type', $activityType))
            ->sum('active_duration_seconds');
    }
}
