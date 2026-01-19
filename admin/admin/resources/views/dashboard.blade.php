@extends('layouts.app')
@section('title', '仪表盘')

@section('content')
<div class="container-fluid py-4 min-vh-100 bg-light">

    <!-- Welcome Section -->
    <div class="row mb-4 px-3">
        <div class="col-12 col-xl-8 mb-3 mb-xl-0">
            <h3 class="fw-bold text-dark">欢迎,{{ auth('admins')->user()->name }}</h3>
            <h6 class="text-muted mb-0">所有系统运行正常!</h6>
        </div>
        <div class="col-12 col-xl-4 d-flex justify-content-end align-items-start">
            <p class="btn btn-sm btn-light bg-white text-dark" id="currentDate"></p>
        </div>
    </div>

    <!-- Dashboard Cards -->
    <div class="row g-4 mt-3 px-3">
    
        @php
            $v2ray_status = \App\Models\AppSetting::where('key', 'v2ray_status')->value('value');
        @endphp

        @if($v2ray_status == 1)
        <div class="col-md-3">
            <div class="card dashboard-card shadow-sm">
                <div class="card-body text-center py-4">
                    <h6 class="mb-2">V2Ray 订阅国家数</h6>
                    <h3 class="fw-bold">{{ $counts['v2rayServers'] }}</h3>
                </div>
            </div>
        </div>
        @endif

        @php
            $openconnect_status = \App\Models\AppSetting::where('key', 'openconnect_status')->value('value');
        @endphp

        @if($openconnect_status == 1)
        <div class="col-md-3">
            <div class="card dashboard-card shadow-sm">
                <div class="card-body text-center py-4">
                    <h6 class="mb-2">OpenConnect 服务器总数</h6>
                    <h3 class="fw-bold">{{ $counts['openconnectServers'] }}</h3>
                </div>
            </div>
        </div>
        @endif
        <div class="col-md-3">
            <div class="card dashboard-card shadow-sm">
                <div class="card-body text-center py-4">
                    <h6 class="mb-2">用户总数</h6>
                    <h3 class="fw-bold">{{ $counts['users'] }}</h3>
                </div>
            </div>
        </div>

        <div class="col-md-3">
            <div class="card dashboard-card shadow-sm">
                <div class="card-body text-center py-4">
                    <h6 class="mb-2">订阅总数</h6>
                    <h3 class="fw-bold">{{ $counts['subscriptions'] }}</h3>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card dashboard-card shadow-sm">
                <div class="card-body text-center py-4">
                    <h6 class="mb-2">总收入</h6>
                    <h3 class="fw-bold">$ {{ $counts['totalRevenue'] }}</h3>
                </div>
            </div>
        </div>
    </div>

    <!-- Top Server users -->
     
    <div class="row px-3 mt-5">
    <h4 class="text-dark fw-bold">前5名服务器</h4>
        <div class="col-12">
           <div class="table-responsive shadow-sm rounded">
            <table class="table table-striped table-light text-dark mb-0 align-middle">
                <thead class="table-secondary text-dark bg-opacity-10">
                    <tr class="text-center">
                        <th>名称</th>
                        <th>协议</th>
                        <th>活跃数量</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($counts['topServerUsers'] as $server)
                    <tr class="text-center">
                        <td>{{ ucwords($server->name) }}</td>
                        <td>
                            @if($server->protocol == 'v2ray')
                                <span class="badge bg-warning">V2ray</span>
                            @elseif($server->protocol == 'openconnect')
                                <span class="badge bg-danger">OpenConnect</span>
                            @endif
                        </td>
                        
                        
                        <td>{{ $server->active_count }}</td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="4" class="text-center text-danger">未找到活跃连接</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
           </div>
        </div>
    </div>

</div>
@endsection

@push('style')
<style>
/* Dashboard Card */
.dashboard-card {
    background: #eee !important;
    border-radius: 12px;
    border: 1px solid #253A71;
    transition: transform 0.3s ease, box-shadow 0.3s ease, border-color 0.3s ease;
    color: #111;
}
.dashboard-card:hover {
    transform: translateY(-5px);
    border-color: #38c2af;
    box-shadow: 0 8px 20px rgba(0, 255, 255, 0.15);
}

/* Card Headings */
.dashboard-card h3, .dashboard-card h6 {
    color: #111;
}

/* Date Button */
.btn-light {
    background-color: #eee !important;
    color: #000 !important;
    border-radius: 6px;
    font-weight: 500;
}

/* Responsive adjustments */
@media (max-width: 767px) {
    .dashboard-card {
        padding: 20px;
    }
}
</style>
@endpush

@push('scripts')
<script>
// Display current date
const dateElement = document.getElementById('currentDate');
const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
dateElement.textContent = new Date().toLocaleDateString('zh-CN', options);
</script>
@endpush
