<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\RedeemRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RedeemRequestController extends Controller
{
    public function index(Request $request)
    {
        $requests = RedeemRequest::with('user')
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = $request->search;
                $query->where('code', 'like', "%{$term}%")
                    ->orWhereHas('user', function ($userQuery) use ($term) {
                        $userQuery->where('name', 'like', "%{$term}%")
                            ->orWhere('email', 'like', "%{$term}%");
                    });
            })
            ->when($request->filled('status'), function ($query) use ($request) {
                $query->where('status', $request->status);
            })
            ->latest()
            ->paginate(Helpers::getPaginateSetting());

        return view('admin.redeem_requests', compact('requests'));
    }

    public function approve($id)
    {
        $request = RedeemRequest::find($id);
        if (!$request) {
            return back()->with('not', '请求不存在');
        }

        if ($request->status !== 'pending') {
            return back()->with('not', '该请求已处理');
        }

        $user = User::find($request->user_id);
        if (!$user) {
            return back()->with('not', '用户不存在');
        }

        $validityDays = 365;
        $packageName = '口令红包';
        $price = 0;

        $start = Carbon::now();
        if (!empty($user->expired_date)) {
            $existingExpire = Carbon::parse($user->expired_date);
            if ($existingExpire->isFuture()) {
                $start = $existingExpire;
            }
        }
        $expiredAt = $start->copy()->addDays($validityDays);
        $totalValidity = max(1, Carbon::now()->diffInDays($expiredAt, false));

        $order = Order::where('user_id', $user->id)->first();
        if (!$order) {
            $order = new Order();
            $order->user_id = $user->id;
            $order->name = $user->name;
            $order->email = $user->email;
        }
        $order->pakage_name = $packageName;
        $order->price = $price;
        $order->validity = $totalValidity;
        $order->expired_date = $expiredAt;
        $order->status = 'success';
        $order->save();

        $user->isPremium = 1;
        $user->validity = $totalValidity;
        $user->subscription_id = $order->id;
        $user->pakage_name = $packageName;
        $user->price = $price;
        $user->start_date = Carbon::now();
        $user->expired_date = $expiredAt;
        $user->save();

        $request->status = 'approved';
        $request->approved_by = Auth::guard('admins')->id();
        $request->approved_at = Carbon::now();
        $request->save();

        return back()->with('done', '已通过并开通 365 天会员');
    }

    public function reject(Request $request, $id)
    {
        $redeem = RedeemRequest::find($id);
        if (!$redeem) {
            return back()->with('not', '请求不存在');
        }

        if ($redeem->status !== 'pending') {
            return back()->with('not', '该请求已处理');
        }

        $redeem->status = 'rejected';
        $redeem->rejected_by = Auth::guard('admins')->id();
        $redeem->rejected_at = Carbon::now();
        $redeem->note = $request->input('note');
        $redeem->save();

        return back()->with('done', '已拒绝该请求');
    }
}
