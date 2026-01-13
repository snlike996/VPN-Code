<?php

namespace App\Http\Controllers;

use App\Models\Bandwidth;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class BandwidthController extends Controller
{
    public function store(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'server' => 'required|string|max:255',
                'duration' => 'required|numeric',
                'mb' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => $validator->errors()], 200);
            }

            $bandwidth = Bandwidth::create([
                'name' => Auth::user()->name,
                'email' => Auth::user()->email,
                'server' => $request->input('server'),
                'duration' => $request->input('duration'),
                'mb' => $request->input('mb'),
            ]);

            return response()->json([
                'message' => 'Successfully added',
                'bandwidth' => $bandwidth,
            ], 201);

        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Add failed',
                'exception' => $e->getMessage(),
            ], 200);
        }
    }

}
