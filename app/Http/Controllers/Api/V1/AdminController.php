<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Challenge;
use App\Models\HealthRecord;
use App\Models\ShopItem;
use App\Models\SyncRun;
use App\Models\Team;
use App\Models\User;
use App\Models\WorkoutSession;
use App\Services\GamificationService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminController extends Controller
{
    public function __construct(private readonly GamificationService $gamification) {}

    public function dashboard(): JsonResponse
    {
        return response()->json(['data' => [
            'users' => User::count(),
            'challenges' => Challenge::where('active', true)->count(),
            'completed_assignments' => DB::table('challenge_assignments')->where('status', 'completed')->count(),
            'sync_runs' => SyncRun::count(),
        ]]);
    }

    public function challenges(): JsonResponse
    {
        return response()->json(['data' => Challenge::orderBy('sort_order')->get()]);
    }

    public function storeChallenge(Request $request): JsonResponse
    {
        $challenge = Challenge::create($this->challengeData($request));
        $this->audit($request, 'challenge.created', $challenge, $challenge->toArray());

        return response()->json(['data' => $challenge], 201);
    }

    public function updateChallenge(Request $request, Challenge $challenge): JsonResponse
    {
        $challenge->update($this->challengeData($request, $challenge));
        $this->audit($request, 'challenge.updated', $challenge, $challenge->toArray());

        return response()->json(['data' => $challenge]);
    }

    public function destroyChallenge(Request $request, Challenge $challenge): JsonResponse
    {
        $challenge->update(['active' => false]);
        $this->audit($request, 'challenge.deactivated', $challenge);

        return response()->json(['message' => 'Challenge deactivated.']);
    }

    public function shopItems(): JsonResponse
    {
        return response()->json(['data' => ShopItem::orderBy('sort_order')->get()]);
    }

    public function storeShopItem(Request $request): JsonResponse
    {
        $item = ShopItem::create($this->shopData($request));
        $this->audit($request, 'shop_item.created', $item, $item->toArray());

        return response()->json(['data' => $item], 201);
    }

    public function updateShopItem(Request $request, ShopItem $shopItem): JsonResponse
    {
        $shopItem->update($this->shopData($request, $shopItem));
        $this->audit($request, 'shop_item.updated', $shopItem, $shopItem->toArray());

        return response()->json(['data' => $shopItem]);
    }

    public function destroyShopItem(Request $request, ShopItem $shopItem): JsonResponse
    {
        $shopItem->update(['active' => false]);
        $this->audit($request, 'shop_item.deactivated', $shopItem);

        return response()->json(['message' => 'Shop item deactivated.']);
    }

    public function teams(): JsonResponse
    {
        return response()->json(['data' => Team::with('users')->get()]);
    }

    public function storeTeam(Request $request): JsonResponse
    {
        $validated = $request->validate(['name' => ['required', 'string', 'max:255', 'unique:teams'], 'description' => ['nullable', 'string']]);
        $team = Team::create($validated);
        $team->users()->sync($request->input('user_ids', []));
        $this->audit($request, 'team.created', $team, $validated);

        return response()->json(['data' => $team->load('users')], 201);
    }

    public function updateTeam(Request $request, Team $team): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255', Rule::unique('teams')->ignore($team)],
            'description' => ['nullable', 'string'],
            'user_ids' => ['sometimes', 'array'],
            'user_ids.*' => ['integer', 'exists:users,id'],
        ]);
        $team->update(collect($validated)->except('user_ids')->all());
        if (array_key_exists('user_ids', $validated)) {
            $team->users()->sync($validated['user_ids']);
        }
        $this->audit($request, 'team.updated', $team, $validated);

        return response()->json(['data' => $team->load('users')]);
    }

    public function destroyTeam(Request $request, Team $team): JsonResponse
    {
        $this->audit($request, 'team.deleted', $team);
        $team->delete();

        return response()->json(['message' => 'Team deleted.']);
    }

    public function users(): JsonResponse
    {
        return response()->json(['data' => User::orderBy('name')->get()]);
    }

    public function updateUser(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'role' => ['sometimes', 'in:user,admin'],
            'profile_status' => ['sometimes', 'string', 'max:255'],
        ]);
        $user->update($validated);
        $this->audit($request, 'user.updated', $user, $validated);

        return response()->json(['data' => $user]);
    }

    public function assign(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'challenge_id' => ['required', 'exists:challenges,id'],
        ]);
        $user = User::findOrFail($validated['user_id']);
        $challenge = Challenge::findOrFail($validated['challenge_id']);
        $assignment = $user->challengeAssignments()->updateOrCreate(
            ['challenge_id' => $challenge->id],
            ['status' => 'started', 'progress' => 0, 'target_value' => $challenge->target_value, 'started_at' => now(), 'completed_at' => null],
        );
        $this->audit($request, 'challenge.assigned', $assignment, $validated);

        return response()->json(['data' => $assignment->load('challenge')]);
    }

    public function adjustPoints(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'amount' => ['required', 'integer', 'between:-100000,100000'],
            'reason' => ['required', 'string', 'max:255'],
        ]);
        $user = User::findOrFail($validated['user_id']);
        $this->gamification->awardPoints($user, $validated['amount'], $validated['reason'], 'admin-adjustment:'.str()->uuid());
        $this->audit($request, 'points.adjusted', $user, $validated);

        return response()->json(['data' => $user->fresh()]);
    }

    public function demoHealth(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => ['required', 'exists:users,id'],
            'metric_type' => ['nullable', 'in:steps,heart_rate,active_energy_burned,dietary_energy_consumed,water_intake'],
            'value' => ['nullable', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:32'],
            'activity_type' => ['nullable', 'string', 'max:64'],
            'active_duration_seconds' => ['nullable', 'integer', 'min:1'],
        ]);
        $user = User::findOrFail($validated['user_id']);
        $device = $user->devices()->firstOrCreate(
            ['client_device_id' => "admin-demo-{$user->id}"],
            ['platform' => 'android', 'app_version' => 'admin-demo'],
        );
        $now = CarbonImmutable::now();

        if (! empty($validated['metric_type'])) {
            HealthRecord::create([
                'user_id' => $user->id,
                'device_id' => $device->id,
                'source' => 'admin_demo',
                'external_id' => 'admin-'.str()->uuid(),
                'metric_type' => $validated['metric_type'],
                'value' => $validated['value'],
                'unit' => $validated['unit'],
                'measured_at' => $now,
                'timezone' => 'Europe/Amsterdam',
                'metadata' => ['admin_demo' => true],
                'synced_at' => $now,
            ]);
        }

        if (! empty($validated['activity_type'])) {
            WorkoutSession::create([
                'user_id' => $user->id,
                'device_id' => $device->id,
                'source' => 'admin_demo',
                'external_id' => 'admin-'.str()->uuid(),
                'activity_type' => $validated['activity_type'],
                'started_at' => $now->subSeconds($validated['active_duration_seconds']),
                'ended_at' => $now,
                'timezone' => 'Europe/Amsterdam',
                'active_duration_seconds' => $validated['active_duration_seconds'],
                'metadata' => ['admin_demo' => true],
                'synced_at' => $now,
            ]);
        }

        $this->gamification->recalculate($user, true);
        $this->audit($request, 'demo_health.created', $user, $validated);

        return response()->json(['data' => ['user' => $user->fresh(), 'message' => 'Demo health-data added.']], 201);
    }

    public function audits(): JsonResponse
    {
        return response()->json(['data' => AuditLog::latest()->limit(100)->get()]);
    }

    private function challengeData(Request $request, ?Challenge $challenge = null): array
    {
        return $request->validate([
            'slug' => ['required', 'string', 'max:255', Rule::unique('challenges')->ignore($challenge)],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'icon_key' => ['required', 'string', 'max:64'],
            'difficulty' => ['required', 'string', 'max:32'],
            'type' => ['required', 'in:health_metric,workout,admin_only'],
            'metric_type' => ['nullable', 'string', 'max:64'],
            'target_value' => ['required', 'numeric', 'min:0'],
            'unit' => ['nullable', 'string', 'max:32'],
            'activity_type' => ['nullable', 'string', 'max:64'],
            'min_workout_seconds' => ['nullable', 'integer', 'min:1'],
            'points' => ['required', 'integer', 'min:0'],
            'is_quick' => ['sometimes', 'boolean'],
            'active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
            'instructions' => ['nullable', 'array'],
        ]);
    }

    private function shopData(Request $request, ?ShopItem $item = null): array
    {
        return $request->validate([
            'slug' => ['required', 'string', 'max:255', Rule::unique('shop_items')->ignore($item)],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'icon_key' => ['required', 'string', 'max:64'],
            'category' => ['required', 'string', 'max:32'],
            'points_cost' => ['required', 'integer', 'min:0'],
            'requirement' => ['nullable', 'string', 'max:255'],
            'active' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
        ]);
    }

    private function audit(Request $request, string $action, object $auditable, array $payload = []): void
    {
        AuditLog::create([
            'actor_id' => $request->user()->id,
            'action' => $action,
            'auditable_type' => $auditable::class,
            'auditable_id' => $auditable->id,
            'payload' => $payload,
        ]);
    }
}
