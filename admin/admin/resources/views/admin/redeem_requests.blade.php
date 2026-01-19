@extends('layouts.app')
@section('title') 口令红包审核 @endsection
@section('content')
<div class="container-fluid p-0 min-vh-100 bg-light">
    <div class="card bg-light text-dark rounded-0 shadow-none p-3">
        <h4 class="card-title text-dark">口令红包审核</h4>

        @if (session('done'))
            <div class="alert alert-success">{{ session('done') }}</div>
        @endif
        @if (session('not'))
            <div class="alert alert-danger">{{ session('not') }}</div>
        @endif

        <div class="row mb-3">
            <div class="col-md-7">
                <form action="{{ url()->current() }}" method="GET">
                    <div class="input-group mb-3">
                        <input type="text" name="search" class="form-control input-dark"
                               value="{{ request('search') }}" placeholder="按姓名、邮箱、口令搜索">
                        <button class="btn btn-primary" type="submit">
                            <i class="fa fa-search text-dark"></i>
                        </button>
                    </div>
                </form>
            </div>
            <div class="col-md-3">
                <form action="{{ url()->current() }}" method="GET">
                    <div class="input-group mb-3">
                        <select name="status" class="form-control input-dark" onchange="this.form.submit()">
                            <option value="">全部状态</option>
                            <option value="pending" {{ request('status') === 'pending' ? 'selected' : '' }}>待审核</option>
                            <option value="approved" {{ request('status') === 'approved' ? 'selected' : '' }}>已通过</option>
                            <option value="rejected" {{ request('status') === 'rejected' ? 'selected' : '' }}>已拒绝</option>
                        </select>
                    </div>
                </form>
            </div>
        </div>

        <hr class="border-secondary">

        <div class="table-responsive shadow-sm rounded">
            <table class="table table-striped table-light text-dark mb-0 align-middle">
                <thead class="table-secondary text-dark bg-opacity-10">
                    <tr class="text-center">
                        <th>姓名</th>
                        <th>邮箱</th>
                        <th>口令</th>
                        <th>状态</th>
                        <th>提交时间</th>
                        <th>操作</th>
                    </tr>
                </thead>
                <tbody>
                    @if (count($requests) > 0)
                        @foreach ($requests as $req)
                            <tr class="text-center text-dark hover-row">
                                <td>{{ $req->user->name ?? '-' }}</td>
                                <td>{{ $req->user->email ?? '-' }}</td>
                                <td>{{ $req->code }}</td>
                                <td>
                                    @if ($req->status === 'pending')
                                        <span class="badge bg-warning text-dark">待审核</span>
                                    @elseif ($req->status === 'approved')
                                        <span class="badge bg-success">已通过</span>
                                    @else
                                        <span class="badge bg-danger">已拒绝</span>
                                    @endif
                                </td>
                                <td>{{ $req->created_at ? $req->created_at->format('Y年n月j日 H:i') : '-' }}</td>
                                <td>
                                    @if ($req->status === 'pending')
                                        <form class="d-inline" method="POST" action="{{ route('admin.redeemRequests.approve', $req->id) }}" onsubmit="return confirm('确定通过该口令提现吗？');">
                                            @csrf
                                            <button class="btn btn-success btn-sm">通过</button>
                                        </form>
                                        <form class="d-inline" method="POST" action="{{ route('admin.redeemRequests.reject', $req->id) }}" onsubmit="return confirm('确定拒绝该口令提现吗？');">
                                            @csrf
                                            <button class="btn btn-danger btn-sm">拒绝</button>
                                        </form>
                                    @else
                                        <span class="text-muted">已处理</span>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                    @else
                        <tr><td colspan="6" class="text-center text-danger">暂无记录</td></tr>
                    @endif
                </tbody>
            </table>
        </div>

        <div class="d-flex justify-content-end pt-3 pl-3">
            {{ $requests->links('pagination::bootstrap-5') }}
        </div>
    </div>
</div>
@endsection

@push('style')
<style>
.container-fluid { max-width: 100% !important; padding-left:0 !important; padding-right:0 !important; }
.card { border-radius:0 !important; }
.table-light th, .table-light td { border-color: #f1f1f1 !important; }
.table-striped.table-light tbody tr:nth-of-type(odd) { background-color: #252536; }
.table-striped.table-light tbody tr:nth-of-type(even) { background-color: #1f1f2e; }
.table-responsive { border-radius:12px; overflow:hidden; }

.btn-primary { background-color: #0df40d !important; border-color: #0df40d !important; }

.input-dark {
    background-color: #eee!important;
    border: 1px solid #111 !important;
    color: #111 !important;
}
.input-dark:focus {
    background-color: #eee !important;
    border-color: #0df40d !important;
    color: #111 !important;
}
</style>
@endpush
