@extends('layouts.app')
@section('title', '常规设置')

@section('content')

<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; color: #111; border-radius:12px;">
        <div class="p-4">
           
            <h3 class="mb-4 text-dark">常规设置</h3>

            {{-- Flash Messages --}}
            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            {{-- Settings Form --}}
            <form action="{{ route('settings.general.update') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <div class="row g-3">

                    {{-- VPN Status Toggles --}}
                    <div class="col-md-4">
                        <label for="wireguard_status" class="form-label">默认协议</label>
                        <select name="default_protocol" class="form-select input-light">
                            <option value="wireguard" {{ ($settings['default_protocol'] ?? 'wireguard') == 'wireguard' ? 'selected' : '' }}>Wireguard</option>
                            <option value="v2ray" {{ ($settings['default_protocol'] ?? 'v2ray') == 'v2ray' ? 'selected' : '' }}>V2ray</option>
                            <option value="openvpn" {{ ($settings['default_protocol'] ?? 'openvpn') == 'openvpn' ? 'selected' : '' }}>OpenVPN</option>
                          
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label for="wireguard_status" class="form-label">Wireguard状态</label>
                        <select name="wireguard_status" class="form-select input-light">
                            <option value="1" {{ ($settings['wireguard_status'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['wireguard_status'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label for="v2ray_status" class="form-label">V2ray状态</label>
                        <select name="v2ray_status" class="form-select input-light">
                            <option value="1" {{ ($settings['v2ray_status'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['v2ray_status'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label for="openvpn_status" class="form-label">OpenVPN状态</label>
                        <select name="openvpn_status" class="form-select input-light">
                            <option value="1" {{ ($settings['openvpn_status'] ?? '0') == '1' ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ ($settings['openvpn_status'] ?? '0') == '0' ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>
                

                    {{-- Paginate --}}
                    <div class="col-md-4">
                        <label for="paginate" class="form-label">每页条数</label>
                        <input type="number" name="paginate" class="form-control input-light" 
                               value="{{ $settings['paginate'] ?? '10' }}" min="1" max="100">
                    </div>

                    {{-- Device Limit --}}
                    <div class="col-md-4">
                        <label for="device_limit" class="form-label">设备限制</label>
                        <input type="number" name="device_limit" class="form-control input-light" 
                               value="{{ $settings['device_limit'] ?? '1' }}" min="1" max="10">
                        <small class="text-muted">每个用户的最大设备数</small>
                    </div>
                   
                    <div class="col-md-4">
                        <label for="ads_setting" class="form-label">广告设置</label>
                        <select name="ads_setting" id="ads_setting" class="form-select input-light">
                            <option value="disabled" {{ ($settings['ads_setting'] ?? 'disabled') == 'disabled' ? 'selected' : '' }}>禁用</option>
                            <option value="admob" {{ ($settings['ads_setting'] ?? 'disabled') == 'admob' ? 'selected' : '' }}>Admob广告</option>
                           
                        </select>
                    </div>


                    {{-- Empty col for alignment --}}
                    <div class="col-md-4"></div>

                    {{-- Admin Web Logo --}}
                    <!-- <div class="col-md-4">
                        <label for="app_logo" class="form-label">Admin Web Logo</label>
                        <input type="file" name="app_logo" class="form-control input-light" accept="image/*">
                        @if(!empty($settings['app_logo']))
                            <img src="{{ asset('storage/images/settings/' . $settings['app_logo']) }}" 
                                 class="mt-2 rounded" alt="App Logo" height="70" width="auto">
                        @endif
                    </div> -->

                    {{-- Short Logo --}}
                    <!-- <div class="col-md-4">
                        <label for="short_logo" class="form-label">Short Logo (Favicon)</label>
                        <input type="file" name="short_logo" class="form-control input-light" accept="image/*">
                        @if(!empty($settings['short_logo']))
                            <img src="{{ asset('storage/images/settings/' . $settings['short_logo']) }}" 
                                 class="mt-2 rounded" alt="Short Logo" height="70" width="auto">
                        @endif
                    </div> -->

                </div>

                <button type="submit" class="btn btn-primary btn-hover mt-4">
                    <i class="fa fa-save fa-lg"></i> 更新设置
                </button>
            </form>
        </div>
    </div>
</div>
@endsection

@push('style')
<style>
/* Inputs dark theme */
.input-light {
    background-color: #eee !important;
    border: 1px solid #444 !important;
    color: #111 !important;
}
.input-light:focus {
    background-color: #eee !important;
    border-color: #0df40d !important;
    
    color: #111 !important;
}

/* Select dropdown */
.form-select.input-light option {
    background-color: #eee;
    color: #111;
}
.form-label {
    color: #111 !important;
}
/* Buttons */
.btn-primary {
    background-color: #0df40d !important;
    border-color: #0df40d !important;
    color: #111 !important;
}

/* Card & container */
.card {
    border-radius: 12px;
}

/* File preview images */
img {
    border: 2px solid #0df40d;
    border-radius: 6px;
}

/* Breadcrumb */
.breadcrumb-item + .breadcrumb-item::before {
    color: #888;
}

/* Responsive spacing */
@media (max-width:767px){
    .card { padding: 20px 15px; }
}
</style>
@endpush
