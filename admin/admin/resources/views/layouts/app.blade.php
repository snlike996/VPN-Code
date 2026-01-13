<!DOCTYPE html>
<html lang="en">

<head>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>VPN管理后台 | @yield('title')</title>
    <meta name="csrf-token" content="{{ csrf_token() }}">
    @stack('style')
    <!-- plugins:css -->
    <link rel="stylesheet" href="{{ asset('css/bootstrap.min.css') }}">
    <link rel="stylesheet" href="{{ asset('css/app.css') }}">
    <link rel="stylesheet" href="{{ asset('css/animate.min.css') }}">
    <link rel="stylesheet" href="{{ asset('css/icons.min.css') }}">
    <link rel="stylesheet" href="{{ asset('css/all.min.css') }}">
    <link rel="stylesheet" href="{{ asset('css/feather.css') }}">
    <!-- endinject -->
    <!-- Plugin css for this page -->
    <link rel="stylesheet" href="{{ asset('css/dataTables.bootstrap4.css') }}">

    <!-- inject:css -->
    <link rel="stylesheet" href="{{ asset('css/style.css') }}">
    <!-- endinject -->
    <link rel="shortcut icon" href="{{ App\CPU\Helpers::getShortLogoSetting() }}" />

@vite(['resources/js/app.js'])

</head>

<body>
    <div class="container-scroller">

        <script>
            // Create a preloader element
            var preloader = document.createElement("div");
            preloader.id = "preloader";

            preloader.style.position = "fixed";
            preloader.style.top = "0";
            preloader.style.left = "0";
            preloader.style.width = "100%";
            preloader.style.height = "100%";
            preloader.style.backgroundColor = "white";
            preloader.style.display = "flex";
            preloader.style.justifyContent = "center";
            preloader.style.alignItems = "center";
            preloader.style.zIndex = "9999";

            var eyeImage = document.createElement("img");
            eyeImage.src = '{{ asset('storage/images/eye.gif') }}';
            eyeImage.alt = '加载中...';

            // Style the image
            eyeImage.style.width = "200px";
            eyeImage.style.height = "200px";
            eyeImage.style.objectFit = "cover";

            preloader.appendChild(eyeImage);

            document.body.appendChild(preloader);

            window.onload = function() {
                setTimeout(function() {
                    preloader.style.display = "none";
                }, 500);

            };
        </script>
        <!-- partial:partials/_navbar.html -->
        @include('partials.navbar')
        <!-- partial -->
        <div class="container-fluid page-body-wrapper">
            <!-- partial:partials/_settings-panel.html -->
           {{--  @include('partials.settings-panel') --}}
            <!-- partial -->
            <!-- partial:partials/_sidebar.html -->
            @include('partials.sidebar')
            <!-- partial -->
            <div class="main-panel">

                @yield('content')
                @stack('scripts')

                <!-- content-wrapper ends -->
                <!-- partial:partials/_footer.html -->
                @include('partials.footer')
                <!-- partial -->
            </div>
            <!-- main-panel ends -->
        </div>
        <!-- page-body-wrapper ends -->
    </div>
    <!-- container-scroller -->

    <!-- plugins:js -->
   
    <script src="{{ asset('js/jquery-3.7.1.min.js') }}"></script>
    <script src="{{ asset('js/bootstrap.bundle.min.js') }}"></script>
    <script src="{{ asset('js/vendor.bundle.base.js') }}"></script>
    <!-- endinject -->
    <!-- Plugin js for this page -->
    <script src="{{ asset('js/all.min.js') }}"></script>
    <script src="{{ asset('js/wow.min.js') }}"></script>
    <script>
        new WOW().init();
    </script>
    <script src="{{ asset('js/icons.min.js') }}"></script>

    <!-- End plugin js for this page -->
    <!-- inject:js -->
    <script src="{{ asset('js/off-canvas.js') }}"></script>
    <script src="{{ asset('js/hoverable-collapse.js') }}"></script>
    <script src="{{ asset('js/template.js') }}"></script>
    <script src="{{ asset('js/settings.js') }}"></script>
    <!-- endinject -->
    <!-- Custom js for this page-->
    <script src="{{ asset('js/dashboard.js') }}"></script>
    <!-- End custom js for this page-->
    @stack('script')
</body>

</html>
