<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use App\Models\Chat;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    public function index()
    {
        $messages = Chat::where('user_id', Auth::id())
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($messages);
    }

    // Send message from user to admin
    public function store(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
        ]);
        $admin_id = Admin::first()->id;
        $chat = Chat::create([
            'user_id' => Auth::id(),
            'admin_id' => $admin_id,
            'message' => $request->message,
            'sender_type' => 'user',
            'user_read_view' => 1

        ]);

        return response()->json(['success' => true, 'data' => $chat]);
    }
    
    public function user_read_view(Request $request, $id)
    {
        Chat::where('user_id', $id)
            ->update(['user_read_view' => 1]);

        return response()->json(['success' => 'Message read successfully'], 200);
    }
}
