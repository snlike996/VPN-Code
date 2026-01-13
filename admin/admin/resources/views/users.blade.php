@extends('layouts.app')
@section('title')
用户管理
@endsection
@section('content')
    <div class="col-lg-12 grid-margin stretch-card">
        <div class="card">
            <div class="card-body">

                    <h4 class="card-title">所有用户</h4>
                    @if (count($online)>0)
                        @if (session('done'))
                            <div class="alert alert-success">
                                {{ session('done') }}
                            </div>
                        @endif
                        @if (session('not'))
                            <div class="alert alert-danger">
                                {{ session('not') }}
                            </div>
                        @endif
                        <div id="cancelMessage" class="alert alert-info" style="display:none;">
                            删除已取消。
                        </div>
                            <div class="row">

                                <div class="col-md-12">
                                    <form action="{{url()->current()}}">
                                    <div class="input-group mb-3">
                                        <input type="text" name="search" class="form-control input-text" value="{{ request('search') }}" placeholder="按姓名或邮箱搜索...">
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-primary btn-md" type="submit"><i class="fa fa-search"></i></button>
                                        </div>
                                    </div>

                                    </form>
                                </div>
                            </div>
                        <hr>
                        </p>
                        <div class="table-responsive">
                            <table class="table table-striped">
                                <thead>
                                <tr>
                                    <th>
                                        序号
                                    </th>
                                    <th>
                                        姓名
                                    </th>
                                    <th>
                                        邮箱
                                    </th>
                                    <th>
                                        注册时间
                                    </th>
                                    <th>
                                        操作
                                    </th>

                                </tr>
                                </thead>
                                <tbody>
                                @foreach ($online as $user)
                                    <tr>
                                        <td>{{ $loop->iteration }}</td>
                                        <td>
                                            {{ucwords($user->name)}}
                                        </td>
                                        <td>
                                            {{$user->email}}
                                        </td>
                                        
                                        <td>
                                            {{ $user->created_at->format('Y年m月d日') }}
                                        </td>
                                        <td>
                                            <a class="pl-3 text-danger" href="#"
                                               onclick="confirmDelete({{ $user->id }})">
                                                <i class="fa-solid fa-arrow-right-from-bracket"></i> 删除
                                            </a>

                                        </td>

                                    </tr>
                                @endforeach
                                </tbody>
                            </table>
                        </div>

                        <div style="display: flex;justify-content: end;padding-top: inherit;">
                            @if ($online->lastPage() > 1)
                                <span aria-label="Page navigation example">
                        <ul class="pagination">
                            <!-- Previous Page Link -->
                            @if ($online->onFirstPage())
                                <li class="page-item disabled">
                                    <span class="page-link" aria-hidden="true">&laquo;</span>
                                </li>
                            @else
                                <li class="page-item">
                                    <a class="page-link" href="{{ $online->previousPageUrl() }}" aria-label="Previous">
                                        <span aria-hidden="true">&laquo;</span>
                                    </a>
                                </li>
                            @endif

                        <!-- Pagination Elements -->
                            @for ($i = 1; $i <= $online->lastPage(); $i++)
                                <li class="page-item {{ $online->currentPage() == $i ? 'active' : '' }}">
                                    <a class="page-link" href="{{ $online->url($i) }}">{{ $i }}</a>
                                </li>
                            @endfor

                        <!-- Next Page Link -->
                            @if ($online->hasMorePages())
                                <li class="page-item">
                                    <a class="page-link" href="{{ $online->nextPageUrl() }}" aria-label="Next">
                                        <span aria-hidden="true">&raquo;</span>
                                    </a>
                                </li>
                            @else
                                <li class="page-item disabled">
                                    <span class="page-link" aria-hidden="true">&raquo;</span>
                                </li>
                            @endif
                        </ul>
                    </span>
                            @endif
                        </div>
                    @else
                        <h4 class="text-danger text-center">暂无在线用户</h4>
                        <hr>

                    @endif
            </div>
        </div>
    </div>
@endsection
@push('script')
    <script>
        function confirmDelete(userId) {
            var result = confirm("确定要删除此用户吗？");
            if (result) {
                window.location.href = "{{ route('user.delete', ['id' => ':userId']) }}".replace(':userId', userId);
            } else {
                document.getElementById('cancelMessage').style.display = 'block';
                setTimeout(function() {
                    document.getElementById('cancelMessage').style.display = 'none';
                }, 3000);
            }
        }
    </script>
@endpush
@push('style')
    <style>
        .btn{

            border-radius: 25px;

        }

        .new{
            font-size: 12px;
        }

        .card{

            padding: 20px;
            border:none;


        }


        .active{

            background: #f6f7fb !important;
            border-color: #f6f7fb !important;
            color: #000 !important;
            font-size: 12px;

        }

        .inputs{

            position: relative;

        }

        .form-control {
            text-indent: 15px;
            border: none;
            height: 45px;
            border-radius: 0px;
            border-bottom: 1px solid #eee;
        }

        .form-control:focus {
            color: #495057;
            background-color: #fff;
            border-color: #eee;
            outline: 0;
            box-shadow: none;
            border-bottom: 1px solid blue;
        }


        .form-control:focus  {
            color: blue;
        }

        .inputs i{

            position: absolute;
            top: 14px;
            left: 4px;
            color: #b8b9bc;
        }


    </style>
@endpush
