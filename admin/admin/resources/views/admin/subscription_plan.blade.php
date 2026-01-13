@extends('layouts.app')

@section('title', '订阅计划')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none bg-light text-dark rounded-0">
        <div class="p-3">
            <h4 class="card-title text-dark">订阅计划</h4>

            {{-- Flash Messages --}}
            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif
            <div id="cancelMessage" class="alert alert-info" style="display:none;">操作已取消</div>

            {{-- Search & Add --}}
            <div class="row mb-3">
                <div class="col-md-6">
                    <form action="{{ url()->current() }}">
                        <div class="input-group">
                            <input type="text" name="search" class="form-control search-input"
                                   value="{{ request('search') }}" placeholder="按套餐名称搜索">
                            <button class="btn search-btn" type="submit">
                                <i class="fa fa-search text-dark"></i>
                            </button>
                        </div>
                    </form>
                </div>
                <div class="col-md-6 text-end">
                    <button class="btn btn-primary btn-rounded mb-4" data-bs-toggle="modal" data-bs-target="#addModal">添加订阅计划</button>
                </div>
            </div>
        </div>

        <hr class="border-secondary">

        {{-- Table --}}
       <div class="px-3">
       <div class="table-responsive shadow-sm rounded">
            <table class="table table-striped table-light text-dark mb-0 align-middle">
                <thead class="table-secondary text-dark bg-opacity-10">
                    <tr class="text-center">
                        <th>套餐名称</th>
                        <th>有效期(天)</th>
                        <th>价格</th>
                        <th>开始日期</th>
                        <th>到期日期</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($plans as $plan)
                        <tr class="text-center text-dark">
                            <td>{{ $plan->pakage_name }}</td>
                            <td>{{ $plan->validity }}</td>
                            <td>${{ number_format($plan->price, 2) }}</td>
                            <td>{{ $plan->start_date ? \Carbon\Carbon::parse($plan->start_date)->format('Y年n月j日') : '无' }}</td>
                            <td>{{ $plan->expired_date ? \Carbon\Carbon::parse($plan->expired_date)->format('Y年n月j日') : '无' }}</td>
                            <td>
                                <a href="javascript:void(0)" class="text-primary me-2" onclick="openEditModal({{ $plan->id }}, '{{ $plan->pakage_name }}', '{{ $plan->validity }}', '{{ $plan->price }}')">
                                    <i class="fas fa-edit"></i> 编辑
                                </a>

                                <a href="javascript:void(0)" class="text-danger" onclick="confirmDelete({{ $plan->id }})">
                                    <i class="fa-solid fa-trash"></i> 删除
                                </a>

                                <form id="delete-form-{{ $plan->id }}" action="{{ route('subscription-plan.destroy', $plan->id) }}" method="POST" style="display: none;">
                                    @csrf
                                    @method('DELETE')
                                </form>

                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="7" class="text-center text-danger">未找到订阅计划</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <!-- Pagination -->
          <div class="d-flex justify-content-end pt-3 pl-3">
                {{ $plans->links('pagination::bootstrap-5') }}
          </div>
        </div>

        
    </div>
</div>

{{-- Add Modal --}}
<div class="modal fade" id="addModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content bg-light text-dark">
            <form action="{{ route('subscription-plan.store') }}" method="POST">
                @csrf
                <div class="modal-header">
                    <h5 class="modal-title">添加订阅计划</h5>
                    <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label>套餐名称</label>
                        <input type="text" name="pakage_name" class="form-control input-dark" required>
                    </div>
                    <div class="mb-3">
                        <label>有效期(天)</label>
                        <input type="number" name="validity" class="form-control input-dark" required>
                    </div>
                    <div class="mb-3">
                        <label>价格</label>
                        <input type="number" step="0.01" name="price" class="form-control input-dark" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary btn-hover" data-bs-dismiss="modal">关闭</button>
                    <button type="submit" class="btn btn-primary btn-hover">保存</button>
                </div>
            </form>
        </div>
    </div>
</div>

{{-- Edit Modal --}}
<div class="modal fade" id="editModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content bg-light text-dark">
            <form id="editForm" method="POST">
                @csrf @method('PUT')
                <div class="modal-header">
                    <h5 class="modal-title">编辑订阅计划</h5>
                    <button type="button" class="btn-close btn-close-dark" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="mb-3">
                        <label>套餐名称</label>
                        <input type="text" id="edit_pakage_name" name="pakage_name" class="form-control input-dark" required>
                    </div>
                    <div class="mb-3">
                        <label>有效期(天)</label>
                        <input type="number" id="edit_validity" name="validity" class="form-control input-dark" required>
                    </div>
                    <div class="mb-3">
                        <label>价格</label>
                        <input type="number" step="0.01" id="edit_price" name="price" class="form-control input-dark" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button class="btn btn-secondary btn-hover" data-bs-dismiss="modal">关闭</button>
                    <button type="submit" class="btn btn-primary btn-hover">更新</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('style')
<style>
/* Search Input */
.search-input {
    background-color: #eee;
    color: #111;
    border: none;
    padding-left: 15px;
    height: 42px;
}
.search-input::placeholder { color: #bbb; }
.search-input:focus { background-color: #eee; outline: none; }

/* Search Button */
.search-btn {
    background-color: #0df40d !important;
    border: none !important;
    color: #fff;
    padding: 0 18px;
}
.search-btn:hover { opacity: 0.85; }

/* Dark Inputs */
.input-dark {
    background-color: #eee !important;
    border: 1px solid #eee !important;
    color: #111 !important;
}
.input-dark:focus {
    background-color: #eee !important;
    border-color: #0df40d !important;
    
    color: #111 !important;
}

/* Buttons */
.btn-primary {
    background-color: #0df40d !important;
    border-color: #0df40d !important;
    color: #111 !important;
}


/* Secondary buttons */
.btn-secondary.btn-hover {
    background-color: #444 !important;
    border-color: #444 !important;
    color: #111 !important;
}
.btn-secondary.btn-hover:hover {
    background-color: #555 !important;
}

/* Table */
.table-striped.table-light tbody tr:nth-of-type(odd) { background-color: #252536; }
.table-striped.table-light tbody tr:nth-of-type(even) { background-color: #eee; }
.table-light th, .table-light td { border-color: #f1f1f1 !important; }

/* Modal background */
.modal-content.bg-light {
    background-color: #eee !important;
    color: #fff;
}


</style>
@endpush

@push('script')
<script>
function openEditModal(id, pakage_name, validity, price) {
    $('#editModal').modal('show');
    $('#editForm').attr('action', '{{ route("subscription-plan.update", ":id") }}'.replace(':id', id));
    $('#edit_pakage_name').val(pakage_name);
    $('#edit_validity').val(validity);
    $('#edit_price').val(price);
}

function confirmDelete(planId) {
    if (confirm("确定要删除此订阅计划吗?")) {
        document.getElementById('delete-form-' + planId).submit();
    } else {
        $('#cancelMessage').fadeIn().delay(3000).fadeOut();
    }
}

</script>
@endpush
