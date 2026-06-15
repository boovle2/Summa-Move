<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    public function home(Request $request): JsonResponse
    {
        $user = $request->user();
        $today = CarbonImmutable::today('Europe/Amsterdam');

        return response()->json(['data' => [
            'user' => $this->userSummary($user),
            'daily_summary' => $this->dailySummary($user, $today),
            'featured_challenge' => $user->challengeAssignments()
                ->with('challenge')
                ->where('status', 'started')
                ->first(),
        ]]);
    }

    public function profile(Request $request): JsonResponse
    {
        $user = $request->user();
        $weekStart = CarbonImmutable::now()->startOfWeek()->utc();

        return response()->json(['data' => [
            'user' => $this->userSummary($user),
            'stats' => [
                'completed_challenges' => $user->challengeAssignments()->where('status', 'completed')->count(),
                'weekly_steps' => (float) $user->healthRecords()
                    ->where('metric_type', 'steps')->where('measured_to', '>=', $weekStart)->sum('value'),
                'weekly_active_minutes' => (int) round($user->workoutSessions()
                    ->where('started_at', '>=', $weekStart)->sum('active_duration_seconds') / 60),
            ],
            'favorite_sports' => $user->settings['favorite_sports'] ?? ['Hardlopen', 'Fietsen', 'Fitness'],
            'achievements' => DB::table('achievements')
                ->leftJoin('achievement_user', function ($join) use ($user): void {
                    $join->on('achievements.id', '=', 'achievement_user.achievement_id')
                        ->where('achievement_user.user_id', $user->id);
                })
                ->select('achievements.*', 'achievement_user.earned_at')
                ->get(),
        ]]);
    }

    public function settings(Request $request): JsonResponse
    {
        return response()->json(['data' => $this->settingsFor($request->user())]);
    }

    public function updateSettings(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'notifications' => ['sometimes', 'boolean'],
            'sound' => ['sometimes', 'boolean'],
            'theme' => ['sometimes', 'in:light,dark'],
            'language' => ['sometimes', 'in:nl'],
        ]);

        $request->user()->update(['settings' => [...$this->settingsFor($request->user()), ...$validated]]);

        return $this->settings($request);
    }

    public function rankings(Request $request): JsonResponse
    {
        $period = $request->validate(['period' => ['nullable', 'in:today,week,progress,friends']])['period'] ?? 'today';
        $query = User::query()->where('role', 'user');

        if ($period === 'friends') {
            $friendIds = DB::table('friendships')
                ->where('status', 'accepted')
                ->where(fn ($q) => $q->where('requester_id', $request->user()->id)
                    ->orWhere('addressee_id', $request->user()->id))
                ->get()
                ->flatMap(fn ($friendship) => [$friendship->requester_id, $friendship->addressee_id])
                ->reject(fn ($id) => $id === $request->user()->id);
            $query->whereIn('id', $friendIds);
        }

        $start = $period === 'week' ? now()->startOfWeek() : now()->startOfDay();
        $rows = $query->get()->map(function (User $user) use ($period, $start): array {
            $value = $period === 'friends'
                ? DB::table('point_transactions')->where('user_id', $user->id)->where('is_demo', false)->sum('amount')
                : $user->healthRecords()->where('source', '!=', 'admin_demo')->where('metric_type', 'steps')
                    ->where(fn ($q) => $q->where('measured_at', '>=', $start)
                        ->orWhere('measured_to', '>=', $start))->sum('value');

            if ($period === 'progress') {
                $value = $user->challengeAssignments()->where('is_demo', false)->where('status', 'completed')->count() * 25;
            }

            return [...$this->publicUserSummary($user), 'value' => (float) $value];
        })->sortByDesc('value')->values()->map(fn ($row, $index) => [...$row, 'rank' => $index + 1]);

        return response()->json(['data' => ['period' => $period, 'rankings' => $rows]]);
    }

    private function userSummary(User $user): array
    {
        return $user->only([
            'id', 'name', 'email', 'role', 'points_balance', 'level', 'streak_days',
            'profile_status', 'active_character_key',
        ]);
    }

    private function publicUserSummary(User $user): array
    {
        return $user->only([
            'id', 'name', 'points_balance', 'level', 'streak_days',
            'profile_status', 'active_character_key',
        ]);
    }

    private function settingsFor(User $user): array
    {
        return [...[
            'notifications' => true,
            'sound' => true,
            'theme' => 'light',
            'language' => 'nl',
        ], ...($user->settings ?? [])];
    }

    private function dailySummary(User $user, CarbonImmutable $day): array
    {
        $start = $day->startOfDay()->utc();
        $end = $day->endOfDay()->utc();
        $records = $user->healthRecords()->where(fn ($q) => $q->whereBetween('measured_at', [$start, $end])
            ->orWhereBetween('measured_from', [$start, $end])
            ->orWhereBetween('measured_to', [$start, $end]))->get();

        return [
            'steps' => $records->where('metric_type', 'steps')->sum('value') ?: null,
            'water_intake_ml' => $records->where('metric_type', 'water_intake')->sum('value') ?: null,
            'active_energy_burned_kcal' => $records->where('metric_type', 'active_energy_burned')->sum('value') ?: null,
            'workout_duration_seconds' => $user->workoutSessions()->whereBetween('started_at', [$start, $end])
                ->sum('active_duration_seconds') ?: null,
        ];
    }
}
