<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChallengeAssignment extends Model
{
    protected $guarded = ['id'];

    protected function casts(): array
    {
        return [
            'progress' => 'float',
            'target_value' => 'float',
            'is_demo' => 'boolean',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function challenge()
    {
        return $this->belongsTo(Challenge::class);
    }
}
