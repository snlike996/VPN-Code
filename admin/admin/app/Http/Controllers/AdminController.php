<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AdminController extends Controller
{
    public function login(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'email' => 'required|email',
                'password' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => $validator->errors()], 200);
            }
            $admin = Admin::where(['email' => $request->email])->first();
            if ($admin && Hash::check($request->password, $admin->password)) {
                $token = $admin->createToken('API TOKEN')->plainTextToken;

                return response()->json([
                    'message' => 'You have logged in successfully',
                    'token' => $token,
                ], 200);
            } else {
                return response()->json(['error' => 'Unauthorized'], 200);
            }
        } catch (\Exception $e) {
            dd($e);

            return response()->json(['error' => 'Login failed'], 200);
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

            $admin = Auth::guard('api_admin')->user();

            if (! Hash::check($request->current_password, $admin->password)) {
                return response()->json(['error' => 'Current password is incorrect'], 200);
            }

            $admin->password = Hash::make($request->new_password);
            $admin->save();

            return response()->json(['message' => 'Password changed successfully'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Password change failed'], 200);
        }
    }

    public function update(Request $request, $id)
    {
        try {
            $admin = Admin::find($id);

            if (! $admin) {
                return response()->json(['error' => 'Admin not found'], 200);
            }

            $validator = Validator::make($request->all(), [
                'name' => 'string',
                'email' => 'email|unique:admins,email,'.$id,
            ]);

            if ($validator->fails()) {
                return response()->json(['error' => $validator->errors()], 200);
            }

            $admin->name = $request->input('name');
            $admin->email = $request->input('email');
            $admin->save();

            return response()->json(['message' => 'Admin updated successfully', 'admin' => $admin], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Update failed'], 200);
        }
    }

    public function profile()
    {
        try {
            $user = Auth::guard('api_admin')->user();
            $user->password = '#Hidden';
            if (! $user) {
                return response()->json(['error' => 'Admin not found'], 200);
            }

            return response()->json($user, 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Admin retrieval failed'], 200);
        }
    }

    public function logout()
    {
        try {
            Auth::guard('api_admin')->user()->tokens()->delete();

            return response()->json(['message' => 'Admin logout successful'], 200);
        } catch (\Exception $e) {
            dd($e);

            return response()->json(['error' => 'Admin logout failed'], 200);
        }
    }
}
