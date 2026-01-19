<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\V2raySubscriptionConfig;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\Rule;

class V2raySubscriptionController extends Controller
{
    public function index()
    {
        $subscriptions = V2raySubscriptionConfig::orderBy('sort_order')
            ->orderBy('country_name')
            ->get();

        return view('admin.v2ray_subscription.index', compact('subscriptions'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'country_code' => ['required', 'string', 'max:8'],
            'country_name' => ['required', 'string', 'max:32'],
            'subscription_url' => ['required', 'url', 'max:2048'],
            'enabled' => ['nullable', 'boolean'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'remark' => ['nullable', 'string', 'max:255'],
        ]);

        $countryCode = strtolower(trim($validated['country_code']));
        $enabled = $request->boolean('enabled');
        $sortOrder = $validated['sort_order'] ?? 0;

        V2raySubscriptionConfig::updateOrCreate(
            ['country_code' => $countryCode],
            [
                'country_name' => $validated['country_name'],
                'subscription_url' => $validated['subscription_url'],
                'enabled' => $enabled,
                'sort_order' => $sortOrder,
                'remark' => $validated['remark'] ?? null,
            ]
        );

        Cache::forget('v2ray_subscription_countries');
        Cache::forget("v2ray_subscription_content_{$countryCode}");

        return back()->with('success', 'V2Ray 订阅配置已保存。');
    }

    public function delete(Request $request)
    {
        $validated = $request->validate([
            'country_code' => ['required', 'string', 'max:8'],
        ]);

        $countryCode = strtolower(trim($validated['country_code']));
        V2raySubscriptionConfig::where('country_code', $countryCode)->delete();

        Cache::forget('v2ray_subscription_countries');
        Cache::forget("v2ray_subscription_content_{$countryCode}");

        return back()->with('success', 'V2Ray 订阅配置已删除。');
    }
}
