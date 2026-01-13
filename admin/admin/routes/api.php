<?php

use App\Http\Controllers\AdminController;
use App\Http\Controllers\AllGetApiController;
use App\Http\Controllers\BandwidthController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\EpayController;
use App\Http\Controllers\FCMTokenController;
use App\Http\Controllers\HelpCenterController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\ServerController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/
  
/// Authentication Routes
Route::prefix('auth')->group(function () {
    Route::post('user/register', [UserController::class, 'register']);
    Route::post('user/login', [UserController::class, 'login']);
    Route::post('forgot-password', [UserController::class, 'sendResetLink']);
    Route::post('reset-password', [UserController::class, 'resetPassword']);
    Route::post('admin/login', [AdminController::class, 'login']);
});

/* V2ray */
Route::get('v2ray/list', [AllGetApiController::class, 'v2ray']);
Route::get('v2ray/list/free', [AllGetApiController::class, 'v2ray_free']);
Route::get('v2ray/list/premium', [AllGetApiController::class, 'v2ray_premium']);
Route::get('v2ray/search', [AllGetApiController::class, 'v2ray_search']);

/* OpenVpn */
Route::get('openvpn/list', [AllGetApiController::class, 'openvpn']);
Route::get('openvpn/list/free', [AllGetApiController::class, 'openvpn_free']);
Route::get('openvpn/list/premium', [AllGetApiController::class, 'openvpn_premium']);
Route::get('openvpn/search', [AllGetApiController::class, 'openvpn_search']);
/* Wireguard */
Route::get('wireguard/list', [AllGetApiController::class, 'wireguard']);
Route::get('wireguard/list/free', [AllGetApiController::class, 'wireguard_free']);
Route::get('wireguard/list/premium', [AllGetApiController::class, 'wireguard_premium']);
Route::get('wireguard/search', [AllGetApiController::class, 'wireguard_search']);

Route::get('all', [AllGetApiController::class, 'all']);


Route::get('setting', function () {
    return response()->json([
        'status' => 0,
        'data' => [
            'admob' => [
                'status' => true,
            ],
        ],
    ]);
})->name('app.setting');

Route::get('app-setting', [AllGetApiController::class, 'setting']);

Route::get('general-setting', [AllGetApiController::class, 'general_setting']);
Route::get('popup-setting', [AllGetApiController::class, 'popup_setting']);
Route::get('contact-setting', [AllGetApiController::class, 'contact_setting']);
Route::get('facebook-ads-setting', [AllGetApiController::class, 'facebook_ads_setting']);
Route::get('admob-setting', [AllGetApiController::class, 'admob_setting']);
Route::post('server-connect', [AllGetApiController::class, 'server_connect']);
Route::post('server-disconnect', [AllGetApiController::class, 'server_disconnect']);
// User API Routes
Route::prefix('user')->middleware(['auth:sanctum'])->group(function () {
    Route::get('show-profile', [UserController::class, 'showProfile']);
    Route::get('profile/{id}', [UserController::class, 'show']);
    //Route::get('server/list', [ServerController::class, 'index'])->name('admin.servers.list');
    Route::post('update/{id}', [UserController::class, 'update']);
    Route::post('change-password', [UserController::class, 'changePassword']);
    Route::post('logout', [UserController::class, 'logout']);
    Route::post('/subscription', [UserController::class, 'orderStore']);
    Route::post('/subscription/cancel', [UserController::class, 'orderCancel']);
    Route::get('/subscription/packeges', [UserController::class, 'subscriptionPackeges']);
    Route::post('/subscription/cancel/expire-date', [UserController::class, 'orderCancelExpireDate']);
  


    /* Bandwidth */
    Route::post('/bandwidth', [BandwidthController::class, 'store']);
    Route::get('/status', [UserController::class, 'userStatus']);

    /* Epay */
    Route::post('/epay/api-pay', [EpayController::class, 'apiPay']);
    Route::post('/epay/page-pay', [EpayController::class, 'pagePay']);
   
    Route::get('/epay/status/{id}', [EpayController::class, 'checkStatus']);

    Route::get('/chat', [ChatController::class, 'index']);
    Route::post('/chat', [ChatController::class, 'store']);
    Route::post('/chat/read-view/{id}', [ChatController::class, 'user_read_view']);

});

 Route::post('/epay/notify', [EpayController::class, 'notify'])->name('epay.notify');
 Route::get('/epay/return', [EpayController::class, 'return'])->name('epay.return');

// Admin API Routes
Route::prefix('admin')->middleware(['auth:admin'])->group(function () {
    Route::post('change-password', [AdminController::class, 'changePassword']);
    Route::post('update/{id}', [AdminController::class, 'update']);
    Route::post('user/register', [UserController::class, 'register']);
    Route::get('user-list', [UserController::class, 'index']);
    Route::get('user-profile/{id}', [UserController::class, 'show']);
    Route::get('profile', [AdminController::class, 'profile']);
    Route::post('user-update/{id}', [UserController::class, 'update']);
    Route::post('user-delete/{id}', [UserController::class, 'destroy']);
    Route::post('logout', [AdminController::class, 'logout']);
});


Route::get('helpcenter/search', [HelpCenterController::class, 'search']);

/*
|--------------------------------------------------------------------------
| VPN Configuration Generation Routes
|--------------------------------------------------------------------------
|
| These routes handle WireGuard VPN configuration generation via SSH.
| Protected routes require Sanctum authentication.
|
*/
use App\Http\Controllers\Api\VPNConfigController;

// Main VPN routes (all require authentication)
Route::prefix('vpn')->middleware(['auth:sanctum'])->group(function () {
    // Generate new VPN config
    Route::post('/generate', [VPNConfigController::class, 'generate']);
    
    // Remove existing VPN client from server
    Route::post('/remove-client', [VPNConfigController::class, 'removeClient']);
    
    // Test SSH connection to VPS
    Route::post('/test-connection', [VPNConfigController::class, 'testConnection']);
    
    // List all clients on VPS
    Route::post('/list-clients', [VPNConfigController::class, 'listClients']);
});
