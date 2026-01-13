<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\Chat;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    public function index()
    {
        $latestChats = Chat::select(
                'user_id',
                DB::raw('MAX(created_at) as last_message_at')
            )
            ->groupBy('user_id');

        $users = Chat::joinSub($latestChats, 'latest', function ($join) {
                $join->on('chats.user_id', '=', 'latest.user_id')
                    ->whereRaw('chats.created_at = latest.last_message_at');
            })
            ->with('user:id,name,email')
            ->orderByDesc('latest.last_message_at')
            ->get([
                'chats.user_id',
                'chats.sender_type',
                'chats.admin_read_view',
                'latest.last_message_at'
            ])
            ->map(function ($chat) {
                return [
                    'id' => $chat->user->id,
                    'name' => $chat->user->name,
                    'email' => $chat->user->email,
                    'last_message_at' => $chat->last_message_at,
                    'sender_type' => $chat->sender_type,
                    'admin_read_view' => $chat->admin_read_view,
                ];
            });

        return view('admin.chat', compact('users'));
    }


    public function search(Request $request)
    {
        $search = $request->input('q');

        $users = User::select('id', 'name', 'email')
            ->when($search, function ($query, $search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            })
            ->orderBy('name')
            ->limit(20)
            ->get()
            ->map(function ($user) {
                $lastChat = Chat::where('user_id', $user->id)
                    ->latest('created_at')
                    ->first();

                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'last_message_at' => $lastChat?->created_at,
                    'admin_read_view' => $lastChat?->admin_read_view ?? 1,
                ];
            });

        return response()->json($users);
    }



    // Fetch messages for a specific user (AJAX)
    public function getMessages(Request $request)
    {
        $request->validate(['user_id' => 'required|exists:users,id']);

        $messages = Chat::where('user_id', $request->user_id)
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($messages);
    }

    // Send message from admin to user (AJAX)
    public function sendMessage(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'message' => 'required|string',
        ]);
        $admin_id = Admin::first()->id;
        $chat = Chat::create([
            'user_id' => $request->user_id,
            'admin_id' => $admin_id,
            'message' => $request->message,
            'sender_type' => 'admin',
            'admin_read_view' => 1
        ]);

        return response()->json(['success' => true, 'data' => $chat]);
    }

    public function admin_read_view(Request $request, $id)
    {
        Chat::where('user_id', $id)
            ->update(['admin_read_view' => 1]);

        return response()->json(['success' => true]);
    }

}
