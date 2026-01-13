@extends('layouts.app')
@section('title', '应用更新弹窗')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; border-radius:12px;">
        <div class="p-4">
            
            <h3 class="mb-4 text-dark">应用更新弹窗设置</h3>

            {{-- Flash Messages --}}
            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            {{-- Settings Form --}}
            <form action="{{ route('settings.popup.update') }}" method="POST">
                @csrf
                <div class="row g-3">

                    {{-- App Version --}}
                    <div class="col-md-6">
                        <label for="app_version" class="form-label">应用版本</label>
                        <input type="text" name="app_version" class="form-control input-dark" 
                               value="{{ $settings['app_version'] ?? '' }}" placeholder="例如：1.0.0">
                    </div>

                    {{-- Force Update --}}
                    <div class="col-md-6">
                        <label for="force_update" class="form-label">强制更新</label>
                        <select name="force_update" class="form-select input-dark">
                            <option value="1" {{ ($settings['force_update'] ?? '0') == '1' ? 'selected' : '' }}>是</option>
                            <option value="0" {{ ($settings['force_update'] ?? '0') == '0' ? 'selected' : '' }}>否</option>
                        </select>
                        <small class="text-muted">强制用户更新应用</small>
                    </div>

                    {{-- Popup Title --}}
                    <div class="col-md-6">
                        <label for="popup_title" class="form-label">弹窗标题</label>
                        <input type="text" name="popup_title" class="form-control input-dark" 
                               value="{{ $settings['popup_title'] ?? '' }}" placeholder="例如：发现新版本">
                    </div>

                    {{-- App URL --}}
                    <div class="col-md-6">
                        <label for="app_url" class="form-label">应用链接</label>
                        <input type="url" name="app_url" class="form-control input-dark" 
                               value="{{ $settings['app_url'] ?? '' }}" placeholder="https://play.google.com/store/apps/details?id=...">
                        <small class="text-muted">应用商店链接</small>
                    </div>

                    {{-- Popup Content --}}
                    <div class="col-12">
                        <label for="popup_content" class="form-label">弹窗内容</label>
                        <textarea name="popup_content" class="form-control input-dark" rows="4" 
                                  placeholder="输入要向用户显示的更新消息...">{{ $settings['popup_content'] ?? '' }}</textarea>
                    </div>

                </div>

                <button type="submit" class="btn btn-primary btn-hover mt-4">
                    <i class="fa fa-save fa-lg"></i> 更新弹窗设置
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
