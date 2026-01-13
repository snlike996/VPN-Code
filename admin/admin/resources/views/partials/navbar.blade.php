<nav class="navbar col-lg-12 col-12 p-0 fixed-top d-flex flex-row">
    <!-- Brand -->
    <!-- <div class="text-center navbar-brand-wrapper d-flex align-items-center justify-content-center bg-light">
        <a class="navbar-brand brand-logo mr-5" href="{{ route('admin.dashboard') }}">
            VPN Admin
        </a>
        <a class="navbar-brand brand-logo-mini" href="{{ route('admin.dashboard') }}">
            <img src="{{ App\CPU\Helpers::getShortLogoSetting() }}" alt="logo" style="height:35px;"/>
        </a>
    </div> -->
    <div class="text-center navbar-brand-wrapper d-flex align-items-center justify-content-center bg-light">
    <a class="navbar-brand brand-logo mr-5" href="{{ route('admin.dashboard') }}">
        <i class="fa fa-globe"></i> <!-- VPN-like icon -->
    </a>
</div>

    <!-- Navbar Menu -->
    <div class="navbar-menu-wrapper d-flex align-items-center justify-content-end bg-light">
        <button class="navbar-toggler navbar-toggler align-self-center text-light" type="button" data-toggle="minimize">
            <i class="fa-solid fa-bars"></i>
        </button>

        <ul class="navbar-nav navbar-nav-right">
            <li class="nav-item nav-profile dropdown">
                <a class="n-nav-link dropdown-toggle d-flex align-items-center" href="#" data-toggle="dropdown" id="profileDropdown">
                    <img src="{{ asset('storage/images/faces/admin.png') }}" alt="profile" class="rounded-circle" style="width:35px;height:35px;object-fit:cover;border:1px solid #555;">
                    <span class="ms-2 text-dark d-none d-md-inline">管理员</span>
                </a>
                <div class="dropdown-menu dropdown-menu-right navbar-dropdown bg-light border-secondary" aria-labelledby="profileDropdown">
                    <a class="dropdown-item text-dark d-flex align-items-center" href="{{ route('admin.logout') }}">
                        <i class="fa-solid fa-person-through-window me-2"></i>
                        退出登录
                    </a>
                </div>
            </li>
        </ul>

        <button class="navbar-toggler navbar-toggler-right d-lg-none align-self-center text-dark" type="button" data-toggle="offcanvas">
            <i class="fa-solid fa-bars"></i>
        </button>
    </div>
</nav>

@push('style')
<style>
/* Navbar Dark Mode */
.navbar {
    background-color: #eee !important;
    border-bottom-color: #646464 !important;
}
.n-nav-link{
    color: rgba(255, 255, 255, 0.5) !important;
    padding: 0.5rem 0px;
    transition: 0.2s ease-in-out;
    text-decoration: none !important;
    font-size: 1rem !important;
}
.navbar .nav-link {
    color: #111 !important;
    transition: color 0.2s ease;
}

.navbar .nav-link:hover {
    color: #111 !important;
}

.navbar .dropdown-menu {
    background-color: #eee !important;
    border-color: #444 !important;
}

.navbar .dropdown-item {
    color: #111 !important;
}

.navbar .dropdown-item:hover {
    background-color: #eee !important;
    color: #111 !important;
}

.navbar .navbar-toggler {
    border-color: #111;
}

.navbar .navbar-toggler:hover {
    background-color: #eee;
}
</style>
@endpush

@push('script')
<script>
document.addEventListener('DOMContentLoaded', function() {
    'use strict';

    // Offcanvas toggle for small screens
    var offcanvasToggle = document.querySelector('[data-toggle="offcanvas"]');
    var sidebarOffcanvas = document.querySelector('.sidebar-offcanvas');
    if (offcanvasToggle) {
        offcanvasToggle.addEventListener('click', function() {
            if (sidebarOffcanvas) {
                sidebarOffcanvas.classList.toggle('active');
            }
        });
    }

    // Minimize sidebar toggle for desktop
    var minimizeToggle = document.querySelector('[data-toggle="minimize"]');
    if (minimizeToggle) {
        minimizeToggle.addEventListener('click', function() {
            document.body.classList.toggle('sidebar-icon-only');
        });
    }
});
</script>
@endpush
