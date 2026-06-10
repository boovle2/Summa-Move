<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('workout_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->constrained()->cascadeOnDelete();
            $table->string('source', 32);
            $table->string('external_id');
            $table->string('activity_type', 64);
            $table->timestamp('started_at');
            $table->timestamp('ended_at');
            $table->string('timezone', 64)->nullable();
            $table->unsignedInteger('active_duration_seconds');
            $table->decimal('energy_burned_kcal', 12, 3)->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('synced_at');
            $table->timestamps();

            $table->unique(['user_id', 'source', 'external_id'], 'workouts_dedupe');
            $table->index(['user_id', 'started_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('workout_sessions');
    }
};
