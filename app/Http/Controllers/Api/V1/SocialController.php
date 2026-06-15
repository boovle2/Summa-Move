<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Challenge;
use App\Models\Friendship;
use App\Models\Message;
use App\Models\Team;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SocialController extends Controller
{
    public function friends(Request $request): JsonResponse
    {
        $friendIds = $this->acceptedFriendIds($request->user());

        return response()->json(['data' => User::whereIn('id', $friendIds)->get()->map(
            fn (User $user) => $this->summary($user),
        )]);
    }

    public function requests(Request $request): JsonResponse
    {
        $requests = Friendship::where('addressee_id', $request->user()->id)
            ->where('status', 'pending')
            ->get()
            ->map(fn (Friendship $friendship) => [
                'id' => $friendship->id,
                'user' => $this->summary(User::findOrFail($friendship->requester_id)),
            ]);

        return response()->json(['data' => $requests]);
    }

    public function sendRequest(Request $request): JsonResponse
    {
        $validated = $request->validate(['user_id' => ['required', 'integer', 'exists:users,id']]);
        abort_if((int) $validated['user_id'] === $request->user()->id, 422);
        abort_if(Friendship::where(fn ($q) => $q
            ->where('requester_id', $request->user()->id)->where('addressee_id', $validated['user_id']))
            ->orWhere(fn ($q) => $q
                ->where('requester_id', $validated['user_id'])->where('addressee_id', $request->user()->id))
            ->exists(), 422, 'Friendship already exists.');

        $friendship = Friendship::create([
            'requester_id' => $request->user()->id,
            'addressee_id' => $validated['user_id'],
        ]);

        return response()->json(['data' => $friendship], 201);
    }

    public function accept(Request $request, Friendship $friendRequest): JsonResponse
    {
        abort_unless($friendRequest->addressee_id === $request->user()->id && $friendRequest->status === 'pending', 403);
        $friendRequest->update(['status' => 'accepted', 'accepted_at' => now()]);

        return response()->json(['data' => $friendRequest]);
    }

    public function decline(Request $request, Friendship $friendRequest): JsonResponse
    {
        abort_unless($friendRequest->addressee_id === $request->user()->id && $friendRequest->status === 'pending', 403);
        $friendRequest->delete();

        return response()->json(['message' => 'Friend request declined.']);
    }

    public function challenge(Request $request, User $friend): JsonResponse
    {
        abort_unless($this->acceptedFriendIds($request->user())->contains($friend->id), 403);
        $challengeId = $request->validate(['challenge_id' => ['nullable', 'exists:challenges,id']])['challenge_id']
            ?? Challenge::where('active', true)->orderBy('sort_order')->value('id');
        $challenge = Challenge::findOrFail($challengeId);

        foreach ([$request->user(), $friend] as $user) {
            $user->challengeAssignments()->firstOrCreate(
                ['challenge_id' => $challenge->id],
                ['target_value' => $challenge->target_value, 'started_at' => now()],
            );
        }

        return response()->json(['data' => ['challenge' => $challenge, 'friend' => $this->summary($friend)]]);
    }

    public function messages(Request $request, User $friend): JsonResponse
    {
        abort_unless($this->acceptedFriendIds($request->user())->contains($friend->id), 403);
        $messages = Message::where(fn ($q) => $q->where('sender_id', $request->user()->id)->where('recipient_id', $friend->id))
            ->orWhere(fn ($q) => $q->where('sender_id', $friend->id)->where('recipient_id', $request->user()->id))
            ->orderBy('created_at')
            ->get();

        Message::where('sender_id', $friend->id)->where('recipient_id', $request->user()->id)
            ->whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['data' => ['friend' => $this->summary($friend), 'messages' => $messages]]);
    }

    public function sendMessage(Request $request, User $friend): JsonResponse
    {
        abort_unless($this->acceptedFriendIds($request->user())->contains($friend->id), 403);
        $validated = $request->validate(['body' => ['required', 'string', 'max:2000']]);
        $message = Message::create([
            'sender_id' => $request->user()->id,
            'recipient_id' => $friend->id,
            'body' => $validated['body'],
        ]);

        return response()->json(['data' => $message], 201);
    }

    public function teams(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->teams()->withCount('users')->get()]);
    }

    public function team(Request $request, Team $team): JsonResponse
    {
        abort_unless($team->users()->whereKey($request->user()->id)->exists(), 403);
        $team->load('users');

        return response()->json(['data' => [
            ...$team->only(['id', 'name', 'description', 'points']),
            'users' => $team->users->map(fn (User $user) => $this->summary($user)),
        ]]);
    }

    private function acceptedFriendIds(User $user)
    {
        return DB::table('friendships')->where('status', 'accepted')
            ->where(fn ($q) => $q->where('requester_id', $user->id)->orWhere('addressee_id', $user->id))
            ->get()
            ->map(fn ($row) => $row->requester_id === $user->id ? $row->addressee_id : $row->requester_id);
    }

    private function summary(User $user): array
    {
        return $user->only(['id', 'name', 'points_balance', 'level', 'active_character_key', 'profile_status']);
    }
}
