<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Support\Facades\Auth;

class AdminMiddleware
{
    public function handle($request, Closure $next)
    {

        if (Auth::guard('admins')->user() != null && Auth::guard('admins')->user()->id === 1) {
            return $next($request);
        }

        return redirect('/');
    }
}
