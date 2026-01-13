<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use Illuminate\Http\Request;
use Carbon\Carbon;

class SubscriptionPlanController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->input('search');

        $plans = SubscriptionPlan::when($search, function ($query, $search) {
            $query->where('pakage_name', 'like', "%{$search}%");
        })->orderBy('id', 'desc')->paginate(Helpers::getPaginateSetting());

        return view('admin.subscription_plan', compact('plans'));
    }

    public function show($id)
    {
        
    }

    public function store(Request $request)
    {
        $request->validate([
            'pakage_name' => 'required|string|max:255',
            'validity' => 'required|integer|min:1',
            'price' => 'required|numeric|min:0',
        ]);

        $startDate = Carbon::now();
        $endDate   = $startDate->copy()->addDays((int)$request->validity);

        SubscriptionPlan::create([
            'pakage_name' => $request->pakage_name,
            'validity' => $request->validity,
            'price' => $request->price,
            'start_date' => $startDate,
            'expired_date' => $endDate,
        ]);

        return redirect()->back()->with('done', '订阅计划添加成功。');
    }

    public function update(Request $request, $id)
    {
        $plan = SubscriptionPlan::findOrFail($id);

        $request->validate([
            'pakage_name' => 'required|string|max:255',
            'validity' => 'required|integer|min:1',
            'price' => 'required|numeric|min:0',
        ]);

        $startDate = Carbon::now();
        $endDate   = $startDate->copy()->addDays((int)$request->validity);

        $plan->update([
            'pakage_name' => $request->pakage_name,
            'validity' => $request->validity,
            'price' => $request->price,
            'start_date' => $startDate,
            'expired_date' => $endDate,
        ]);

        return redirect()->back()->with('done', '订阅计划更新成功。');
    }

    public function destroy($id)
    {
        $plan = SubscriptionPlan::findOrFail($id);
        $plan->delete();

        return redirect()->back()->with('done', '订阅计划删除成功。');
    }
}
