@extends('layouts.app')
@section('title', 'WireGuard 服务器')

@section('content')
<div class="container-fluid p-0 min-vh-100 bg-light">

    <!-- Header -->
    <div class="row mb-4 px-3 pt-4">
        <div class="col-12 d-flex justify-content-between align-items-center">
            <h4 class="text-dark fw-bold">所有 WireGuard 服务器</h4>
            <a href="#" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#modalAddServer">添加服务器</a>
        </div>
    </div>

    <!-- Alerts -->
    @if(session('done'))
        <div class="alert alert-success px-3">{{ session('done') }}</div>
    @endif
    @if(session('not'))
        <div class="alert alert-danger px-3">{{ session('not') }}</div>
    @endif
    <div id="statusMessage" class="alert d-none px-3" role="alert"></div>
    <div id="cancelMessage" class="alert alert-info px-3" style="display:none;">已取消删除</div>

    <!-- Search -->
    <div class="row mb-3 px-3">
        <div class="col-md-6">
            <form action="{{ url()->current() }}">
                <div class="input-group">
                    <input type="text" name="search" class="form-control search-input"
                           value="{{ request('search') }}" placeholder="按名称搜索">
                    <button class="btn search-btn" type="submit">
                        <i class="fa fa-search text-dark"></i>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Servers Table -->
    <div class="row px-3">
        <div class="col-12">
           <div class="table-responsive shadow-sm rounded">
            <table class="table table-striped table-light text-dark mb-0 align-middle">
                <thead class="table-secondary text-dark bg-opacity-10">
                        <tr class="text-center">
                            <th>名称</th>
                            <th>国家代码</th>
                            <th>城市名称</th>
                            <th>主机</th>
                            <th>端口</th>
                            <th>VPS用户名</th>
                            <th>类型</th>
                            <th>注册时间</th>
                            <th>状态</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($servers as $server)
                        <tr class="text-center">
                            <td>{{ ucwords($server->name) }}</td>
                            <td>{{ $server->country_code }}</td>
                            <td>{{ $server->city_name }}</td>
                            <td>{{ $server->host ?? '-' }}</td>
                            <td>{{ $server->port ?? 22 }}</td>
                            <td>{{ $server->vps_username ?? '-' }}</td>
                            <td>
                                @if($server->type == 1)
                                    <span class="badge bg-primary">会员</span>
                                @else
                                    <span class="badge bg-danger">免费</span>
                                @endif
                            </td>
                            <td>{{ $server->created_at->format('Y年n月j日') }}</td>
                            <td>
                                <div class="form-check form-switch">
                                    <input type="checkbox" class="form-check-input status-toggle-n"
                                           data-id="{{ $server->id }}" {{ $server->status == 1 ? 'checked' : '' }}>
                                </div>
                            </td>
                            <td>
                                <a class="text-primary me-2" href="#"
                                   onclick="openEditModal({{ json_encode([
                                       'id' => $server->id,
                                       'name' => $server->name,
                                       'country_code' => $server->country_code,
                                       'city_name' => $server->city_name,
                                       'host' => $server->host,
                                       'port' => $server->port ?? 22,
                                       'vps_username' => $server->vps_username,
                                       'vps_password' => $server->vps_password,
                                       'type' => $server->type,
                                   ]) }})">
                                    <i class="fas fa-edit"></i> 编辑
                                </a>
                                <a class="text-danger" href="#" onclick="confirmDelete({{ $server->id }})">
                                    <i class="fa-solid fa-trash"></i> 删除
                                </a>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="10" class="text-center text-danger">未找到服务器</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
          <div class="d-flex justify-content-end pt-3 pl-3">
                {{ $servers->links('pagination::bootstrap-5') }}
          </div>
        </div>
    </div>
</div>

<!-- Add Server Modal -->
<div class="modal fade" id="modalAddServer" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content bg-light text-dark">
            <div class="modal-header">
                <h5 class="modal-title">添加服务器</h5>
                <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form action="{{ route('admin.wireguard.add') }}" method="POST">
                @csrf
                <div class="modal-body">
                    <div class="mb-3">
                        <label>名称 <span class="text-danger">*</span></label>
                        <input type="text" name="name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label>国家代码 <span class="text-danger">*</span></label>
                        <input type="text" name="country_code" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label>城市名称 <span class="text-danger">*</span></label>
                        <input type="text" name="city_name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label>主机 (IP) <span class="text-danger">*</span></label>
                        <input type="text" name="host" class="form-control" placeholder="例如: 192.168.1.1 或 vpn.example.com" required>
                    </div>
                    <div class="mb-3">
                        <label>SSH端口</label>
                        <input type="number" name="port" class="form-control" value="22" min="1" max="65535">
                    </div>
                    <div class="mb-3">
                        <label>VPS用户名 <span class="text-danger">*</span></label>
                        <input type="text" name="vps_username" class="form-control" placeholder="例如: root" required>
                    </div>
                    <div class="mb-3">
                        <label>VPS密码 <span class="text-danger">*</span></label>
                        <input type="password" name="vps_password" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label>服务器类型 <span class="text-danger">*</span></label>
                        <select name="type" class="form-control" required>
                            <option value="0">免费</option>
                            <option value="1">会员</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                    <button type="submit" class="btn btn-primary">添加服务器</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit Server Modal -->
<div class="modal fade" id="editModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content bg-light text-dark">
            <div class="modal-header">
                <h5 class="modal-title">编辑服务器</h5>
                <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal"></button>
            </div>
            <form id="editForm" method="POST">
                @csrf
                @method('PUT')
                <div class="modal-body">
                    <div class="mb-3">
                        <label>名称 <span class="text-danger">*</span></label>
                        <input type="text" id="edit_name" name="name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label>国家代码 <span class="text-danger">*</span></label>
                        <input type="text" id="edit_country_code" name="country_code" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label>城市名称 <span class="text-danger">*</span></label>
                        <input type="text" id="edit_city_name" name="city_name" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label>主机 (IP) <span class="text-danger">*</span></label>
                        <input type="text" id="edit_host" name="host" class="form-control" placeholder="例如: 192.168.1.1 或 vpn.example.com" required>
                    </div>
                    <div class="mb-3">
                        <label>SSH端口</label>
                        <input type="number" id="edit_port" name="port" class="form-control" value="22" min="1" max="65535">
                    </div>
                    <div class="mb-3">
                        <label>VPS用户名 <span class="text-danger">*</span></label>
                        <input type="text" id="edit_vps_username" name="vps_username" class="form-control" placeholder="例如: root" required>
                    </div>
                    <div class="mb-3">
                        <label>VPS密码</label>
                        <input type="password" id="edit_vps_password" name="vps_password" class="form-control" placeholder="留空以保持当前密码">
                        <small class="text-muted">留空以保持当前密码</small>
                    </div>
                    <div class="mb-3">
                        <label>类型 <span class="text-danger">*</span></label>
                        <select id="edit_type" name="type" class="form-control" required>
                            <option value="0">免费</option>
                            <option value="1">会员</option>
                        </select>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                    <button type="submit" class="btn btn-primary">保存更改</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('style')
<style>
.table-light th, .table-light td { border-color: #f1f1f1 !important; }
.table-striped.table-light tbody tr:nth-of-type(odd) { background-color: #f1f1f1; }
.table-striped.table-light tbody tr:nth-of-type(even) { background-color: #f1f1f1; }
.btn-primary { background-color: #0df40d !important; border-color: #0df40d !important; color: #111 !important; }
.modal-content.bg-light { background-color: #f1f1f1 !important; color: #eee; }

/* Search Input Group (clean, no border) */
.search-input {
    background-color: #2a2a3f;
    color: #fff;
    border: none;
    padding-left: 15px;
    height: 42px;
}
.search-input::placeholder { color: #bbb; }
.search-input:focus { background-color: #3a3a5a; outline: none; }
.search-btn {
    background-color: #0df40d !important;
    border: none !important;
    color: #fff;
    padding: 0 18px;
}
.search-btn:hover { opacity: 0.85; }
</style>
@endpush

@push('script')
<script>
/**
 * Opens the edit modal and populates form fields with server data.
 * 
 * @param {Object} server - Server data object containing all editable fields
 */
function openEditModal(server) {
    $('#editModal').modal('show');
    $('#editForm').attr('action', '{{ route("admin.wireguard.update", ":id") }}'.replace(':id', server.id));
    $('#edit_name').val(server.name);
    $('#edit_country_code').val(server.country_code);
    $('#edit_city_name').val(server.city_name);
    $('#edit_host').val(server.host);
    $('#edit_port').val(server.port || 22);
    $('#edit_vps_username').val(server.vps_username);
    $('#edit_vps_password').val(''); // Always clear password field for security
    $('#edit_type').val(server.type);
}

/**
 * Confirms and executes server deletion after user approval.
 * 
 * @param {number} serverId - The ID of the server to delete
 */
function confirmDelete(serverId) {
    if(confirm("确定要删除此服务器吗?")) {
        window.location.href = "{{ route('admin.wireguard.delete', ':id') }}".replace(':id', serverId);
    } else {
        $('#cancelMessage').fadeIn().delay(3000).fadeOut();
    }
}

/**
 * Initializes status toggle functionality for server status updates via AJAX.
 */
$(document).ready(function () {
    $('.status-toggle-n').on('change', function () {
        let serverId = $(this).data('id');
        let status = $(this).is(':checked') ? 1 : 0;

        $.ajax({
            url: '{{ route("admin.wireguard.status", ":id") }}'.replace(':id', serverId),
            type: 'POST',
            data: { status: status, _token: '{{ csrf_token() }}' },
            success: function(response) {
                $('#statusMessage').removeClass().addClass('alert alert-success')
                    .text(response.success).removeClass('d-none').fadeIn().delay(3000).fadeOut();
            },
            error: function(xhr) {
                let errorMsg = xhr.responseJSON?.error ?? '发生错误';
                $('#statusMessage').removeClass().addClass('alert alert-danger')
                    .text(errorMsg).removeClass('d-none').fadeIn().delay(3000).fadeOut();
            }
        });
    });
});
</script>
@endpush
