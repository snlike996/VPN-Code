<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Adds VPS credential columns to the wireguards table for SSH connectivity.
 * 
 * This migration adds the necessary fields to store VPS connection details
 * (host, port, username, password) and removes deprecated link/address fields.
 */
return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table('wireguards', function (Blueprint $table) {
            // Add new VPS credential columns if they don't exist
            if (!Schema::hasColumn('wireguards', 'host')) {
                $table->string('host')->nullable()->after('type');
            }
            
            if (!Schema::hasColumn('wireguards', 'port')) {
                $table->integer('port')->default(22)->after('host');
            }
            
            if (!Schema::hasColumn('wireguards', 'vps_username')) {
                $table->string('vps_username')->nullable()->after('port');
            }
            
            if (!Schema::hasColumn('wireguards', 'vps_password')) {
                $table->string('vps_password')->nullable()->after('vps_username');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        Schema::table('wireguards', function (Blueprint $table) {
            $table->dropColumn(['host', 'port', 'vps_username', 'vps_password']);
        });
    }
};
