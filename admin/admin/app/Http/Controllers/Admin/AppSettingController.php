<?php

namespace App\Http\Controllers\Admin;

use App\CPU\Helpers;
use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Exception;
use Illuminate\Http\Request;

/**
 * Handles all application settings management.
 * Includes general, popup, contact, app, and ad settings.
 */
class AppSettingController extends Controller
{
    /**
     * Display general settings page.
     *
     * @return \Illuminate\View\View
     */
    public function general()
    {
        $settings = AppSetting::getValues([
            'v2ray_status',
            'paginate',
            'app_logo',
            'short_logo',
            'device_limit',
            'openconnect_status',
            'ads_click',
            'ads_setting',
        ]);

        return view('admin.settings.general', compact('settings'));
    }

    /**
     * Display app update popup settings page.
     *
     * @return \Illuminate\View\View
     */
    public function popup()
    {
        $settings = AppSetting::getValues([
            'app_version',
            'force_update',
            'popup_title',
            'popup_content',
            'app_url',
        ]);

        return view('admin.settings.popup', compact('settings'));
    }

    /**
     * Display contact settings page.
     *
     * @return \Illuminate\View\View
     */
    public function contact()
    {
        $settings = AppSetting::getValues([
            'telegram_username',
            'contact_email',
        ]);

        return view('admin.settings.contact', compact('settings'));
    }

    /**
     * Display app settings page (privacy, terms, about, urls).
     *
     * @return \Illuminate\View\View
     */
    public function app()
    {
        $settings = AppSetting::getValues([
            'privacy_policy',
            'terms_conditions',
            'about_us',
            'more_app_url',
            'share_app_url',
            'rate_app_url',
        ]);

        return view('admin.settings.app', compact('settings'));
    }

    /**
     * Display ad settings page.
     *
     * @return \Illuminate\View\View
     */
    public function ads()
    {
        $settings = AppSetting::getValues([
            'admob_app_id',
            'admob_native_ad',
            'admob_native_enabled',
            'admob_banner_ad',
            'admob_banner_enabled',
            'admob_open_ad',
            'admob_open_enabled',
            'admob_rewarded_ad',
            'admob_rewarded_enabled',
            'admob_interstitial_ad',
            'admob_interstitial_enabled',
        ]);

        return view('admin.settings.ads', compact('settings'));
    }
    public function facebookads()
    {
        $settings = AppSetting::getValues([
            'facebook_app_id',
            'facebook_native_ad',
            'facebook_native_enabled',
            'facebook_banner_ad',
            'facebook_banner_enabled',
            'facebook_open_ad',
            'facebook_open_enabled',
            'facebook_rewarded_ad',
            'facebook_rewarded_enabled',
            'facebook_interstitial_ad',
            'facebook_interstitial_enabled',
        ]);

        return view('admin.settings.fbads', compact('settings'));
    }

    /**
     * Update general settings.
     *
     * @param Request $request
     * @return \Illuminate\Http\RedirectResponse
     */
    public function updateGeneral(Request $request)
    {
        try {
            // Handle text/select fields
            $fields = ['v2ray_status', 'paginate', 'device_limit', 'openconnect_status', 'ads_click', 'ads_setting'];
            foreach ($fields as $field) {
                if ($request->has($field)) {
                    AppSetting::setValue($field, $request->input($field));
                    session([$field => $request->input($field)]);
                }
            }

            // Handle image uploads
            if ($request->hasFile('app_logo')) {
                $this->handleImageUpload('app_logo', $request->file('app_logo'));
            }
            if ($request->hasFile('short_logo')) {
                $this->handleImageUpload('short_logo', $request->file('short_logo'));
            }

            return back()->with('success', '通用设置已更新。');
        } catch (Exception $e) {
            return back()->with('error', '设置更新失败: ' . $e->getMessage());
        }
    }

    /**
     * Update app update popup settings.
     *
     * @param Request $request
     * @return \Illuminate\Http\RedirectResponse
     */
    public function updatePopup(Request $request)
    {
        try {
            $fields = ['app_version', 'force_update', 'popup_title', 'popup_content', 'app_url'];
            foreach ($fields as $field) {
                if ($request->has($field)) {
                    AppSetting::setValue($field, $request->input($field));
                }
            }

            return back()->with('success', '弹窗设置已更新。');
        } catch (Exception $e) {
            return back()->with('error', '设置更新失败: ' . $e->getMessage());
        }
    }

    /**
     * Update contact settings.
     *
     * @param Request $request
     * @return \Illuminate\Http\RedirectResponse
     */
    public function updateContact(Request $request)
    {
        try {
            $fields = ['telegram_username', 'contact_email'];
            foreach ($fields as $field) {
                if ($request->has($field)) {
                    AppSetting::setValue($field, $request->input($field));
                }
            }

            return back()->with('success', '联系方式设置已更新。');
        } catch (Exception $e) {
            return back()->with('error', '设置更新失败: ' . $e->getMessage());
        }
    }

    /**
     * Update a single app setting field (privacy, terms, about, urls).
     *
     * @param Request $request
     * @return \Illuminate\Http\RedirectResponse
     */
    public function updateAppField(Request $request)
    {
        try {
            $allowedFields = ['privacy_policy', 'terms_conditions', 'about_us', 'more_app_url', 'share_app_url', 'rate_app_url'];
            $field = $request->input('field');
            $value = $request->input('value');

            if (!in_array($field, $allowedFields)) {
                return back()->with('error', '无效的字段。');
            }

            AppSetting::setValue($field, $value);

            return back()->with('success', ucfirst(str_replace('_', ' ', $field)) . ' 已更新。');
        } catch (Exception $e) {
            return back()->with('error', '更新失败: ' . $e->getMessage());
        }
    }

    /**
     * Update ad settings.
     *
     * @param Request $request
     * @return \Illuminate\Http\RedirectResponse
     */
    public function updateFacebookAds(Request $request)
    {
        try {
            $fields = [
            'facebook_app_id',
            'facebook_native_ad',
            'facebook_native_enabled',
            'facebook_banner_ad',
            'facebook_banner_enabled',
            'facebook_open_ad',
            'facebook_open_enabled',
            'facebook_rewarded_ad',
            'facebook_rewarded_enabled',
            'facebook_interstitial_ad',
            'facebook_interstitial_enabled',
        ];
            foreach ($fields as $field) {
                $value = $request->input($field, $field . '_enabled' ? '0' : '');
                AppSetting::setValue($field, $value);
            }

            return back()->with('success', 'Facebook 广告设置已更新。');
        } catch (Exception $e) {
            return back()->with('error', '设置更新失败: ' . $e->getMessage());
        }
    }
    public function updateAds(Request $request)
    {
        try {
            $fields = [
                'admob_app_id',
                'admob_native_ad',
                'admob_native_enabled',
                'admob_banner_ad',
                'admob_banner_enabled',
                'admob_open_ad',
                'admob_open_enabled',
                'admob_rewarded_ad',
                'admob_rewarded_enabled',
                'admob_interstitial_ad',
                'admob_interstitial_enabled',
            ];

            foreach ($fields as $field) {
                $value = $request->input($field, $field . '_enabled' ? '0' : '');
                AppSetting::setValue($field, $value);
            }

            return back()->with('success', '广告设置已更新。');
        } catch (Exception $e) {
            return back()->with('error', '设置更新失败: ' . $e->getMessage());
        }
    }

    /**
     * Legacy update method for backward compatibility.
     *
     * @param Request $request
     * @return \Illuminate\Http\RedirectResponse
     */
    public function update(Request $request)
    {
        try {
            foreach ($request->all() as $key => $value) {
                if ($key != '_token' && $value != null) {
                    if ($key != 'app_logo' && $key != 'short_logo') {
                        AppSetting::setValue($key, $value);
                        session([$key => $value]);
                        Helpers::updateEnvCredentials($key, $value);
                    }
                    if ($key == 'app_logo' || $key == 'short_logo') {
                        $this->handleImageUpload($key, $value);
                    }
                }
            }

            return back()->with('update', '设置已更新成功');
        } catch (Exception $e) {
            return back()->with('error', $e->getMessage());
        }
    }

    /**
     * Handle image upload for settings.
     *
     * @param string $key
     * @param \Illuminate\Http\UploadedFile $file
     * @return void
     */
    private function handleImageUpload(string $key, $file): void
    {
        $currentValue = AppSetting::getValue($key);

        // Delete previous image if exists
        if ($currentValue) {
            $previousImagePath = public_path('storage/images/settings/' . $currentValue);
            if (file_exists($previousImagePath)) {
                unlink($previousImagePath);
            }
        }

        // Store new image
        $fileName = time() . rand(100, 999) . '.' . $file->getClientOriginalExtension();
        $file->storeAs('public/images/settings', $fileName);

        // Update setting
        AppSetting::setValue($key, $fileName);
        session([$key => $fileName]);
    }
}
