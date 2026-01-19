@extends('layouts.app')
@section('title', 'V2Ray 订阅配置')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; color: #111; border-radius:12px;">
        <div class="p-4">
            <h3 class="mb-4 text-dark">V2Ray 国家订阅配置</h3>

            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            <form id="subscriptionForm" action="{{ route('admin.v2ray.subscriptions.store') }}" method="POST">
                @csrf
                <div class="row g-3">
                    <div class="col-md-3">
                        <label for="country_name" class="form-label">国家名称</label>
                        <input type="text" name="country_name" id="country_name" class="form-control input-light" placeholder="美国" required>
                    </div>
                    <div class="col-md-2">
                        <label for="country_code" class="form-label">国家代码</label>
                        <input type="text" name="country_code" id="country_code" class="form-control input-light" placeholder="us" required>
                    </div>
                    <div class="col-md-5">
                        <label for="subscription_url" class="form-label">订阅链接</label>
                        <input type="url" name="subscription_url" id="subscription_url" class="form-control input-light" placeholder="https://example.com/sub" required>
                    </div>
                    <div class="col-md-2">
                        <label for="sort_order" class="form-label">排序</label>
                        <input type="number" name="sort_order" id="sort_order" class="form-control input-light" value="0" min="0">
                    </div>
                    <div class="col-md-3">
                        <label for="enabled" class="form-label">启用</label>
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="enabled" id="enabled" value="1" checked>
                            <label class="form-check-label" for="enabled">启用订阅</label>
                        </div>
                    </div>
                    <div class="col-md-9">
                        <label for="remark" class="form-label">备注</label>
                        <input type="text" name="remark" id="remark" class="form-control input-light" placeholder="可选备注">
                    </div>
                </div>

                <button type="submit" class="btn btn-primary btn-hover mt-4">
                    <i class="fa fa-save fa-lg"></i> 保存配置
                </button>
                <button type="button" id="resetForm" class="btn btn-outline-secondary mt-4 ms-2">清空</button>
            </form>

            <hr class="my-4">

            <div class="table-responsive shadow-sm rounded">
                <table class="table table-striped table-light text-dark mb-0 align-middle">
                    <thead class="table-secondary text-dark bg-opacity-10">
                        <tr class="text-center">
                            <th>国家</th>
                            <th>代码</th>
                            <th>订阅链接</th>
                            <th>启用</th>
                            <th>排序</th>
                            <th>备注</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($subscriptions as $item)
                            <tr class="text-center">
                                <td>{{ $item->country_name }}</td>
                                <td>{{ $item->country_code }}</td>
                                <td class="text-start">
                                    <span class="text-muted">{{ $item->subscription_url }}</span>
                                </td>
                                <td>{{ $item->enabled ? '启用' : '禁用' }}</td>
                                <td>{{ $item->sort_order }}</td>
                                <td>{{ $item->remark }}</td>
                                <td>
                                    <button
                                        type="button"
                                        class="btn btn-sm btn-outline-primary edit-btn"
                                        data-country-name="{{ $item->country_name }}"
                                        data-country-code="{{ $item->country_code }}"
                                        data-subscription-url="{{ $item->subscription_url }}"
                                        data-enabled="{{ $item->enabled ? 1 : 0 }}"
                                        data-sort-order="{{ $item->sort_order }}"
                                        data-remark="{{ $item->remark }}"
                                    >编辑</button>

                                    <form action="{{ route('admin.v2ray.subscriptions.delete') }}" method="POST" class="d-inline">
                                        @csrf
                                        <input type="hidden" name="country_code" value="{{ $item->country_code }}">
                                        <button type="submit" class="btn btn-sm btn-outline-danger" onclick="return confirm('确认删除该国家订阅？')">删除</button>
                                    </form>
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="7" class="text-center text-danger">暂无订阅配置</td>
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
.btn-primary {
    background-color: #0df40d !important;
    border-color: #0df40d !important;
    color: #111 !important;
}
</style>
@endpush

@push('script')
<script>
document.querySelectorAll('.edit-btn').forEach(function (button) {
    button.addEventListener('click', function () {
        document.getElementById('country_name').value = this.dataset.countryName || '';
        document.getElementById('country_code').value = this.dataset.countryCode || '';
        document.getElementById('subscription_url').value = this.dataset.subscriptionUrl || '';
        document.getElementById('enabled').checked = this.dataset.enabled === '1';
        document.getElementById('sort_order').value = this.dataset.sortOrder || 0;
        document.getElementById('remark').value = this.dataset.remark || '';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
});

document.getElementById('resetForm').addEventListener('click', function () {
    document.getElementById('subscriptionForm').reset();
    document.getElementById('enabled').checked = true;
    document.getElementById('sort_order').value = 0;
});
</script>
@endpush
