@extends('layouts.app')
@section('title', 'Facebook 广告设置')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; border-radius:12px;">
        <div class="p-4">
            
            <h3 class="mb-4 text-dark">Facebook 广告设置</h3>

            {{-- Flash Messages --}}
            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            {{-- Ad Settings Form --}}
            <form action="{{ route('settings.facebookads.update') }}" method="POST">
                @csrf

                {{-- App ID --}}
                <div class="row g-3 mb-4">
                    <div class="col-12">
                        <label for="facebook_app_id" class="form-label text-info">应用 ID (App Id)</label>
                        <input type="text" name="facebook_app_id" class="form-control input-dark" 
                               value="{{ $settings['facebook_app_id'] ?? '' }}" 
                               placeholder="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX">
                    </div>
                </div>

                {{-- Native Ad --}}
                <div class="row g-3 mb-3 align-items-end">
                    <div class="col-md-8">
                        <label for="facebook_native_ad" class="form-label text-info">原生广告 (Native Ad)</label>
                        <input type="text" name="facebook_native_ad" class="form-control input-dark" 
                               value="{{ $settings['facebook_native_ad'] ?? '' }}" 
                               placeholder="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX">
                    </div>
                    <div class="col-md-4">
                        <label for="facebook_native_enabled" class="form-label">是否启用</label>
                        <select name="facebook_native_enabled" class="form-select input-dark">
                            <option value="1" {{ ($settings['facebook_native_enabled'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['facebook_native_enabled'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>
                </div>

                {{-- Banner Ad --}}
                <div class="row g-3 mb-3 align-items-end">
                    <div class="col-md-8">
                        <label for="facebook_banner_ad" class="form-label text-info">横幅广告 (Banner Ad)</label>
                        <input type="text" name="facebook_banner_ad" class="form-control input-dark" 
                               value="{{ $settings['facebook_banner_ad'] ?? '' }}" 
                               placeholder="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX">
                    </div>
                    <div class="col-md-4">
                        <label for="facebook_banner_enabled" class="form-label">是否启用</label>
                        <select name="facebook_banner_enabled" class="form-select input-dark">
                            <option value="1" {{ ($settings['facebook_banner_enabled'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['facebook_banner_enabled'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>
                </div>

                {{-- Open Ad --}}
                <div class="row g-3 mb-3 align-items-end">
                    <div class="col-md-8">
                        <label for="facebook_open_ad" class="form-label text-info">开屏广告 (Open Ad)</label>
                        <input type="text" name="facebook_open_ad" class="form-control input-dark" 
                               value="{{ $settings['facebook_open_ad'] ?? '' }}" 
                               placeholder="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX">
                    </div>
                    <div class="col-md-4">
                        <label for="facebook_open_enabled" class="form-label">是否启用</label>
                        <select name="facebook_open_enabled" class="form-select input-dark">
                            <option value="1" {{ ($settings['facebook_open_enabled'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['facebook_open_enabled'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>
                </div>

                {{-- Rewarded Ad --}}
                <div class="row g-3 mb-3 align-items-end">
                    <div class="col-md-8">
                        <label for="facebook_rewarded_ad" class="form-label text-info">激励广告 (Rewarded Ad)</label>
                        <input type="text" name="facebook_rewarded_ad" class="form-control input-dark" 
                               value="{{ $settings['facebook_rewarded_ad'] ?? '' }}" 
                               placeholder="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX">
                    </div>
                    <div class="col-md-4">
                        <label for="facebook_rewarded_enabled" class="form-label">是否启用</label>
                        <select name="facebook_rewarded_enabled" class="form-select input-dark">
                            <option value="1" {{ ($settings['facebook_rewarded_enabled'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['facebook_rewarded_enabled'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>
                </div>

                {{-- Interstitial Ad --}}
                <div class="row g-3 mb-4 align-items-end">
                    <div class="col-md-8">
                        <label for="facebook_interstitial_ad" class="form-label text-info">插屏广告 (Interstitial Ad)</label>
                        <input type="text" name="facebook_interstitial_ad" class="form-control input-dark" 
                               value="{{ $settings['facebook_interstitial_ad'] ?? '' }}" 
                               placeholder="ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX">
                    </div>
                    <div class="col-md-4">
                        <label for="facebook_interstitial_enabled" class="form-label">是否启用</label>
                        <select name="facebook_interstitial_enabled" class="form-select input-dark">
                            <option value="1" {{ ($settings['facebook_interstitial_enabled'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['facebook_interstitial_enabled'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary btn-hover">
                    <i class="fa fa-save fa-lg"></i> 保存 Facebook 广告设置
                </button>
            </form>
        </div>
    </div>
</div>
@endsection

@push('style')
<style>
/* Inputs dark theme */
.input-dark {
    background-color: #eee !important;
    border: 1px solid #444 !important;
    color: #111 !important;
}

/* Buttons */
.btn-primary {
    background-color: #0df40d !important;
    border-color: #0df40d !important;
    color: #111 !important;
}

.form-label {
    color: #111 !important;
}

/* Card & container */
.card {
    border-radius: 12px;
}

/* Breadcrumb */
.breadcrumb-item + .breadcrumb-item::before {
    color: #888;
}

/* Ad row styling */
.row.align-items-end {
    padding: 15px;
    background-color: #eee;
    border-radius: 8px;
    margin-bottom: 10px !important;
}

/* Responsive spacing */
@media (max-width:767px){
    .card { padding: 20px 15px; }
}
</style>
@endpush
