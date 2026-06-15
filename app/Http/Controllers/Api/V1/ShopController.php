<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ShopItem;
use App\Services\GamificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ShopController extends Controller
{
    public function __construct(private readonly GamificationService $gamification) {}

    public function index(Request $request): JsonResponse
    {
        $owned = $request->user()->shopItems()->pluck('shop_items.id');
        $items = ShopItem::where('active', true)->orderBy('sort_order')->get()
            ->map(fn (ShopItem $item) => [...$item->toArray(), 'owned' => $owned->contains($item->id)]);

        return response()->json(['data' => [
            'points_balance' => $request->user()->points_balance,
            'active_character_key' => $request->user()->active_character_key,
            'items' => $items,
        ]]);
    }

    public function purchase(Request $request, ShopItem $item): JsonResponse
    {
        abort_unless($item->active, 404);
        abort_if($request->user()->shopItems()->whereKey($item->id)->exists(), 422, 'Item already owned.');
        abort_if($request->user()->points_balance < $item->points_cost, 422, 'Insufficient points.');

        DB::transaction(function () use ($request, $item): void {
            $this->gamification->awardPoints(
                $request->user(),
                -$item->points_cost,
                'shop_purchase',
                "shop-purchase:{$request->user()->id}:{$item->id}",
            );
            $request->user()->shopItems()->attach($item->id, ['purchased_at' => now()]);
        });

        return $this->index($request);
    }

    public function equip(Request $request, ShopItem $item): JsonResponse
    {
        abort_unless($item->points_cost === 0 || $request->user()->shopItems()->whereKey($item->id)->exists(), 422);
        $request->user()->update(['active_character_key' => $item->icon_key]);

        return response()->json(['data' => $request->user()->only(['active_character_key'])]);
    }
}
