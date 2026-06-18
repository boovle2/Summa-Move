<?php

namespace App\Support;

final class HealthMetrics
{
    public const SOURCES = ['health_connect', 'healthkit', 'samsung_health'];

    public const PLATFORMS = ['android', 'ios'];

    public const UNITS = [
        'steps' => 'count',
        'heart_rate' => 'bpm',
        'active_energy_burned' => 'kcal',
        'dietary_energy_consumed' => 'kcal',
        'water_intake' => 'ml',
    ];

    public const RECORD_TYPES = [
        'steps',
        'heart_rate',
        'active_energy_burned',
        'dietary_energy_consumed',
        'water_intake',
    ];

    public const ALL_TYPES = [
        ...self::RECORD_TYPES,
        'workout_session',
    ];

    private function __construct() {}
}
