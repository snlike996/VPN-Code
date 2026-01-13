<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\Server;
use App\Models\V2ray;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class V2rayController extends Controller
{
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string',
                'link' => 'string|required',
                'country_code' => 'string|required',
                'city_name' => 'string|required',
                'type' => 'string|required',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors());
            }

            $server = new V2ray([
                'name' => $request->input('name'),
                'country_code' => $request->input('country_code'),
                'city_name' => $request->input('city_name'),
                'link' => $request->input('link'),
                'type' => $request->input('type'),
            ]);

            $server->save();

            return back()->with('done', 'V2ray服务器创建成功');

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
                'type' => 'string|required',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors());
            }
            $server = V2ray::find($id);

            if (! $server) {
                return response()->json(['error' => '未找到V2ray服务器'], 404);
            }

            $server->name = $request->input('name', $server->name);
            $server->country_code = $request->input('country_code', $server->country_code);
            $server->city_name = $request->input('city_name', $server->city_name);
            $server->link = $request->input('link', $server->link);
            $server->type = $request->input('type', $server->type);

     

            $server->save();

            return back()->with('done', 'V2ray服务器更新成功');
        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    public function destroy($id)
    {
        try {
            $server = V2ray::find($id);

            if (! $server) {
                return response()->json(['error' => '未找到服务器'], 404);
            }

            $server->delete();

            return back()->with('done', 'V2ray服务器删除成功');

        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    public function index(Request $request)
{
    try {
        $servers = V2ray::when($request->filled('search'), function ($query) use ($request) {
            $searchTerm = $request->search;

            return $query->where(function ($q) use ($searchTerm) {
                $q->where('name', 'like', "%$searchTerm%")
                  ->orWhere('link', 'like', "%$searchTerm%")
                  ->orWhere('country_code', 'like', "%$searchTerm%")
                  ->orWhere('city_name', 'like', "%$searchTerm%");
            });
        })
        ->orderBy('id', 'desc') // 👈 newest first
        ->paginate(Helpers::getPaginateSetting());

        return view('admin.v2ray', compact('servers'));
    } catch (\Exception $e) {
        return back()->with('not', 'V2ray服务器列表获取失败');
    }
}


    public function status(Request $request, $id)
    {
        try {
            $server = V2ray::find($id);
    
            if (! $server) {
                return response()->json(['error' => '未找到V2ray'], 404);
            }
    
            $server->status = $request->status;
            $server->save();
    
            return response()->json(['success' => 'V2ray状态更新成功']);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
