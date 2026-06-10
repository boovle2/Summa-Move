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
        Schema::create('health_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->constrained()->cascadeOnDelete();
            $table->string('source', 32);
            $table->string('external_id');
            $table->string('metric_type', 64);
            $table->decimal('value', 18, 6);
            $table->string('unit', 32);
            $table->timestamp('measured_at')->nullable();
            $table->timestamp('measured_from')->nullable();
            $table->timestamp('measured_to')->nullable();
            $table->string('timezone', 64)->nullable();
            $table->string('source_app')->nullable();
            $table->string('source_device')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamp('synced_at');
            $table->timestamps();

            $table->unique(['user_id', 'source', 'metric_type', 'external_id'], 'health_records_dedupe');
            $table->index(['user_id', 'metric_type', 'measured_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('health_records');
    }
};
