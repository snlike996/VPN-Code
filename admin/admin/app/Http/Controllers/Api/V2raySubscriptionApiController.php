<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\V2raySubscriptionConfig;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class V2raySubscriptionApiController extends Controller
{
    public function countries(Request $request)
    {
        $countries = Cache::remember('v2ray_subscription_countries', 60, function () {
            return V2raySubscriptionConfig::where('enabled', 1)
                ->orderBy('sort_order')
                ->orderBy('country_name')
                ->get(['country_code', 'country_name']);
        });

        return response()->json($countries);
    }

    public function content(Request $request)
    {
        $user = $request->user();
        if (!$this->hasValidSubscription($user)) {
            return response()->json(['error' => 'Subscription required'], 403);
        }

        $country = strtolower(trim((string) $request->query('country', '')));
        if ($country === '') {
            return response()->json(['error' => 'Country is required'], 400);
        }

        $config = V2raySubscriptionConfig::where('country_code', $country)->first();
        if (!$config) {
            return response()->json(['error' => 'Subscription not found'], 404);
        }
        if (!$config->enabled) {
            return response()->json(['error' => 'Subscription disabled'], 403);
        }

        $cacheKey = "v2ray_subscription_content_{$country}";
        $cacheTtlSeconds = 60;

        try {
            $content = Cache::remember($cacheKey, $cacheTtlSeconds, function () use ($config) {
                $response = Http::timeout(12)->get($config->subscription_url);
                if (!$response->successful()) {
                    throw new \RuntimeException('Upstream subscription fetch failed.');
                }

                return $response->body();
            });
        } catch (\Exception $e) {
            return response()->json(['error' => 'Subscription fetch failed'], 502);
        }

        return response($content, 200, [
            'Content-Type' => 'text/plain; charset=utf-8',
        ]);
    }

    private function hasValidSubscription($user): bool
    {
        if (!$user || (int) $user->isPremium !== 1) {
            return false;
        }

        if (!empty($user->expired_date) && Carbon::parse($user->expired_date)->isPast()) {
            return false;
        }

        return true;
    }
}
