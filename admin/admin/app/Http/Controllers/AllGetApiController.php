<?php

namespace App\Http\Controllers;

use App;
use App\Models\Admob;
use App\Models\AppSetting;
use App\Models\Ikev;
use App\Models\Ikev2;
use App\Models\OpenVpn;
use App\Models\Sstp;
use App\Models\V2ray;
use App\Models\Wireguard;
use Illuminate\Http\Request;
use Exception;

class AllGetApiController extends Controller
{

    public function v2ray(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = V2ray::where('status', 1)->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'V2ray server list retrieval failed'], 200);
        }
    }

     public function v2ray_free(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = V2ray::where(['status'=> 1, 'type' => '0'])->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'V2ray server list retrieval failed'], 200);
        }
    }
     public function v2ray_premium(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = V2ray::where(['status'=> 1, 'type' => '1'])->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'V2ray server list retrieval failed'], 200);
        }
    }

    public function v2ray_search(Request $request)
    {
        try {
            $query = V2ray::query();
            $query->where('status', 1);     
            // input search (case-insensitive)
            if ($request->filled('search_text')) {
                $q = strtolower($request->search_text);

                $query->where(function ($sub) use ($q) {
                    $sub->whereRaw('LOWER(name) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(country_code) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(city_name) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(link) LIKE ?', ["%{$q}%"]);
                });
            }

            // select search (type only, case-insensitive)
            if ($request->filled('type')) {
                $query->whereRaw('LOWER(type) = ?', [strtolower($request->type)]);
            }

            $results = $query->get();

            return response()->json([
                'success' => true,
                'data' => $results,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 200);
        }
    }
    public function openvpn(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = OpenVpn::where('status', 1)->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'OpenVpn server list retrieval failed'], 200);
        }
    }

    public function openvpn_free(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = OpenVpn::where(['status'=> 1, 'type' => '0'])->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'OpenVpn server list retrieval failed'], 200);
        }
    }
    public function openvpn_premium(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = OpenVpn::where(['status'=> 1, 'type' => '1'])->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'OpenVpn server list retrieval failed'], 200);
        }
    }

    public function openvpn_search(Request $request)
    {
        try {
            $query = OpenVpn::query();
            $query->where('status', 1);
            // input search (case-insensitive)
            if ($request->filled('search_text')) {
                $q = strtolower($request->search_text);

                $query->where(function ($sub) use ($q) {
                    $sub->whereRaw('LOWER(name) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(country_code) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(city_name) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(link) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(username) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(password) LIKE ?', ["%{$q}%"]);
                });
            }

            // select search (type only, case-insensitive)
            if ($request->filled('type')) {
                $query->whereRaw('LOWER(type) = ?', [strtolower($request->type)]);
            }

            $results = $query->get();

            return response()->json([
                'success' => true,
                'data' => $results,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 200);
        }
    }
    public function wireguard(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = Wireguard::where('status', 1)->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Wireguard server list retrieval failed'], 200);
        }
    }
    public function wireguard_free(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = Wireguard::where(['status'=> 1, 'type' => '0'])->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Wireguard server list retrieval failed'], 200);
        }
    }
    public function wireguard_premium(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);
            $servers = Wireguard::where(['status'=> 1, 'type' => '1'])->paginate($perPage);

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Wireguard server list retrieval failed'], 200);
        }
    }
    public function wireguard_search(Request $request)
    {
        try {
            $query = Wireguard::query();
            $query->where('status', 1);

            // input search (case-insensitive)
            if ($request->filled('search_text')) {
                $q = strtolower($request->search_text);

                $query->where(function ($sub) use ($q) {
                    $sub->whereRaw('LOWER(name) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(country_code) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(link) LIKE ?', ["%{$q}%"])
                        ->orWhereRaw('LOWER(address) LIKE ?', ["%{$q}%"]);
                });
            }

            // select search (type only, case-insensitive)
            if ($request->filled('type')) {
                $query->whereRaw('LOWER(type) = ?', [strtolower($request->type)]);
            }

            $results = $query->get();

            return response()->json([
                'success' => true,
                'data' => $results,
            ], 200);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
            ], 200);
        }
    }


    public function setting()
    {
        try {
            $setting = AppSetting::pluck('value', 'key'); // returns key => value
            return response()->json($setting);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Setting list retrieval failed'], 200);
        }
    }
    public function general_setting()
    {
        try {
            $settings = AppSetting::getValues([
                'wireguard_status',
                'v2ray_status',
                'openvpn_status',
                'openconnect_status',
                'paginate',
                'app_logo',
                'short_logo',
                'device_limit',
                'default_protocol',
                'ads_click',
                'ads_setting',
            ]);
            return response()->json($settings);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Setting list retrieval failed'], 200);
        }
    }
    public function popup_setting()
    {
        try {
            $settings = AppSetting::getValues([
                'app_version',
                'force_update',
                'popup_title',
                'popup_content',
                'app_url',
            ]);
            return response()->json($settings);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Setting list retrieval failed'], 200);
        }
    }
    public function contact_setting()
    {
        try {
            $settings = AppSetting::getValues([
                'telegram_username',
                'contact_email',
            ]);
            return response()->json($settings);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Setting list retrieval failed'], 200);
        }
    }
    public function app_setting()
    {
        try {
            $settings = AppSetting::getValues([
            'privacy_policy',
            'terms_conditions',
            'about_us',
            'more_app_url',
            'share_app_url',
            'rate_app_url',
            ]);
            return response()->json($settings);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Setting list retrieval failed'], 200);
        }
    }
    public function admob_setting()
    {
        try {
            $settings = AppSetting::getValues([
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
            ]);
            return response()->json($settings);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Setting list retrieval failed'], 200);
        }
    }
    public function facebook_ads_setting()
    {
        try {
            $settings = AppSetting::getValues([
            'facebook_app_id',
            'facebook_native_ad',
            'facebook_native_enabled',
            'facebook_banner_ad',
            'facebook_banner_enabled',
            'facebook_open_ad',
            'facebook_open_enabled',
            'facebook_rewarded_ad',
            'facebook_rewarded_enabled',
            'facebook_interstitial_ad',
            'facebook_interstitial_enabled',
            ]);
            return response()->json($settings);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Setting list retrieval failed'], 200);
        }
    }

    public function all(Request $request)
    {
        try {
            $perPage = $request->input('paginate', 10000);

            $search = strtolower($request->input('search_text', ''));
            $type   = strtolower($request->input('type', ''));

            // Reusable filter closure
            $applyFilters = function ($query) use ($search, $type) {
                if ($search) {
                    $query->where(function ($sub) use ($search) {
                        $sub->whereRaw('LOWER(name) LIKE ?', ["%{$search}%"])
                            ->orWhereRaw('LOWER(country_code) LIKE ?', ["%{$search}%"])
                            ->orWhereRaw('LOWER(city_name) LIKE ?', ["%{$search}%"]);
                    });
                }

                if ($type) {
                    $query->whereRaw('LOWER(type) = ?', [$type]);
                }
            };

            $servers = [
                'v2ray'     => V2ray::where('status', 1)->tap($applyFilters)->paginate($perPage),
                'openvpn'   => OpenVpn::where('status', 1)->tap($applyFilters)->paginate($perPage),
                'wireguard' => Wireguard::where('status', 1)->tap($applyFilters)->paginate($perPage),
            ];

            return response()->json($servers);
        } catch (\Exception $e) {
            return response()->json([
                'error'   => 'Server list retrieval failed',
                'message' => $e->getMessage()
            ], 500);
        }
    }

    private function getModelByProtocol($protocol)
{
    return match ($protocol) {
        'wireguard' => \App\Models\Wireguard::class,
        'v2ray'     => \App\Models\V2ray::class,
        'openvpn'   => \App\Models\OpenVpn::class,
        'openconnect' => \App\Models\OpenConnect::class,
        default     => null
    };
}
public function server_connect(Request $request)
{
    $request->validate([
        'server_id' => 'required|integer',
        'protocol'  => 'required|string'
    ]);

    $model = $this->getModelByProtocol($request->protocol);

    if (!$model) {
        return response()->json(['error' => 'Invalid protocol'], 400);
    }

    // Fetch server
    $server = $model::find($request->server_id);

    if (!$server) {
        return response()->json(['error' => 'Server not found'], 404);
    }

    // increment active_count safely
    $server->increment('active_count');

    return response()->json([
        'message' => 'Connected successfully',
        'active_count' => $server->active_count
    ]);
}

public function server_disconnect(Request $request)
{
    $request->validate([
        'server_id' => 'required|integer',
        'protocol'  => 'required|string'
    ]);

    $model = $this->getModelByProtocol($request->protocol);

    if (!$model) {
        return response()->json(['error' => 'Invalid protocol'], 400);
    }

    $server = $model::find($request->server_id);

    if (!$server) {
        return response()->json(['error' => 'Server not found'], 404);
    }

    // Prevent negative values
    if ($server->active_count > 0) {
        $server->decrement('active_count');
    }

    return response()->json([
        'message' => 'Disconnected successfully',
        'active_count' => $server->active_count
    ]);
}

 

}
