<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use App\Models\AppSetting;

/**
 * Migration to add new settings fields for the restructured settings pages.
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
        // Insert new settings if they don't exist
        $newSettings = [
            // General Settings
            'device_limit' => '1',
            
            // Popup Settings
            'force_update' => '0',
            'popup_title' => 'Update Available',
            'popup_content' => 'A new version of the app is available. Please update to continue.',
            'app_url' => '',
            
            // Contact Settings
            'telegram_username' => '',
            'contact_email' => '',
            
            // App Settings
            'privacy_policy' => '',
            'terms_conditions' => '',
            'about_us' => '',
            'more_app_url' => '',
            'share_app_url' => '',
            'rate_app_url' => '',
            
            // Ad Settings
            'admob_app_id' => '',
            'admob_native_ad' => '',
            'admob_native_enabled' => '0',
            'admob_banner_ad' => '',
            'admob_banner_enabled' => '0',
            'admob_open_ad' => '',
            'admob_open_enabled' => '0',
            'admob_rewarded_ad' => '',
            'admob_rewarded_enabled' => '0',
            'admob_interstitial_ad' => '',
            'admob_interstitial_enabled' => '0',
        ];

        foreach ($newSettings as $key => $value) {
            AppSetting::firstOrCreate(
                ['key' => $key],
                ['value' => $value]
            );
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        $keysToDelete = [
            'device_limit',
            'force_update',
            'popup_title',
            'popup_content',
            'app_url',
            'telegram_username',
            'contact_email',
            'privacy_policy',
            'terms_conditions',
            'about_us',
            'more_app_url',
            'share_app_url',
            'rate_app_url',
            'admob_app_id',
            'admob_native_ad',
            'admob_native_enabled',
            'admob_banner_ad',
            'admob_banner_enabled',
            'admob_open_ad',
            'admob_open_enabled',
            'admob_rewarded_ad',
            'admob_rewarded_enabled',
            'admob_interstitial_ad',
            'admob_interstitial_enabled',
        ];

        AppSetting::whereIn('key', $keysToDelete)->delete();
    }
};
