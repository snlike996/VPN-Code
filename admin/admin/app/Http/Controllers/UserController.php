<?php

namespace App\Http\Controllers;

use App\Models\Order;
use App\Models\Package;
use App\Models\SubscriptionPlan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;
use Carbon\Carbon;
use Google\Service\AnalyticsHub\Subscription;
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
                return response()->json(['error' => $validator->errors()], 200);
            }

            $settings = AppSetting::getValues([
                'device_limit',
            ]);

            $user = new User([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'admin_password' => $request->password,
                'device' =>  $settings['device_limit'] ?? 1,
            ]);

            $user->save();
            $token = $user->createToken('user_token')->plainTextToken;

            return response()->json([
                'message' => '注册成功',
                'token' => $token,
            ], 201);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 200);
        }
    }

    public function login(Request $request)
{
    try {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
            'device_id' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['error' => $validator->errors()], 200);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['error' => '未授权'], 200);
        }

        $limit = $user->device; // max allowed devices
        $deviceText = $limit === 1 ? '设备' : '设备';

        // Get unique device IDs for this user
        $existingDevices = $user->tokens()->where('name','device_token')->select('device_id')->distinct()->pluck('device_id');

        if (!$existingDevices->contains($request->device_id)) {
            // New device logging in — check if limit reached
            if ($existingDevices->count() >= $limit) {
                return response()->json([
                    'error' => "您已达到最大 $deviceText 限制 ($limit)。"
                ], 403);
            }
        } else {
            // Existing device — revoke old token so we can create a new one
            $user->tokens()->where('device_id', $request->device_id)->delete();
        }

        // Create new token with device_id attached
        $token = $user->createToken('device_token');
        $token->accessToken->device_id = $request->device_id;
        $token->accessToken->save();

        return response()->json([
            'message' => '登录成功',
            'token' => $token->plainTextToken,
        ]);
    } catch (\Exception $e) {
        return response()->json(['error' => '登录失败'], 200);
    }
}





    public function update(Request $request, $id)
    {
        try {
            $user = User::find($id);

            if (! $user) {
                return response()->json(['error' => 'User not found'], 200);
            }

            $validator = Validator::make($request->all(), [
                'name' => 'string',
                'email' => 'email|unique:users,email,'.$id,
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => $validator->errors()], 200);
            }

            $user->name = $request->input('name');
            $user->email = $request->input('email');
            $user->subscription_id = $request->input('subscription_id') ? $request->input('subscription_id') : $user->subscription_id;
            $user->isPremium = $request->input('isPremium') ? $request->input('isPremium') : $user->isPremium;
            $user->isSuspended = $request->input('isSuspended') ? $request->input('isSuspended') : $user->isSuspended;
            $user->save();

            return response()->json(['message' => 'User updated successfully', 'user' => $user], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Update failed'], 200);
        }
    }

    public function destroy($id)
    {
        try {
            $user = User::find($id);

            if (! $user) {
                return response()->json(['error' => 'User not found'], 200);
            }

            $user->delete();

            $orders = Order::where('user_id', $id)->first();
            if ($orders) {
                $orders->delete();
            }

            return response()->json(['message' => 'User deleted successfully'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Deletion failed'], 200);
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
                return response()->json(['error' => $validator->errors()], 200);
            }

            $user = Auth::user();
            if (! Hash::check($request->current_password, $user->password)) {
                return response()->json(['error' => 'Current password is incorrect'], 200);
            }

            $user->password = Hash::make($request->new_password);
            $user->save();

            return response()->json(['message' => 'Password changed successfully'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Password change failed'], 200);
        }
    }

    public function logout()
    {
        try {
            Auth::guard('api_users')->user()->tokens()->delete();

            return response()->json(['message' => 'Logout successful'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Logout failed'], 200);
        }
    }

    public function index(Request $request)
    {
        try {

            $users = User::all();

            return response()->json($users, 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'User list retrieval failed'], 200);
        }
    }

    public function show($id)
    {
        try {
            $user = User::find($id);

            if (! $user) {
                return response()->json(['error' => 'User not found'], 200);
            }

            return response()->json($user, 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'User retrieval failed'], 200);
        }
    }
    public function sendResetLink(Request $request)
    {
                                                                           
        $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $status = Password::sendResetLink($request->only('email'));

        if ($status === Password::RESET_LINK_SENT) {
            return response()->json(['message' => __($status)], 200);
        }

        throw ValidationException::withMessages([
            'email' => [__($status)],
        ]);
    }

    // Reset the password
    public function resetPassword(Request $request)
    {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email|exists:users,email',
            'password' => 'required|min:6|confirmed',
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, $password) {
                $user->forceFill([
                    'password' => Hash::make($password),
                ])->save();
            }
        );
        
        if ($status === Password::PASSWORD_RESET) {
            return response()->json(['message' => __($status)], 200);
        }else{
            return response()->json(['error' => __($status)], 200);
        }

        throw ValidationException::withMessages([
            'email' => [__($status)],
        ]);
    }

    public function subscriptionPackeges()
    {
        try {
            $packeges = SubscriptionPlan::get();
            return response()->json($packeges, 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Packeges list retrieval failed'], 200);
        }
    }
    public function orderStore(Request $request){

        try {
            $request->validate([
                'package_name' => 'required',
                'validity' => 'required',
                'price' => 'required',
                
            ]);
            if (Order::where('user_id', Auth::id())->exists()) {
                return response()->json(['error' => 'You have already placed an order.'], 200);
            }
            $order = Order::create([
                 'user_id' => Auth::id(),
                 'name' => Auth::user()->name,
                 'email' => Auth::user()->email,
                 'pakage_name' => $request->package_name,
                 'validity' => $request->validity,
                 'expired_date' => Carbon::now()->addDays((int)$request->validity),
                 'price' => $request->price,
                 'status' => 'success',
            ]);

            $user = User::find(Auth::user()->id);
            $user->isPremium = 1;
            $user->validity = $request->validity;
            $user->subscription_id = $order->id;
            $user->pakage_name = $request->package_name;
            $user->price = $request->price;
            $user->start_date = Carbon::now();
            $user->expired_date = Carbon::now()->addDays((int)$request->validity);
            $user->save();

            return response()->json(['message' => 'Subscription created successfully'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Subscription creation failed'], 200);
        }
    }

    public function orderCancel(Request $request){
        $id = Auth::user()->id;
        $order = Order::where('user_id', Auth::user()->id)->first();
        if(!$order)
        {
            return response()->json(['message' => 'No Order Found!'], 200);    
        }
        $order->delete();

        $user = User::where('id', $order->user_id)->first();
            $user->isPremium = 0;
            $user->validity = NULL;
            $user->subscription_id = NULL;
            $user->start_date = NULL;
            $user->expired_date = NULL;
            $user->pakage_name = NULL;
            $user->price = NULL;
            $user->save();

        return response()->json(['message' => 'Subscription canceled successfully'], 200);
    }

    public function orderCancelExpireDate(Request $request)
    {
        $user = Auth::user();
        $order = Order::where('user_id', $user->id)->first();

        if (!$order) {
            return response()->json(['message' => 'No Order Found!'], 200);
        }

        // Check if expired_date is today or earlier
        if ($user->expired_date && \Carbon\Carbon::parse($user->expired_date)->isPast()) {
            // Cancel the order
            $order->delete();

            // Update user subscription status
            $user->isPremium = 0;
            $user->validity = null;
            $user->subscription_id = null;
            $user->start_date = null;
            $user->expired_date = null;
            $user->pakage_name = NULL;
            $user->price = NULL;
            $user->save();

            return response()->json(['message' => 'Subscription auto-canceled due to expiry'], 200);
        }

        return response()->json(['message' => 'Subscription is still valid'], 200);
    }


    public function showProfile()
    {
        try {
            $user = User::find(Auth::user()->id);

            if (!$user) {
                return response()->json(['error' => 'User not found'], 200);
            }

            return response()->json($user, 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'User retrieval failed'], 200);
        }
    }
     public function userStatus()
    {
        try {
            $user = User::find(Auth::user()->id);

            if (!$user) {
                return response()->json(['error' => 'User not found'], 200);
            }

            return response()->json($user->isPremium, 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'User retrieval failed'], 200);
        }
    }
}
