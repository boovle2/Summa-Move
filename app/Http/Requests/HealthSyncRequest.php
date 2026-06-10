<?php

namespace App\Http\Requests;

use App\Support\HealthMetrics;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class HealthSyncRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'sync_id' => ['required', 'uuid'],
            'device_id' => ['required', 'string', 'max:255'],
            'source' => ['required', Rule::in(HealthMetrics::SOURCES)],
            'cursor' => ['nullable', 'string', 'max:4000'],
            'records' => ['present', 'array'],
            'records.*.external_id' => ['required', 'string', 'max:255'],
            'records.*.metric_type' => ['required', Rule::in(HealthMetrics::RECORD_TYPES)],
            'records.*.value' => ['required', 'numeric', 'min:0'],
            'records.*.unit' => ['required', 'string', 'max:32'],
            'records.*.measured_at' => ['nullable', 'date'],
            'records.*.measured_from' => ['nullable', 'date'],
            'records.*.measured_to' => ['nullable', 'date'],
            'records.*.timezone' => ['nullable', 'timezone'],
            'records.*.source_app' => ['nullable', 'string', 'max:255'],
            'records.*.source_device' => ['nullable', 'string', 'max:255'],
            'records.*.metadata' => ['nullable', 'array'],
            'workouts' => ['present', 'array'],
            'workouts.*.external_id' => ['required', 'string', 'max:255'],
            'workouts.*.activity_type' => ['required', 'string', 'max:64'],
            'workouts.*.started_at' => ['required', 'date'],
            'workouts.*.ended_at' => ['required', 'date'],
            'workouts.*.timezone' => ['nullable', 'timezone'],
            'workouts.*.active_duration_seconds' => ['required', 'integer', 'min:0'],
            'workouts.*.energy_burned_kcal' => ['nullable', 'numeric', 'min:0'],
            'workouts.*.metadata' => ['nullable', 'array'],
        ];
    }

    /**
     * @return array<callable>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                $records = $this->input('records', []);
                $workouts = $this->input('workouts', []);

                if (count($records) + count($workouts) > 500) {
                    $validator->errors()->add('records', 'A sync request may contain at most 500 records and workouts combined.');
                }

                foreach ($records as $index => $record) {
                    $metric = $record['metric_type'] ?? null;
                    $unit = $record['unit'] ?? null;

                    if ($metric && $unit && (HealthMetrics::UNITS[$metric] ?? null) !== $unit) {
                        $validator->errors()->add("records.$index.unit", 'Unit must be '.HealthMetrics::UNITS[$metric]." for $metric.");
                    }

                    if (empty($record['measured_at']) && empty($record['measured_from'])) {
                        $validator->errors()->add("records.$index.measured_at", 'Provide measured_at or measured_from.');
                    }

                    if (! empty($record['measured_from']) && ! empty($record['measured_to'])
                        && strtotime($record['measured_to']) < strtotime($record['measured_from'])) {
                        $validator->errors()->add("records.$index.measured_to", 'measured_to must be after or equal to measured_from.');
                    }
                }

                foreach ($workouts as $index => $workout) {
                    if (! empty($workout['started_at']) && ! empty($workout['ended_at'])
                        && strtotime($workout['ended_at']) < strtotime($workout['started_at'])) {
                        $validator->errors()->add("workouts.$index.ended_at", 'ended_at must be after or equal to started_at.');
                    }
                }
            },
        ];
    }
}
