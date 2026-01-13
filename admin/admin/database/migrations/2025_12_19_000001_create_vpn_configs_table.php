<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Migration for VPN configurations generated via SSH automation.
 * 
 * This table stores WireGuard configs created by connecting to VPS
 * and running the wireguard-install.sh script automatically.
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('vpn_configs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('client_name', 100);
            $table->string('client_ip', 45)->nullable();
            $table->text('config_content');
            $table->string('download_token', 64)->unique();
            $table->string('server_host', 255);
            $table->string('server_endpoint', 255)->nullable();
            $table->enum('status', ['active', 'expired', 'revoked'])->default('active');
            $table->timestamp('expires_at')->nullable();
            $table->unsignedInteger('download_count')->default(0);
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index('download_token');
            $table->index('client_name');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vpn_configs');
    }
};
