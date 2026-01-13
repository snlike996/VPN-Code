<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\HelpCenter;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HelpCenterController extends Controller
{
    public function index(Request $request)
    {
            try {
            $helpcenters = HelpCenter::query()
                ->when($request->filled('search'), function ($query) use ($request) {
                    $searchTerm = $request->search;
                    $query->where(function ($q) use ($searchTerm) {
                        $q->where('question', 'like', "%$searchTerm%")
                            ->orWhere('answer', 'like', "%$searchTerm%");
                    });
                })
                ->orderBy('id', 'desc') // 👈 newest first
                ->paginate(Helpers::getPaginateSetting());

                return view('admin.help_center', compact('helpcenters'));
            } catch (\Exception $e) {
                return back()->with('not', '问答列表获取失败');
            }
    }

    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'question' => 'required|string',
                'answer' => 'string|required',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors());
            }

            $helpcenter = new HelpCenter([
                'question' => $request->input('question'),
                'answer' => $request->input('answer'),
            ]);

            $helpcenter->save();

            return back()->with('done', '问答创建成功');

        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());

        }
    }

    public function update(Request $request, $id)
    {
        try {
            $validator = Validator::make($request->all(), [
                'question' => 'required|string',
                'answer' => 'string|required',
            ]);

            if ($validator->fails()) {
                return back()->with('not', $validator->errors());
            }
            $helpcenter = HelpCenter::find($id);

            if (! $helpcenter) {
                return response()->json(['error' => '未找到问答'], 404);
            }

            $helpcenter->question = $request->input('question', $helpcenter->question);
            $helpcenter->answer = $request->input('answer', $helpcenter->answer);
            $helpcenter->save();

            return back()->with('done', '问答更新成功');
        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }

    public function destroy($id)
    {
        try {
            $helpcenter = HelpCenter::find($id);

            if (! $helpcenter) {
                return response()->json(['error' => '未找到问答'], 404);
            }

            $helpcenter->delete();

            return back()->with('done', '问答删除成功');

        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }
}
