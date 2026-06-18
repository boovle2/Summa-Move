<?php

namespace App\Models;

use Database\Factories\HealthConnectionFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthConnection extends Model
{
    /** @use HasFactory<HealthConnectionFactory> */
    use HasFactory;

    protected $fillable = [
        'source',
        'granted_metrics',
        'cursor',
        'last_successful_sync_at',
    ];

    protected function casts(): array
    {
        return [
            'granted_metrics' => 'array',
            'last_successful_sync_at' => 'datetime',
        ];
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
