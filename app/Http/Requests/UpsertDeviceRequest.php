<?php

namespace App\Http\Requests;

use App\Support\HealthMetrics;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpsertDeviceRequest extends FormRequest
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
            'platform' => ['required', Rule::in(HealthMetrics::PLATFORMS)],
            'active_source' => ['nullable', Rule::in(HealthMetrics::SOURCES)],
            'app_version' => ['nullable', 'string', 'max:32'],
            'granted_metrics' => ['sometimes', 'array'],
            'granted_metrics.*' => ['string', 'distinct', Rule::in(HealthMetrics::ALL_TYPES)],
        ];
    }

    /**
     * @return array<callable>
     */
    public function after(): array
    {
        return [
            function (Validator $validator): void {
                $platform = $this->input('platform');
                $source = $this->input('active_source');

                if ($source === 'healthkit' && $platform !== 'ios') {
                    $validator->errors()->add('active_source', 'HealthKit requires the iOS platform.');
                }

                if (in_array($source, ['health_connect', 'samsung_health'], true) && $platform !== 'android') {
                    $validator->errors()->add('active_source', 'Health Connect and Samsung Health require the Android platform.');
                }
            },
        ];
    }
}
