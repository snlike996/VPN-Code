<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\AppSetting;
use App\Models\OpenConnect;
use App\Models\V2raySubscriptionConfig;

class DashBoardController extends Controller
{
    public function index()
    {
        $v2rayServers = V2raySubscriptionConfig::count();
        $openconnectServers = OpenConnect::count();
        $activeUsers = User::activeUsers()->count();
        $users = User::count();
        $subscriptions = User::where('isPremium', 1)->count();

        $registeredUsersCount = User::registeredUsersCountLast30Days();
        $activeUsersCount = User::activeUsersCountLast1Hour();
        $registeredUsersPercentage = User::registeredUsersPercentageLast30Days();
        $activeUsersPercentage = User::activeUsersPercentageLast1Hour();
        
        $totalRevenue = Order::sum('price');

        $settings = AppSetting::getValues([
            'v2ray_status',
            'openconnect_status'
        ]);
        
        $unions = [];
        
        if ($settings['openconnect_status'] == 1) {
            $unions[] = "
                SELECT id, name, active_count, 'openconnect' AS protocol
                FROM open_connects
                WHERE status = 1
            ";
        }
        
        if ($settings['v2ray_status'] == 1) {
            $unions[] = "
                SELECT id, name, active_count, 'v2ray' AS protocol
                FROM v2rays
                WHERE status = 1
            ";
        }
        
        if (empty($unions)) {
            $topFive = collect(); // no active providers
        } else {
            $sql = implode(" UNION ALL ", $unions);
        
            $topFive = DB::table(DB::raw("($sql) AS all_servers"))
                ->orderBy('active_count', 'DESC')
                ->limit(5)
                ->get();
        }
        
        $counts = [
            'users' => $users,
            'subscriptions' => $subscriptions,
            'activeUsers' => $activeUsers,
            'registeredUsersCount' => $registeredUsersCount,
            'registeredUsersPercentage' => $registeredUsersPercentage,
            'activeUsers1hrCount' => $activeUsersCount,
            'activeUsers1hrPercentage' => $activeUsersPercentage,
            'v2rayServers' => $v2rayServers,
            'openconnectServers' => $openconnectServers,
            'totalRevenue' => $totalRevenue,
            'topServerUsers' => $topFive,
        ];

        return view('dashboard', compact('counts'));
    }

    public function users(Request $request)
    {
        $online = User::when($request->filled('search'), function ($query) use ($request) {
            $searchTerm = $request->search;

            return $query->where(function ($query) use ($searchTerm) {
                $query->where('email', 'like', "%$searchTerm%")
                    ->orWhere('name', 'like', "%$searchTerm%");
            });
        })
            ->latest()->paginate(10);

        return view('users', compact('online'));
    }
}
