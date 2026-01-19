@extends('layouts.app')
@section('title', '系统设置')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; border-radius:12px;">
        <div class="p-4">
            <h3 class="mb-4">系统设置</h3>

            {{-- Flash Messages --}}
            @if(session('update'))
                <div class="alert alert-success">{{ session('update') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            {{-- Settings Form --}}
            <form action="{{ route('settings.update') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <div class="row g-3">

                    <div class="col-md-4">
                        @php
                            $app_version = \App\Models\AppSetting::where('key', 'app_version')->value('value');
                        @endphp
                        <label for="app_version" class="form-label">应用版本</label>
                        <input type="text" name="app_version" class="form-control input-dark" value="{{ $app_version }}">
                    </div>


                    <div class="col-md-4">
                        @php
                            $v2ray_status = \App\Models\AppSetting::where('key', 'v2ray_status')->value('value');
                        @endphp
                        <label for="v2ray_status" class="form-label">V2ray状态</label>
                        <select name="v2ray_status" class="form-select input-dark">
                            <option value="1" {{ $v2ray_status == 1 ? 'selected' : '' }}>启用</option>
                            <option value="0" {{ $v2ray_status == 0 ? 'selected' : '' }}>禁用</option>
                        </select>
                    </div>

                    <div class="col-md-4">
                        <label for="paginate" class="form-label">分页</label>
                        <input type="number" name="paginate" class="form-control input-dark"
                            value="{{ App\CPU\Helpers::getPaginateSetting() }}">
                    </div>

                    <div class="col-md-4">
                        <label for="app_logo" class="form-label">管理后台Logo</label>
                        <input type="file" name="app_logo" class="form-control input-dark">
                        <img src="{{ App\CPU\Helpers::getAppLogoSetting() }}" class="mt-2 rounded" alt="App Logo" height="70" width="auto">
                    </div>

                    <div class="col-md-4">
                        <label for="short_logo" class="form-label">简短Logo</label>
                        <input type="file" name="short_logo" class="form-control input-dark">
                        <img src="{{ App\CPU\Helpers::getShortLogoSetting() }}" class="mt-2 rounded" alt="Short Logo" height="70" width="auto">
                    </div>

                </div>

                <button type="submit" class="btn btn-primary btn-hover mt-4">
                    <i class="fa fa-pencil-square fa-lg"></i> 更新
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
.input-dark:focus {
    background-color: #1f1f2e !important;
    border-color: #0df40d !important;
    
    color: #fff !important;
}

/* Buttons */
.btn-primary {
    background-color: #0df40d !important;
    border-color: #0df40d !important;
    color: #fff !important;
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

/* Responsive spacing */
@media (max-width:767px){
    .card { padding: 20px 15px; }
}
</style>
@endpush
