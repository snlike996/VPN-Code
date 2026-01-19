<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\OpenConnect;
use App\Models\V2ray;
use Illuminate\Http\Request;
use App\Models\AppSetting;

class ActiveConnectionsController extends Controller
{
    public function index(Request $request)
    {
        try {
            $protocolFilter = $request->input('protocol', 'all');
            $searchTerm = $request->input('search', '');

            $settings = AppSetting::getValues(['v2ray_status', 'openconnect_status']);
            // dd($settings['wireguard_status']);

            $connections = collect();

            if (($protocolFilter === 'all' || $protocolFilter === 'openconnect') && $settings['openconnect_status'] == 1) {
                $openconnects = OpenConnect::where('status', 1)
                    ->when($searchTerm, function ($query) use ($searchTerm) {
                        return $query->where(function ($q) use ($searchTerm) {
                            $q->where('name', 'like', "%$searchTerm%")
                                ->orWhere('link', 'like', "%$searchTerm%");
                        });
                    })
                    ->get()
                    ->map(function ($item) {
                        return [
                            'id' => $item->id,
                            'name' => $item->name,
                            'active_count' => $item->active_count,
                            'protocol' => 'openconnect',
                            'created_at' => $item->created_at,
                        ];
                    });
                $connections = $connections->merge($openconnects);
            }

            // Get V2ray connections
            if (($protocolFilter === 'all' || $protocolFilter === 'v2ray') && $settings['v2ray_status'] == 1) {
                $v2rays = V2ray::where('status', 1)
                    ->when($searchTerm, function ($query) use ($searchTerm) {
                        return $query->where(function ($q) use ($searchTerm) {
                            $q->where('name', 'like', "%$searchTerm%")
                                ->orWhere('link', 'like', "%$searchTerm%");
                        });
                    })
                    ->get()
                    ->map(function ($item) {
                        return [
                            'id' => $item->id,
                            'name' => $item->name,
                            'active_count' => $item->active_count,
                            'protocol' => 'v2ray',
                            'created_at' => $item->created_at,
                        ];
                    });
                $connections = $connections->merge($v2rays);
            }

            // Sort by created_at descending
            $connections = $connections->sortByDesc('active_count');

            // Paginate manually
            $perPage = Helpers::getPaginateSetting() ?? 10;
            $currentPage = $request->input('page', 1);
            $items = $connections->forPage($currentPage, $perPage);
            $paginator = new \Illuminate\Pagination\LengthAwarePaginator(
                $items,
                $connections->count(),
                $perPage,
                $currentPage,
                ['path' => $request->url(), 'query' => $request->query()]
            );

            return view('admin.activeConnections', [
                'connections' => $paginator,
                'protocolFilter' => $protocolFilter,
                'searchTerm' => $searchTerm,
            ]);
        } catch (\Exception $e) {
            return back()->with('not', '活跃连接获取失败: ' . $e->getMessage());
        }
    }
}
