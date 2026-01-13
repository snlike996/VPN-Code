@extends('layouts.app')
@section('title', '所有用户')

@section('content')
<div class="container-fluid p-0 min-vh-100 bg-light">

    <!-- Header -->
    <div class="row mb-4 px-3 pt-4">
        <div class="col-12 d-flex justify-content-between align-items-center">
            <h4 class="text-dark fw-bold">所有用户</h4>
            <a href="" class="btn btn-primary text-dark" data-bs-toggle="modal" data-bs-target="#modalRegisterForm">添加用户</a>
        </div>
    </div>

    <!-- Alerts -->
    @if(session('done'))
        <div class="alert alert-success px-3">{{ session('done') }}</div>
    @endif
    @if(session('not'))
        <div class="alert alert-danger px-3">{{ session('not') }}</div>
    @endif
    <div id="cancelMessage" class="alert alert-info px-3" style="display:none;">已取消删除</div>

    <!-- Search -->
    <div class="row mb-3 px-3">
        <div class="col-md-6">
            <form action="{{ url()->current() }}">
                <div class="input-group">
                    <input type="text" name="search" class="form-control search-input"
                           value="{{ request('search') }}" placeholder="按姓名搜索">
                    <button class="btn search-btn" type="submit">
                        <i class="fa fa-search text-dark"></i>
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Users Table -->
    <div class="row px-3">
        <div class="col-12">
            <div class="table-responsive shadow-sm rounded">
                <table class="table table-striped table-light text-dark mb-0 align-middle">
                    <thead class="table-secondary text-dark bg-opacity-10">
                        <tr class="text-center">
                            <th>姓名</th>
                            <th>邮箱</th>
                            <th>会员</th>
                            <th>价格</th>
                            <th>有效期</th>
                            <th>开始日期</th>
                            <th>到期日期</th>
                            <th>剩余天数</th>
                            <th>加入日期</th>
                            <th>设备</th>
                            <th>操作</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($users as $user)
                        <tr class="text-center">
                            <td>{{ $user->name }}</td>
                            <td>{{ $user->email }}</td>
                            <td>
                                @if($user->isPremium)
                                    <span class="badge badge-success">会员</span>
                                @else
                                    <span class="badge badge-danger">免费</span>
                                @endif
                            </td>
                            <td>{{ $user->price }}</td>
                            <td>{{ $user->validity ?? '无' }}</td>
                            <td>{{ $user->start_date ? \Carbon\Carbon::parse($user->start_date)->format('Y年n月j日') : '无' }}</td>
                            <td>{{ $user->expired_date ? \Carbon\Carbon::parse($user->expired_date)->format('Y年n月j日') : '无' }}</td>
                            <td>
                                @php
                                    $daysLeft = $user->expired_date
                                        ? now()->diffInDays($user->expired_date, false)
                                        : null;
                                @endphp

                                @if (is_null($daysLeft))
                                    <span class="badge bg-secondary">无订阅</span>
                                @elseif ($daysLeft > 0)
                                    <span class="badge bg-success">
                                        剩余{{ (int) $daysLeft }}天
                                    </span>
                                @elseif ($daysLeft === 0)
                                    <span class="badge bg-warning">今天到期</span>
                                @else
                                    <span class="badge bg-danger">
                                        已过期{{ abs((int) $daysLeft) }}天
                                    </span>
                                @endif
                            </td>

                            <td>{{ $user->created_at->format('Y年n月j日') }}</td>
                            <td>{{ $user->device ?? '0' }}</td>
                            <td>
                                <a class="me-2 text-primary" href="#" onclick="openOrderModal({{ $user->id }}, '{{ $user->isPremium }}', '{{ $user->pakage_name }}','{{ $user->price }}', '{{ $user->validity }}')">
                                        <i class="fas fa-edit"></i> 会员/免费
                                    </a>
                                <a class="text-primary me-2" href="#" onclick="openEditModal({{ $user->id }}, '{{ $user->name }}', '{{ $user->email }}', '{{ $user->password }}','{{ $user->admin_password }}', '{{ $user->device }}')">
                                    <i class="fas fa-edit"></i> 编辑
                                </a>
                                <form id="deleteForm" method="POST" style="display: none;">
                                    @csrf
                                    @method('DELETE')
                                </form>
                                <a class="text-danger" href="#" onclick="confirmDelete({{ $user->id }})">
                                    <i class="fa-solid fa-arrow-right-from-bracket"></i> 删除
                                </a>
                            </td>
                        </tr>
                        @empty
                        <tr>
                            <td colspan="11" class="text-center text-danger">暂无用户</td>
                        </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
           <div class="d-flex justify-content-end pt-3 pl-3">
                {{ $users->links('pagination::bootstrap-5') }}
            </div>

        </div>
    </div>
</div>

<!-- Add User Modal -->
<div class="modal fade" id="modalRegisterForm" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content bg-light text-dark">
            <div class="modal-header text-center">
                <h4 class="modal-title w-100 font-weight-bold">添加用户</h4>
             <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal" aria-label="Close"></button>

            </div>
            <form action="{{ route('admin.user.add') }}" method="POST" enctype="multipart/form-data">
                @csrf
                <div class="modal-body mx-3">
                    <div class="md-form mb-3">
                        <label>姓名</label>
                        <input type="text" name="name" class="form-control">
                    </div>
                    <div class="md-form mb-3">
                        <label>邮箱</label>
                        <input type="email" name="email" class="form-control">
                    </div>
                    <div class="md-form mb-3">
                        <label>密码</label>
                        <input type="password" name="password" class="form-control">
                    </div>
                    <div class="md-form mb-3">
                        <label>设备</label>
                        <input type="number" name="device" min="1" class="form-control" value="{{ $settings['device_limit'] ?? 1 }}">
                    </div>
                </div>
                <div class="modal-footer d-flex justify-content-center">
                    <button type="submit" class="btn btn-primary">添加</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- Edit User Status Modal -->
<div class="modal fade" id="orderModal" tabindex="-1" role="dialog" aria-labelledby="editModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content bg-light text-dark">
            <div class="modal-header">
                <h5 class="modal-title">编辑会员/免费</h5>
                <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
             <form id="editUserStatus" action="{{ route('admin.users.status', ['id' => ':id']) }}" method="POST"
                    enctype="multipart/form-data">
                    @csrf
                    <div class="modal-body">
                        <div class="form-group">
                            <label for="isPremium">设置会员</label>
                            <select id="isPremium" name="isPremium" class="form-control">
                                <option value="1">会员</option>
                                <option value="0">免费</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label for="pakage_name">套餐名称</label>
                            <input type="text" name="pakage_name" id="pakage_name" class="form-control">
                        </div>
                        <div class="form-group">
                            <label for="price">价格</label>
                             <input type="number" name="price" id="price" class="form-control">
                        </div>
                        <div class="form-group">
                            <label for="validity">有效期</label>
                            <input type="number" name="validity" id="validity" class="form-control">
                        </div>
                        
                    </div>
                    <div class="modal-footer">
                       <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" aria-label="Close">关闭</button>

                        <button type="submit" class="btn btn-primary">保存更改</button>
                    </div>
                </form>
        </div>
    </div>
</div>

<!-- Edit User Modal -->
<div class="modal fade" id="editModal" tabindex="-1" role="dialog" aria-labelledby="editModalLabel" aria-hidden="true">
    <div class="modal-dialog" role="document">
        <div class="modal-content bg-light text-dark">
            <div class="modal-header">
                <h5 class="modal-title">编辑用户</h5>
                <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal" aria-label="Close"></button>

            </div>
            <form id="editUserUpdate" action="{{ route('admin.user.update', ['id' => ':id']) }}" method="POST">
                @csrf
                <div class="modal-body">
                    <div class="form-group mb-3">
                        <label>姓名</label>
                        <input type="text" name="name" id="name" class="form-control">
                    </div>
                    <div class="form-group mb-3">
                        <label>邮箱</label>
                        <input type="email" name="email" id="email" class="form-control">
                    </div>
                    <div class="form-group mb-3">
                        <label>密码</label>
                        <input type="text" name="password" id="admin_password" class="form-control">
                    </div>
                    <div class="form-group mb-3">
                        <label>设备</label>
                        <input type="number" min="1" name="device" id="device" class="form-control">
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
.btn-primary { background-color: #0df40d !important; border-color: #0df40d !important; }
.badge-success { background-color: #4caf50 !important; }
.badge-danger { background-color: #f44336 !important; }
.modal-content.bg-light { background-color: #f1f1f1 !important; color: #111; }

/* Search Input */
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

/* Rounded Table Container */
.table-responsive.shadow-sm.rounded { border-radius: 10px; overflow-x: auto; box-shadow: 0 0 10px rgba(0,0,0,0.2);}
.table { white-space: nowrap; }
.table td, .table th { white-space: nowrap; text-overflow: ellipsis; overflow: hidden; }
</style>
@endpush

@push('script')
<script>
    
</script>


<script>
    function openOrderModal(id,isPremium,pakage_name,price,validity) {
        $('#orderModal').modal('show');
        $('#editUserStatus').attr('action', '{{ route("admin.users.status", ":id") }}'.replace(':id', id));
        $('#isPremium').val(isPremium);
        $('#pakage_name').val(pakage_name);
        $('#price').val(price);
        $('#validity').val(validity);

        $(document).ready(function () {
        function toggleFields(isFree) {
            const fields = $('#pakage_name, #price, #validity');
            if (isFree) {
                fields.val('').prop('readonly', true);
            } else {
                fields.prop('readonly', false);
            }
        }

        toggleFields($('#isPremium').val() === '0'); // on page load

        $('#isPremium').on('change', function () {
            toggleFields($(this).val() === '0');
        });
    });
    }
</script>
<script>

function openEditModal(id,name,email,password,admin_password,device) {
    $('#editModal').modal('show');
    $('#editUserUpdate').attr('action', '{{ route("admin.user.update", ":id") }}'.replace(':id', id));
    $('#name').val(name);
    $('#email').val(email);
    $('#password').val(password);
    $('#admin_password').val(admin_password);
    $('#device').val(device);
}

function confirmDelete(id) {
    if (confirm("确定要删除此用户吗?")) {
        let form = document.getElementById("deleteForm");
        form.action = "{{ route('user.destroy', ':id') }}".replace(':id', id);
        form.submit();
    }
}
</script>
@endpush
