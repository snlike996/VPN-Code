<?php

namespace App\CPU;

use App\Models\AppSetting;
use Carbon\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Session;

class Helpers
{
    public static function percentage($total, $value)
    {
        return ($total > 0) ? round(($value / $total) * 100) : 0;
    }

    public static function make_online()
    {
        $active = Auth::guard('api_users')->user();
        $active->last_seen = Carbon::now();
        $active->save();
    }

    public static function getPaginateSetting()
    {
        if (session()->has('paginate')) {
            return session('paginate');
        } else {
            $setting = AppSetting::where('key', 'paginate')->first();
            if ($setting) {
                session(['paginate' => $setting->value]);

                return $setting->value;
            }

            return null; // or a default value
        }
    }

    public static function getAppLogoSetting()
    {
        if (session()->has('app_logo')) {
            return asset('storage/images/settings/'.session('app_logo'));
        } else {
            $setting = AppSetting::where('key', 'app_logo')->first();
            if ($setting) {
                session(['app_logo' => $setting->value]);

                return asset('storage/images/settings/'.$setting->value);
            }

            return null; // or a default image path
        }
    }

    public static function getShortLogoSetting()
    {
        if (session()->has('short_logo')) {
            return asset('storage/images/settings/'.session('short_logo'));
        } else {
            $setting = AppSetting::where('key', 'short_logo')->first();
            if ($setting) {
                session(['short_logo' => $setting->value]);

                return asset('storage/images/settings/'.$setting->value);
            }

            return null; // or a default image path
        }
    }

    public static function getEnvCredentials()
    {
        $envCredentials = Session::get('env_credentials');

        if (! $envCredentials) {
            // Fetch credentials from the database
            $envCredentials = AppSetting::whereIn('key', [
                'MAIL_DRIVER',
                'MAIL_HOST',
                'MAIL_PORT',
                'MAIL_USERNAME',
                'MAIL_PASSWORD',
                'MAIL_ENCRYPTION',
            ])->pluck('value', 'key')->toArray();

            if (empty($envCredentials)) {
                // If credentials are still empty, fetch from environment variables
                $envCredentials = [
                    'MAIL_DRIVER' => env('MAIL_DRIVER'),
                    'MAIL_HOST' => env('MAIL_HOST'),
                    'MAIL_PORT' => env('MAIL_PORT'),
                    'MAIL_USERNAME' => env('MAIL_USERNAME'),
                    'MAIL_PASSWORD' => env('MAIL_PASSWORD'),
                    'MAIL_ENCRYPTION' => env('MAIL_ENCRYPTION'),
                ];
            }

            // Set credentials in session
            Session::put('env_credentials', $envCredentials);
        }

        return $envCredentials;
    }

    public static function updateEnvCredentials($key, $value)
    {
        $envCredentials = Session::get('env_credentials');

        if ($envCredentials && array_key_exists($key, $envCredentials)) {
            $envCredentials[$key] = $value;
            Session::put('env_credentials', $envCredentials);
            // Update the .env file
            $envFile = base_path('.env');
            if (file_exists($envFile)) {
                file_put_contents($envFile, preg_replace(
                    "/^$key=.*\$/m",
                    "$key=$value",
                    file_get_contents($envFile)
                ));
            }
        }
    }
}
