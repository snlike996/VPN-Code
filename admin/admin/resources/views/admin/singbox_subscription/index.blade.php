@extends('layouts.app')
@section('title', 'Sing-box 订阅配置')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; color: #111; border-radius:12px;">
        <div class="p-4">
            <h3 class="mb-4 text-dark">Sing-box 订阅配置</h3>

            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            <form id="subscriptionForm" action="{{ route('admin.singbox.subscriptions.store') }}" method="POST">
                @csrf
                <input type="hidden" name="id" id="id" value="">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label for="name" class="form-label">配置名称</label>
                        <input type="text" name="name" id="name" class="form-control input-light" placeholder="Windows-主配置" required>
                    </div>
                    <div class="col-md-2">
                        <label for="platform" class="form-label">平台</label>
                        <select name="platform" id="platform" class="form-select input-light">
                            <option value="windows" selected>Windows</option>
                            <option value="common">通用</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label for="content_type" class="form-label">配置类型</label>
                        <select name="content_type" id="content_type" class="form-select input-light">
                            <option value="config_json" selected>直接 JSON</option>
                            <option value="subscription_url">订阅 URL</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label for="priority" class="form-label">优先级</label>
                        <input type="number" name="priority" id="priority" class="form-control input-light" value="0" min="0">
                    </div>
                    <div class="col-md-2">
                        <label for="enabled" class="form-label">启用</label>
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" name="enabled" id="enabled" value="1" checked>
                            <label class="form-check-label" for="enabled">启用配置</label>
                        </div>
                    </div>
                    <div class="col-md-12">
                        <label for="subscription_url" class="form-label">订阅链接</label>
                        <input type="url" name="subscription_url" id="subscription_url" class="form-control input-light" placeholder="https://example.com/singbox-sub">
                    </div>
                    <div class="col-md-12">
                        <label for="config_content" class="form-label">配置 JSON</label>
                        <textarea name="config_content" id="config_content" rows="6" class="form-control input-light" placeholder="{ ... sing-box config json ... }"></textarea>
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
                            <th>名称</th>
                            <th>平台</th>
                            <th>类型</th>
                            <th>启用</th>
                            <th>优先级</th>
                            <th>配置内容</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($subscriptions as $item)
                            <tr class="text-center">
                                <td>{{ $item->name }}</td>
                                <td>{{ $item->platform }}</td>
                                <td>{{ $item->content_type }}</td>
                                <td>{{ $item->enabled ? '启用' : '禁用' }}</td>
                                <td>{{ $item->priority }}</td>
                                <td class="text-start">
                                    @if($item->content_type === 'subscription_url')
                                        <span class="text-muted">{{ $item->subscription_url }}</span>
                                    @else
                                        <span class="text-muted">JSON 配置</span>
                                    @endif
                                </td>
                                <td>
                                    <button
                                        type="button"
                                        class="btn btn-sm btn-outline-primary edit-btn"
                                        data-id="{{ $item->id }}"
                                        data-name="{{ $item->name }}"
                                        data-platform="{{ $item->platform }}"
                                        data-content-type="{{ $item->content_type }}"
                                        data-config-content="{{ $item->config_content }}"
                                        data-subscription-url="{{ $item->subscription_url }}"
                                        data-enabled="{{ $item->enabled ? 1 : 0 }}"
                                        data-priority="{{ $item->priority }}"
                                    >编辑</button>

                                    <form action="{{ route('admin.singbox.subscriptions.delete') }}" method="POST" class="d-inline">
                                        @csrf
                                        <input type="hidden" name="id" value="{{ $item->id }}">
                                        <button type="submit" class="btn btn-sm btn-outline-danger" onclick="return confirm('确认删除该配置？')">删除</button>
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
function toggleFields() {
    const type = document.getElementById('content_type').value;
    const subscriptionField = document.getElementById('subscription_url');
    const configField = document.getElementById('config_content');
    if (type === 'subscription_url') {
        subscriptionField.required = true;
        configField.required = false;
    } else {
        subscriptionField.required = false;
        configField.required = true;
    }
}

document.getElementById('content_type').addEventListener('change', toggleFields);
toggleFields();

document.querySelectorAll('.edit-btn').forEach(function (button) {
    button.addEventListener('click', function () {
        document.getElementById('id').value = this.dataset.id || '';
        document.getElementById('name').value = this.dataset.name || '';
        document.getElementById('platform').value = this.dataset.platform || 'windows';
        document.getElementById('content_type').value = this.dataset.contentType || 'config_json';
        document.getElementById('subscription_url').value = this.dataset.subscriptionUrl || '';
        document.getElementById('config_content').value = this.dataset.configContent || '';
        document.getElementById('enabled').checked = this.dataset.enabled === '1';
        document.getElementById('priority').value = this.dataset.priority || 0;
        toggleFields();
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
});

document.getElementById('resetForm').addEventListener('click', function () {
    document.getElementById('subscriptionForm').reset();
    document.getElementById('id').value = '';
    document.getElementById('enabled').checked = true;
    document.getElementById('priority').value = 0;
    document.getElementById('platform').value = 'windows';
    document.getElementById('content_type').value = 'config_json';
    toggleFields();
});
</script>
@endpush
