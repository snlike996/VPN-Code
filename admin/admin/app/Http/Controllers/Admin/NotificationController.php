<?php

namespace App\Http\Controllers\Admin;

use App\Events\NotificationSent;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(){
        return view('admin.push_notification');
    }
    public function send(Request $request)
    {
        try {
            $request->validate([
                'title' => 'required|string|max:255',
                'message' => 'required|string',
            ]);

            $title = $request->input('title');
            $message = $request->input('message');

            // Fire the event (broadcasted via Pusher)
            event(new NotificationSent($title, $message));

            return back()->with('done', '通知已发送给所有用户。');
        } catch (\Exception $e) {
            return back()->with('not', $e->getMessage());
        }
    }
    

}
