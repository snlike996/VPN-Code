<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\Server;
use App\Models\V2raySubscriptionConfig;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AdminController extends Controller
{
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }

        try {
            $credentials = $request->only('email', 'password');
            if (Auth::guard('admins')->attempt($credentials)) {
                // Authentication passed...
                return redirect()->route('admin.dashboard');
            } else {
                return redirect()->back()->withErrors(['error' => '凭证无效'])->withInput();
            }
        } catch (Exception $e) {
            // Log the error or handle it as required
            return redirect()->back()->withErrors(['error' => '发生错误'])->withInput();
        }
    }

    public function logout()
    {

        Auth::guard('admins')->logout();

        return redirect('/');
    }

    public function profile()
    {
        $admin = Auth::guard('admins')->user();
        $servers = V2raySubscriptionConfig::count();

        return view('admin.profile', compact('admin', 'servers'));
    }

    public function update(Request $request)
    {
        try {
            $user = Admin::find(Auth::guard('admins')->user()->id);

            if (! $user) {
                return back()->with('error', '未找到管理员');
            }

            $validator = Validator::make($request->all(), [
                'name' => 'string',
                'email' => 'email',
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => $validator->errors()], 400);
            }

            $user->name = $request->input('name') ?? $user->name;
            $user->email = $request->input('email') ?? $user->email;
            $user->save();

            return back()->with('update', '信息更新成功');
        } catch (\Exception $e) {
            return back()->with('error', '更新失败');
        }
    }

    public function changePassword(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'current_password' => 'required|string',
                'new_password' => 'required|string|min:6',
            ]);

            if ($validator->fails()) {
                return back()->with('unchanged', $validator->errors());
            }

            $user = Admin::find(Auth::guard('admins')->user()->id);
            if (! Hash::check($request->current_password, $user->password)) {
                return back()->with('unchanged', '当前密码不正确');
            }

            $user->password = Hash::make($request->new_password);
            $user->save();

            return back()->with('changed', '密码更新成功');
        } catch (\Exception $e) {
            return back()->with('unchanged', '密码修改失败');
        }
    }
}
