<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Models\AppSetting;

class UserController extends Controller
{

    public function register(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string',
                'email' => 'required|email|unique:users',
                'password' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => $validator->errors()], 400);
            }

            $user = new User([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'admin_password' => $request->password,
                'device' => $request->device ?? 1,
            ]);

            $user->save();
            $token = $user->createToken('user_token')->plainTextToken;

           return back()->with('done', '用户添加成功。');
        } catch (\Exception $e) {
            return back()->with('not', '注册失败');
        }
    }

    public function registerUpdate(Request $request, $id)
    {
        $user = User::find($id);
        try{
            $user->name = $user->name;
            $user->email = $request->email;
            $user->password = Hash::make($request->password);
            $user->admin_password = $request->password;
            $user->device = $request->device;
            $user->save();
            return back()->with('done', '用户更新成功。');
        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }

    }

    public function index(Request $request)
    {
        try {

            $users = User::when($request->filled('search'), function ($query) use ($request) {
                $searchTerm = $request->search;
                return $query->where(function ($query) use ($searchTerm) {
                    $query->where('name', 'like', "%$searchTerm%");
                });
            })
                ->latest()->paginate(Helpers::getPaginateSetting());

                $settings = AppSetting::getValues([
                    'device_limit',
                ]);
                // dd($settings);



            return view('admin.all_users',compact('users','settings'));
        } catch (\Exception $e) {
            return back()->with('not', '用户列表获取失败');

        }
    }
    
    public function destroy($id)
    {
        $user = User::find($id);
        if ($user) {
            $user->delete();
             $orders = Order::where('user_id', $id)->first();
            if ($orders) {
                $orders->delete();
            }

            return back()->with('done', '删除成功。');
        } else {
            return back()->with('not', '用户未找到。');
        }
    }

    public function order(Request $request){
        try {
            $orders = Order::when($request->filled('search'), function ($query) use ($request) {
                $searchTerm = $request->search;
                return $query->where(function ($query) use ($searchTerm) {
                    $query->where('name', 'like', "%$searchTerm%")
                          ->orWhere('email', 'like', "%$searchTerm%")
                          ->orWhere('pakage_name', 'like', "%$searchTerm%")
                          ->orWhere('price', 'like', "%$searchTerm%");
                });
            })
            ->latest()
            ->paginate(Helpers::getPaginateSetting());
        
            return view('admin.order', compact('orders'));
        } catch (\Exception $e) {
            return back()->with('not', '订单列表获取失败');
        }
    }

    public function orderCancel($id){
        $order = Order::find($id);
        $order->delete();

        $user = User::find($order->user_id);
            $user->isPremium = 0;
            $user->validity = NULL;
            $user->start_date = NULL;
            $user->expired_date = NULL;
            $user->subscription_id = NULL;
            $user->pakage_name = NULL;
            $user->price = NULL;
            $user->save();

            return back()->with('done', '取消成功。');
    }

    public function orderUpdate(Request $request, $id){
        $order = Order::find($id);
        $order->name = $request->name;
        $order->email = $request->email;
        $order->pakage_name = $request->pakage_name;
        $order->price = $request->price;
        $order->validity = $request->validity;
        $order->expired_date = Carbon::now()->addDays((int)$request->validity);
        $order->status = 'success';
        $order->save();

        $user = User::where('id', $order->user_id)->first();
        $user->isPremium = 1;
        $user->validity = $request->validity;
        $user->subscription_id = $order->id;
        $user->pakage_name = $request->pakage_name;
        $user->price = $request->price;
        $user->start_date = Carbon::now();
        $user->expired_date = Carbon::now()->addDays((int)$request->validity);
        $user->save();
        return back()->with('done', '更新成功。');
    }

    public function userStatus (Request $request, $id)
    {
       

        try {
          
            $user = User::find($id);
            if($user){
               if($request->isPremium == 1){
                   
                     $request->validate([
                'validity' => 'required|integer',
                'price' => 'required|numeric',
                'pakage_name' => 'required|string',
            ]);
                   
               
               if(Order::where('user_id', $id)->exists()){
                   $order = Order::where('user_id', $id)->first();
                   $order->pakage_name = $request->pakage_name;
                   $order->validity = $request->validity;
                   $order->price = $request->price;
                   $order->expired_date = Carbon::now()->addDays((int)$request->validity);
                   $order->save();
               }else {
                $order = Order::create([
                                    'user_id' => $id,
                                    'name' => $user->name,
                                    'email' => $user->email,
                                    'pakage_name' => $request->pakage_name,
                                    'validity' => $request->validity,
                                    'expired_date' => Carbon::now()->addDays((int)$request->validity),
                                    'price' => $request->price,
                                    'status' => 'success',
                                ]);
               }
                

                
                $user->isPremium = 1;
                $user->validity = $request->validity;
                $user->subscription_id = $order->id;
                $user->pakage_name = $request->pakage_name;
                $user->price = $request->price;
                $user->start_date = Carbon::now();
                $user->expired_date = Carbon::now()->addDays((int)$request->validity);
                $user->save();

                return back()->with('done', '订阅成功。');
                }else{
                    
                    $user->isPremium = 0;
                    $user->validity = NULL;
                    $user->start_date = NULL;
                    $user->expired_date = NULL;
                    $user->subscription_id = NULL;
                    $user->pakage_name = NULL;
                    $user->price = NULL;
                    $user->save();
                    return back()->with('done', '取消订阅成功。');
                }
            }
        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }    

    }

}
