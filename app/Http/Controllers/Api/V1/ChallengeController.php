<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Challenge;
use App\Services\GamificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChallengeController extends Controller
{
    public function __construct(private readonly GamificationService $gamification) {}

    public function index(Request $request): JsonResponse
    {
        $assignments = $request->user()->challengeAssignments()->get()->keyBy('challenge_id');
        $challenges = Challenge::where('active', true)->orderBy('sort_order')->get()
            ->map(fn (Challenge $challenge) => [
                ...$challenge->toArray(),
                'assignment' => $assignments->get($challenge->id),
            ]);

        return response()->json(['data' => $challenges]);
    }

    public function show(Request $request, Challenge $challenge): JsonResponse
    {
        return response()->json(['data' => [
            ...$challenge->toArray(),
            'assignment' => $request->user()->challengeAssignments()->where('challenge_id', $challenge->id)->first(),
        ]]);
    }

    public function start(Request $request, Challenge $challenge): JsonResponse
    {
        abort_unless($challenge->active, 404);
        $assignment = $request->user()->challengeAssignments()->firstOrCreate(
            ['challenge_id' => $challenge->id],
            ['target_value' => $challenge->target_value, 'started_at' => now()],
        );
        $this->gamification->recalculate($request->user());

        return response()->json(['data' => $assignment->fresh()->load('challenge')]);
    }

    public function assignments(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->challengeAssignments()->with('challenge')->get()]);
    }
}
