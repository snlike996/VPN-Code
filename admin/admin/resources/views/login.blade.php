<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>VPN管理后台 | 登录</title>

    <!-- Bootstrap & Core CSS -->
    <link rel="stylesheet" href="{{ asset('css/bootstrap.min.css') }}">
    <link rel="stylesheet" href="{{ asset('css/app.css') }}">
    <link rel="stylesheet" href="{{ asset('css/all.min.css') }}">
    <link rel="stylesheet" href="{{ asset('css/feather.css') }}">
    <link rel="stylesheet" href="{{ asset('css/dataTables.bootstrap4.css') }}">
    <link rel="stylesheet" type="text/css" href="{{ asset('css/select.dataTables.min.css') }}">
    <link rel="stylesheet" href="{{ asset('css/style.css') }}">

    <!-- Favicon -->
    <link rel="shortcut icon" href="{{ App\CPU\Helpers::getShortLogoSetting() }}" />

    <style>
        body {
            background-color: #eee !important; /* full page dark */
            min-height: 100vh;
        }
        .auth-form-dark {
            background-color: #eee !important; /* form card */
        }
        .form-control.bg-light {
            background-color: #eee !important;
        }
        .form-control.bg-light:focus {
            background-color: #eee !important;
            outline: none;
            box-shadow: none;
        }
        .btn-primary {
            background-color: #0df40d !important;
            border-color: #0df40d !important;
            color: #111 !important;
            font-weight: 600 !important;
        }
        .btn-primary:hover {
            opacity: 0.9;
        }
    </style>
</head>

<body>

    <!-- Error Alerts -->
    @if ($errors->any())
        <div class="alert alert-danger w-100 text-center">
            <ul class="mb-0">
                @foreach ($errors->all() as $error)
                    <li>{{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    @if (Session::has('error'))
        <div class="alert alert-danger w-100 text-center">
            {{ Session::get('error') }}
        </div>
    @endif
<div class="d-flex align-items-center justify-content-center min-vh-100">
 <!-- Login Card -->
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-4">
                <div class="auth-form-dark text-left py-5 px-4 px-sm-5 rounded shadow">

                    <!-- <div class="brand-logo text-center mb-3">
                        <img src="{{ App\CPU\Helpers::getAppLogoSetting() }}" width="50" alt="logo">
                    </div> -->

                    <h4 class="text-center text-dark">您好,管理员 👋</h4>
                    <h6 class="font-weight-light text-center mb-4 text-secondary">登录以继续</h6>

                    <form method="POST" action="{{ route('admin.login') }}">
                        @csrf
                        <div class="form-group">
                            <input type="email" name="email" class="form-control form-control-lg bg-light text-dark border-0"
                                   placeholder="邮箱" required>
                        </div>
                        <div class="form-group">
                            <input type="password" name="password" class="form-control form-control-lg bg-light text-dark border-0"
                                   placeholder="密码" required>
                        </div>
                        <div class="mt-3">
                            <button type="submit"
                                    class="btn btn-block btn-primary btn-lg font-weight-medium auth-form-btn">
                                登录
                            </button>
                        </div>
                    </form>

                </div>
            </div>
        </div>
    </div>
</div>
   

    <!-- Scripts -->
    <script src="{{ asset('js/vendor.bundle.base.js') }}"></script>
    <script src="{{ asset('js/off-canvas.js') }}"></script>
    <script src="{{ asset('js/hoverable-collapse.js') }}"></script>
    <script src="{{ asset('js/template.js') }}"></script>
    <script src="{{ asset('js/settings.js') }}"></script>
    <script src="{{ asset('js/todolist.js') }}"></script>
</body>
</html>
