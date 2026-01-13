<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\OpenVpn;
use App\Models\Server;
use App\Models\V2ray;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class OpenvpnController extends Controller
{
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string',
                'link' => 'string|required',
                'country_code' => 'string|required',
                'city_name' => 'string|required',
                'username' => 'string|required',
                'password' => 'string|required',
                'type' => 'string|required',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors());
            }

            $server = new OpenVpn([
                'name' => $request->input('name'),
                'country_code' => $request->input('country_code'),
                'city_name' => $request->input('city_name'),
                'link' => $request->input('link'),
                'username' => $request->input('username'),
                'password' => $request->input('password'),
                'type' => $request->input('type'),
            ]);

            $server->save();
            $token = $user->createToken('user_token')->plainTextToken;

           return back()->with('done', 'OpenVpn创建成功');
        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());

        }
    }

    public function update(Request $request, $id)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string',
                'link' => 'string|required',
                'country_code' => 'string|required',
                'city_name' => 'string|required',
                'username' => 'string|required',
                'password' => 'string|required',
                'type' => 'string|required',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors());
            }
            $server = OpenVpn::find($id);

            if (! $server) {
                return response()->json(['error' => '未找到OpenVpn服务器'], 404);
            }

            $server->name = $request->input('name', $server->name);
            $server->country_code = $request->input('country_code', $server->country_code);
            $server->city_name = $request->input('city_name', $server->city_name);
            $server->link = $request->input('link', $server->link);
            $server->username = $request->input('username', $server->username);
            $server->password = $request->input('password', $server->password);
            $server->type = $request->input('type', $server->type);
            $server->save();

            return back()->with('done', 'OpenVpn服务器更新成功');
        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    public function destroy($id)
    {
        try {
            $server = OpenVpn::find($id);

            if (! $server) {
                return response()->json(['error' => '未找到服务器'], 404);
            }

            $server->delete();

            return back()->with('done', 'OpenVpn服务器删除成功');

        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    public function index(Request $request)
{
    try {
        $servers = OpenVpn::query()
            ->when($request->filled('search'), function ($query) use ($request) {
                $searchTerm = $request->search;
                $query->where(function ($q) use ($searchTerm) {
                    $q->where('name', 'like', "%$searchTerm%")
                        ->orWhere('city_name', 'like', "%$searchTerm%")
                        ->orWhere('country_code', 'like', "%$searchTerm%")
                        ->orWhere('username', 'like', "%$searchTerm%")
                        ->orWhere('password', 'like', "%$searchTerm%");
                });
            })
            ->orderBy('id', 'desc') // 👈 newest first
            ->paginate(Helpers::getPaginateSetting());

        return view('admin.openvpn', compact('servers'));
    } catch (\Exception $e) {
        return back()->with('not', 'OpenVpn服务器列表获取失败');
    }
}

    

    public function status(Request $request, $id)
    {
        try {
            $server = OpenVpn::find($id);
    
            if (! $server) {
                return response()->json(['error' => '未找到OpenVpn'], 404);
            }
    
            $server->status = $request->status;
            $server->save();
    
            return response()->json(['success' => 'OpenVpn状态更新成功']);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
