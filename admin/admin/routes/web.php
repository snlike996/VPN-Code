<?php

use App\Http\Controllers\Admin\ActiveConnectionsController;
use App\Http\Controllers\Admin\AdminController;
use App\Http\Controllers\Admin\AppSettingController;
use App\Http\Controllers\Admin\ChatController;
use App\Http\Controllers\Admin\DashBoardController;
use App\Http\Controllers\Admin\HelpCenterController;
use App\Http\Controllers\Admin\NotificationController;
use App\Http\Controllers\Admin\OpenvpnController;
use App\Http\Controllers\Admin\OpenconnectController;
use App\Http\Controllers\Admin\ServerController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\WireguardController;
use App\Http\Controllers\Admin\SubscriptionPlanController;
use App\Http\Controllers\Admin\V2rayController;
use App\Http\Controllers\EpayController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::view('/admin/notify', 'admin.notify');
Route::post('/admin/send-notification', [NotificationController::class, 'send'])->name('admin.send.notification');

Route::get('/', function () {
    return view('login');
});
Route::post('admin/login', [AdminController::class, 'login'])->name('admin.login');

Route::prefix('admin')->middleware(['admin'])->group(function () {
    Route::get('dashboard', [DashBoardController::class, 'index'])->name('admin.dashboard');
    Route::get('profile', [AdminController::class, 'profile'])->name('admin.profile');
    Route::post('change-password', [AdminController::class, 'changePassword'])->name('admin.changePassword');
    Route::post('update', [AdminController::class, 'update'])->name('admin.update');
    Route::get('user-list', [UserController::class, 'index'])->name('admin.userList');
    Route::get('user-profile/{id}', [UserController::class, 'show'])->name('admin.userProfile');
    Route::post('user-update/{id}', [UserController::class, 'update'])->name('admin.userUpdate');
    Route::any('user-delete/{id}', [UserController::class, 'destroy'])->name('user.destroy');
    // Route::post('logout', [AdminController::class, 'logout'])->name('admin.logout');
    Route::match(['get', 'post'], 'admin/logout', [AdminController::class, 'logout'])->name('admin.logout');

    Route::get('users', [DashBoardController::class, 'users'])->name('all.users');
    Route::post('user', [UserController::class, 'register'])->name('admin.user.add');
    Route::post('user/{id}', [UserController::class, 'registerUpdate'])->name('admin.user.update');
    
    /* V2ray */
    Route::post('v2ray/add', [V2rayController::class, 'store'])->name('admin.v2ray.add');
    Route::put('v2ray/update/{id}', [V2rayController::class, 'update'])->name('admin.v2ray.update');
    Route::get('v2ray/delete/{id}', [V2rayController::class, 'destroy'])->name('admin.v2ray.delete');
    Route::get('v2ray/list', [V2rayController::class, 'index'])->name('admin.v2ray.list');
    Route::post('v2ray/status/{id}', [V2rayController::class, 'status'])->name('admin.v2ray.status');

    /* OpenVpn */
    Route::post('openvpn/add', [OpenvpnController::class, 'store'])->name('admin.openvpn.add');
    Route::put('openvpn/update/{id}', [OpenvpnController::class, 'update'])->name('admin.openvpn.update');
    Route::get('openvpn/delete/{id}', [OpenvpnController::class, 'destroy'])->name('admin.openvpn.delete');
    Route::get('openvpn/list', [OpenvpnController::class, 'index'])->name('admin.openvpn.list');
    Route::post('openvpn/status/{id}', [OpenvpnController::class, 'status'])->name('admin.openvpn.status');

    /* OpenConnect */
    Route::post('openconnect/add', [OpenconnectController::class, 'store'])->name('admin.openconnect.add');
    Route::put('openconnect/update/{id}', [OpenconnectController::class, 'update'])->name('admin.openconnect.update');
    Route::get('openconnect/delete/{id}', [OpenconnectController::class, 'destroy'])->name('admin.openconnect.delete');
    Route::get('openconnect/list', [OpenconnectController::class, 'index'])->name('admin.openconnect.list');
    Route::post('openconnect/status/{id}', [OpenconnectController::class, 'status'])->name('admin.openconnect.status');

    /* Wireguard */
    Route::post('wireguard/add', [WireguardController::class, 'store'])->name('admin.wireguard.add');
    Route::put('wireguard/update/{id}', [WireguardController::class, 'update'])->name('admin.wireguard.update');
    Route::get('wireguard/delete/{id}', [WireguardController::class, 'destroy'])->name('admin.wireguard.delete');
    Route::get('wireguard/list', [WireguardController::class, 'index'])->name('admin.wireguard.list');
    Route::post('wireguard/status/{id}', [WireguardController::class, 'status'])->name('admin.wireguard.status');

    /* Active Connections */
    Route::get('active-connections', [ActiveConnectionsController::class, 'index'])->name('admin.activeConnections');

    /* Settings Routes */
    Route::post('settings/update', [AppSettingController::class, 'update'])->name('settings.update');
    Route::get('/settings', function () {
        return view('admin.settings');
    })->name('settings');

    // Settings Pages
    Route::get('settings/general', [AppSettingController::class, 'general'])->name('settings.general');
    Route::get('settings/popup', [AppSettingController::class, 'popup'])->name('settings.popup');
    Route::get('settings/contact', [AppSettingController::class, 'contact'])->name('settings.contact');
    Route::get('settings/app', [AppSettingController::class, 'app'])->name('settings.app');
    Route::get('settings/ads', [AppSettingController::class, 'ads'])->name('settings.ads');
    Route::get('settings/facebookads', [AppSettingController::class, 'facebookads'])->name('settings.facebookads');

    // Settings Update Actions
    Route::post('settings/general/update', [AppSettingController::class, 'updateGeneral'])->name('settings.general.update');
    Route::post('settings/popup/update', [AppSettingController::class, 'updatePopup'])->name('settings.popup.update');
    Route::post('settings/contact/update', [AppSettingController::class, 'updateContact'])->name('settings.contact.update');
    Route::post('settings/app/update', [AppSettingController::class, 'updateAppField'])->name('settings.app.update');
    Route::post('settings/ads/update', [AppSettingController::class, 'updateAds'])->name('settings.ads.update');
    Route::post('settings/facebookads/update', [AppSettingController::class, 'updateFacebookAds'])->name('settings.facebookads.update');

    Route::get('subscriptions', [UserController::class, 'order'])->name('admin.orders');
    Route::get('subscriptions/{id}', [UserController::class, 'orderCancel'])->name('admin.orders.cancel');
    Route::put('subscriptions/{id}', [UserController::class, 'orderUpdate'])->name('admin.orders.update');

    /* Subscription Plan */
    Route::resource('subscription-plan', SubscriptionPlanController::class);

    /* Push Notification */
    Route::get('notifications', [NotificationController::class, 'index'])->name('admin.notifications'); 
    Route::post('/admin/send-notification', [NotificationController::class, 'send'])->name('admin.send.notification');

    Route::post('user/status/{id}', [UserController::class, 'userStatus'])->name('admin.users.status');

    /* Help Center */
    Route::post('helpcenter/add', [HelpCenterController::class, 'store'])->name('admin.helpcenter.add');
    Route::put('helpcenter/update/{id}', [HelpCenterController::class, 'update'])->name('admin.helpcenter.update');
    Route::get('helpcenter/delete/{id}', [HelpCenterController::class, 'destroy'])->name('admin.helpcenter.delete');
    Route::get('helpcenter/list', [HelpCenterController::class, 'index'])->name('admin.helpcenter.list');

    /* Chat */
    Route::get('/chat', [ChatController::class, 'index'])->name('admin.chat');
    Route::post('/chat/messages', [ChatController::class, 'getMessages'])->name('admin.chat.messages');
    Route::post('/chat/send', [ChatController::class, 'sendMessage'])->name('admin.chat.send');
    Route::post('/chat/read-view/{id}', [ChatController::class, 'admin_read_view'])->name('admin.chat.admin_read_view');
    Route::post('/chat/search', [ChatController::class, 'search'])->name('admin.chat.search');


});


// Route::get('/storage-link', function () {
//     Artisan::call('storage:link');
//     return 'Storage link created!';
// });
