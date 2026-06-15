<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('role', 16)->default('user')->after('password');
            $table->integer('points_balance')->default(0);
            $table->unsignedInteger('level')->default(1);
            $table->unsignedInteger('streak_days')->default(0);
            $table->string('profile_status')->default('Actief');
            $table->string('active_character_key')->default('directions_run');
            $table->json('settings')->nullable();
        });

        Schema::create('challenges', function (Blueprint $table): void {
            $table->id();
            $table->string('slug')->unique();
            $table->string('title');
            $table->text('description');
            $table->string('icon_key')->default('trophy');
            $table->string('difficulty', 32)->default('Beginner');
            $table->string('type', 32);
            $table->string('metric_type', 64)->nullable();
            $table->decimal('target_value', 18, 3)->default(1);
            $table->string('unit', 32)->nullable();
            $table->string('activity_type', 64)->nullable();
            $table->unsignedInteger('min_workout_seconds')->nullable();
            $table->unsignedInteger('points');
            $table->boolean('is_quick')->default(false);
            $table->boolean('active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->json('instructions')->nullable();
            $table->timestamps();
        });

        Schema::create('challenge_assignments', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('challenge_id')->constrained()->cascadeOnDelete();
            $table->string('status', 24)->default('started');
            $table->decimal('progress', 18, 3)->default(0);
            $table->decimal('target_value', 18, 3);
            $table->boolean('is_demo')->default(false);
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'challenge_id']);
        });

        Schema::create('point_transactions', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('idempotency_key')->unique();
            $table->integer('amount');
            $table->string('reason');
            $table->nullableMorphs('reference');
            $table->boolean('is_demo')->default(false);
            $table->json('metadata')->nullable();
            $table->timestamps();
        });

        Schema::create('shop_items', function (Blueprint $table): void {
            $table->id();
            $table->string('slug')->unique();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('icon_key');
            $table->string('category', 32);
            $table->unsignedInteger('points_cost')->default(0);
            $table->string('requirement')->nullable();
            $table->boolean('active')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('shop_item_user', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('shop_item_id')->constrained()->cascadeOnDelete();
            $table->timestamp('purchased_at');
            $table->timestamps();
            $table->unique(['user_id', 'shop_item_id']);
        });

        Schema::create('friendships', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('requester_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('addressee_id')->constrained('users')->cascadeOnDelete();
            $table->string('status', 24)->default('pending');
            $table->timestamp('accepted_at')->nullable();
            $table->timestamps();
            $table->unique(['requester_id', 'addressee_id']);
        });

        Schema::create('messages', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('recipient_id')->constrained('users')->cascadeOnDelete();
            $table->text('body');
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
            $table->index(['sender_id', 'recipient_id', 'created_at']);
        });

        Schema::create('teams', function (Blueprint $table): void {
            $table->id();
            $table->string('name')->unique();
            $table->text('description')->nullable();
            $table->unsignedInteger('points')->default(0);
            $table->timestamps();
        });

        Schema::create('team_user', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role', 24)->default('member');
            $table->timestamps();
            $table->unique(['team_id', 'user_id']);
        });

        Schema::create('achievements', function (Blueprint $table): void {
            $table->id();
            $table->string('slug')->unique();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('icon_key');
            $table->boolean('active')->default(true);
            $table->timestamps();
        });

        Schema::create('achievement_user', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('achievement_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->timestamp('earned_at');
            $table->timestamps();
            $table->unique(['achievement_id', 'user_id']);
        });

        Schema::create('audit_logs', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action');
            $table->nullableMorphs('auditable');
            $table->json('payload')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('achievement_user');
        Schema::dropIfExists('achievements');
        Schema::dropIfExists('team_user');
        Schema::dropIfExists('teams');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('friendships');
        Schema::dropIfExists('shop_item_user');
        Schema::dropIfExists('shop_items');
        Schema::dropIfExists('point_transactions');
        Schema::dropIfExists('challenge_assignments');
        Schema::dropIfExists('challenges');

        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn([
                'role', 'points_balance', 'level', 'streak_days', 'profile_status',
                'active_character_key', 'settings',
            ]);
        });
    }
};
