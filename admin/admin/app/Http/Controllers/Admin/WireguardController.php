<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\Wireguard;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * Handles CRUD operations for Wireguard VPN servers in the admin panel.
 * 
 * This controller manages the creation, updating, deletion, and status
 * toggling of Wireguard server configurations including VPS credentials.
 */
class WireguardController extends Controller
{
    /**
     * Store a newly created Wireguard server in the database.
     *
     * @param Request $request The incoming HTTP request containing server details
     * @return \Illuminate\Http\RedirectResponse Redirects back with success or error message
     */
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'country_code' => 'required|string|max:10',
                'city_name' => 'required|string|max:100',
                'host' => 'required|string|max:255',
                'port' => 'nullable|integer|min:1|max:65535',
                'vps_username' => 'required|string|max:100',
                'vps_password' => 'required|string|max:255',
                'type' => 'required|in:0,1',
                'link' => 'nullable|string|max:255',
                'address' => 'nullable|string|max:255',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors()->first());
            }

            $server = new Wireguard([
                'name' => $request->input('name'),
                'country_code' => $request->input('country_code'),
                'city_name' => $request->input('city_name'),
                'host' => $request->input('host'),
                'port' => $request->input('port', 22),
                'vps_username' => $request->input('vps_username'),
                'vps_password' => $request->input('vps_password'),
                'type' => $request->input('type'),
                'link' => $request->input('link'),
                'address' => $request->input('address'),
            ]);

            $server->save();

            return back()->with('done', 'Wireguard服务器创建成功');

        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    /**
     * Update the specified Wireguard server in the database.
     *
     * @param Request $request The incoming HTTP request containing updated server details
     * @param int $id The ID of the server to update
     * @return \Illuminate\Http\RedirectResponse Redirects back with success or error message
     */
    public function update(Request $request, $id)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'country_code' => 'required|string|max:10',
                'city_name' => 'required|string|max:100',
                'host' => 'required|string|max:255',
                'port' => 'nullable|integer|min:1|max:65535',
                'vps_username' => 'required|string|max:100',
                'vps_password' => 'nullable|string|max:255',
                'type' => 'required|in:0,1',
                'link' => 'nullable|string|max:255',
                'address' => 'nullable|string|max:255',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors()->first());
            }

            $server = Wireguard::find($id);

            if (!$server) {
                return back()->with('not', '未找到Wireguard服务器');
            }

            $server->name = $request->input('name');
            $server->country_code = $request->input('country_code');
            $server->city_name = $request->input('city_name');
            $server->host = $request->input('host');
            $server->port = $request->input('port', 22);
            $server->vps_username = $request->input('vps_username');
            $server->type = $request->input('type');
            $server->link = $request->input('link');
            $server->address = $request->input('address');
            // Only update password if a new one is provided
            if ($request->filled('vps_password')) {
                $server->vps_password = $request->input('vps_password');
            }

            $server->save();

            return back()->with('done', 'Wireguard服务器更新成功');

        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    /**
     * Remove the specified Wireguard server from the database.
     *
     * @param int $id The ID of the server to delete
     * @return \Illuminate\Http\RedirectResponse Redirects back with success or error message
     */
    public function destroy($id)
    {
        try {
            $server = Wireguard::find($id);

            if (!$server) {
                return back()->with('not', '未找到服务器');
            }

            $server->delete();

            return back()->with('done', 'Wireguard服务器删除成功');

        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    /**
     * Display a paginated listing of Wireguard servers with search functionality.
     *
     * @param Request $request The incoming HTTP request with optional search parameter
     * @return \Illuminate\View\View The view containing the server listing
     */
    public function index(Request $request)
    {
        try {
            $servers = Wireguard::when($request->filled('search'), function ($query) use ($request) {
                    $searchTerm = $request->search;
                    return $query->where(function ($q) use ($searchTerm) {
                        $q->orWhere('name', 'like', "%$searchTerm%")
                        ->orWhere('city_name', 'like', "%$searchTerm%")
                        ->orWhere('country_code', 'like', "%$searchTerm%")
                        ->orWhere('host', 'like', "%$searchTerm%");
                    });
                })
                ->orderBy('id', 'desc')
                ->paginate(Helpers::getPaginateSetting());

            return view('admin.wireguard', compact('servers'));

        } catch (\Exception $e) {
            return back()->with('not', 'Wireguard服务器列表获取失败');
        }
    }

    /**
     * Toggle the status of the specified Wireguard server.
     *
     * @param Request $request The incoming HTTP request containing the new status
     * @param int $id The ID of the server to update
     * @return \Illuminate\Http\JsonResponse JSON response with success or error message
     */
    public function status(Request $request, $id)
    {
        try {
            $server = Wireguard::find($id);

            if (!$server) {
                return response()->json(['error' => '未找到Wireguard'], 404);
            }

            $server->status = $request->status;
            $server->save();

            return response()->json(['success' => 'Wireguard状态更新成功']);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
