<?php

namespace App\Http\Controllers;

use App\Models\HelpCenter;
use Illuminate\Http\Request;

class HelpCenterController extends Controller
{
    public function search(Request $request)
    {
        $search_text = $request->input('search_text');

        if (!filled($search_text)) {
            $results = HelpCenter::all();
            return response()->json(['results' => $results]);
        }

        if($search_text){
            $results = HelpCenter::where('question', 'like', '%' . $search_text . '%')
            ->take(10)
            ->get();
        }

        

        return response()->json(['results' => $results]);
    }
}
