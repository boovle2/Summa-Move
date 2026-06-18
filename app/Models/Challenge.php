<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Challenge extends Model
{
    protected $guarded = ['id'];

    protected function casts(): array
    {
        return [
            'target_value' => 'float',
            'instructions' => 'array',
            'is_quick' => 'boolean',
            'active' => 'boolean',
        ];
    }
}
