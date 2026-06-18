<?php

namespace App\Models;

use Database\Factories\HealthRecordFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HealthRecord extends Model
{
    /** @use HasFactory<HealthRecordFactory> */
    use HasFactory;

    protected $guarded = ['id'];

    protected function casts(): array
    {
        return [
            'value' => 'decimal:6',
            'measured_at' => 'datetime',
            'measured_from' => 'datetime',
            'measured_to' => 'datetime',
            'metadata' => 'array',
            'synced_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(Device::class);
    }
}
