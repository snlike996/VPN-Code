<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SingboxSubscription;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SingboxSubscriptionController extends Controller
{
    public function index()
    {
        $subscriptions = SingboxSubscription::orderBy('priority')
            ->orderBy('name')
            ->get();

        return view('admin.singbox_subscription.index', compact('subscriptions'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'id' => ['nullable', 'integer'],
            'name' => ['required', 'string', 'max:64'],
            'platform' => ['nullable', 'string', 'max:16'],
            'content_type' => ['required', Rule::in(['config_json', 'subscription_url'])],
            'config_content' => [
                Rule::requiredIf(fn () => $request->input('content_type') === 'config_json'),
                'nullable',
                'string',
            ],
            'subscription_url' => [
                Rule::requiredIf(fn () => $request->input('content_type') === 'subscription_url'),
                'nullable',
                'url',
                'max:2048',
            ],
            'enabled' => ['nullable', 'boolean'],
            'priority' => ['nullable', 'integer', 'min:0'],
        ]);

        $platform = strtolower(trim($validated['platform'] ?? 'windows'));
        $enabled = $request->boolean('enabled');
        $priority = $validated['priority'] ?? 0;

        $subscription = null;
        if (!empty($validated['id'])) {
            $subscription = SingboxSubscription::find($validated['id']);
        }
        if ($subscription === null) {
            $subscription = new SingboxSubscription();
        }

        $subscription->fill([
            'name' => $validated['name'],
            'platform' => $platform,
            'content_type' => $validated['content_type'],
            'config_content' => $validated['content_type'] === 'config_json'
                ? $validated['config_content']
                : null,
            'subscription_url' => $validated['content_type'] === 'subscription_url'
                ? $validated['subscription_url']
                : null,
            'enabled' => $enabled,
            'priority' => $priority,
        ]);
        $subscription->save();

        return back()->with('success', 'Sing-box 订阅配置已保存。');
    }

    public function delete(Request $request)
    {
        $validated = $request->validate([
            'id' => ['required', 'integer'],
        ]);

        SingboxSubscription::where('id', $validated['id'])->delete();

        return back()->with('success', 'Sing-box 订阅配置已删除。');
    }
}
