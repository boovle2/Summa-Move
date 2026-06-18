<?php

namespace App\Models;

use Database\Factories\DeviceFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Device extends Model
{
    /** @use HasFactory<DeviceFactory> */
    use HasFactory;

    protected $fillable = [
        'client_device_id',
        'platform',
        'active_source',
        'app_version',
        'last_synced_at',
    ];

    protected function casts(): array
    {
        return ['last_synced_at' => 'datetime'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function connections(): HasMany
    {
        return $this->hasMany(HealthConnection::class);
    }
}
