<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SingboxSubscription;
use Illuminate\Http\Request;

class SingboxConfigApiController extends Controller
{
    public function index(Request $request)
    {
        $configs = SingboxSubscription::where('enabled', 1)
            ->whereIn('platform', ['windows', 'common'])
            ->orderBy('priority')
            ->orderBy('id')
            ->get()
            ->map(function (SingboxSubscription $item) {
                return [
                    'id' => $item->id,
                    'name' => $item->name,
                    'type' => $item->content_type,
                    'content' => $item->content_type === 'subscription_url'
                        ? $item->subscription_url
                        : $item->config_content,
                    'priority' => $item->priority,
                ];
            })
            ->values();

        return response()->json([
            'configs' => $configs,
        ]);
    }
}
