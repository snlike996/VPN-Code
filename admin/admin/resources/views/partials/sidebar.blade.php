<nav class="sidebar sidebar-offcanvas" id="sidebar">
    <ul class="nav">
        <li class="nav-item {{ Request::routeIs('admin.dashboard') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.dashboard') }}">
            <i class="fa-solid fa-table-columns"></i>
                <span class="menu-title pl-3">仪表板</span>
            </a>
        </li>
        <li class="nav-item {{ Request::routeIs('admin.userList') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.userList') }}">
                <i class="fa-solid fa-users"></i>
                <span class="ml-2 menu-title">所有用户</span>
            </a>
        </li>
        
        @php
            $wireguard_status = \App\Models\AppSetting::where('key', 'wireguard_status')->value('value');
        @endphp
        @if($wireguard_status == 1)
        <li class="nav-item {{ Request::routeIs('admin.wireguard.list') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.wireguard.list') }}">
                <i class="fa-solid fa-ticket"></i>
                <span class="ml-2 menu-title">WireGuard 服务器</span>
            </a>
        </li>
        @endif

        @php
            $v2ray_status = \App\Models\AppSetting::where('key', 'v2ray_status')->value('value');
        @endphp
        @if($v2ray_status == 1)
        <li class="nav-item {{ Request::routeIs('admin.v2ray.list') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.v2ray.list') }}">
                <i class="fa-solid fa-window-restore"></i>
                <span class="ml-2 menu-title">V2Ray 服务器</span>
            </a>
        </li>
        @endif

        @php
            $openvpn_status = \App\Models\AppSetting::where('key', 'openvpn_status')->value('value');
        @endphp
        @if($openvpn_status == 1)
        <li class="nav-item {{ Request::routeIs('admin.openvpn.list') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.openvpn.list') }}">
                <i class="fa-solid fa-x-ray"></i>
                <span class="ml-2 menu-title">OpenVPN 服务器</span>
            </a>
        </li>
        @endif
      

        <li class="nav-item {{ Request::routeIs('admin.activeConnections') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.activeConnections') }}">
            <i class="fa-solid fa-signal"></i>
                <span class="ml-2 menu-title">活跃连接</span>
            </a>
        </li>
        <li class="nav-item {{ Request::routeIs('admin.profile') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.profile') }}">
                <i class="fa-regular fa-circle-user"></i>
                <span class="ml-2 menu-title">个人资料</span>
            </a>
        </li>


        <li class="nav-item {{ Request::routeIs('admin.orders') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.orders') }}">
                <i class="fa-solid fa-users-gear"></i>
                <span class="ml-2 menu-title">所有订阅</span>
            </a>
        </li>

        <li class="nav-item {{ Request::routeIs('admin.redeemRequests') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.redeemRequests') }}">
                <i class="fa-solid fa-gift"></i>
                <span class="ml-2 menu-title">口令红包审核</span>
            </a>
        </li>

        <li class="nav-item {{ Request::routeIs('settings') && !Request::routeIs('settings.general') && !Request::routeIs('settings.popup') && !Request::routeIs('settings.contact') && !Request::routeIs('settings.app') && !Request::routeIs('settings.ads') ? 'tactive' : '' }}">
    <a class="nav-link d-flex justify-content-between align-items-center" data-toggle="collapse" href="#settingsMenu">
        <div>
            <i class="fa-solid fa-screwdriver-wrench"></i>
            <span class="ml-1 menu-title">设置</span>
        </div>
        <i class="fa-solid fa-chevron-down transition-arrow {{ Request::routeIs('settings*') ? 'rotated' : '' }}"></i>
    </a>

    <div class="collapse {{ Request::routeIs('settings*') ? 'show' : '' }}" id="settingsMenu">
        <ul class="nav flex-column sub-menu">
            <li class="nav-item {{ Request::routeIs('settings.general') ? 'tactive' : '' }}">
                <a class="nav-link" href="{{ route('settings.general') }}">常规设置</a>
            </li>
            <li class="nav-item {{ Request::routeIs('settings.popup') ? 'tactive' : '' }}">
                <a class="nav-link" href="{{ route('settings.popup') }}">应用更新弹窗</a>
            </li>
            <li class="nav-item {{ Request::routeIs('settings.contact') ? 'tactive' : '' }}">
                <a class="nav-link" href="{{ route('settings.contact') }}">联系方式</a>
            </li>
            <li class="nav-item {{ Request::routeIs('settings.app') ? 'tactive' : '' }}">
                <a class="nav-link" href="{{ route('settings.app') }}">应用设置</a>
            </li>
            <li class="nav-item {{ Request::routeIs('settings.ads') ? 'tactive' : '' }}">
                <a class="nav-link" href="{{ route('settings.ads') }}">AdMob 设置</a>
            </li>
            
        </ul>
    </div>
</li>
         <li class="nav-item {{ Request::routeIs('admin.helpcenter.list') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.helpcenter.list') }}">
                <i class="fa-solid fa-list-ol"></i>
                <span class="ml-2 menu-title">帮助中心</span>
            </a>
        </li>
        <li class="nav-item {{ Request::routeIs('admin.chat') ? 'tactive' : '' }}">
            <a class="nav-link" href="{{ route('admin.chat') }}">
                <i class="fa-solid fa-comment-dots"></i>
                <span class="ml-2 menu-title">聊天</span>
            </a>
        </li>
    </ul>
</nav>

<style>
/* Dark Sidebar */
.sidebar {
    background-color: #eee;
    min-height: 100vh;
    border-right: 1px solid #f1f1f1;
    padding-top: 1rem;
}

/* Remove list markers */
.sidebar .nav,
.sidebar .nav ul,
.sidebar .nav li {
    list-style: none;
    margin: 0;
    padding: 0;
}

.sidebar .nav-link {
    color: #111 !important;
    padding: 10px 15px;
    margin: 5px 10px;
    display: flex;
    align-items: center;
    border-radius: 8px;
    transition: all 0.2s ease-in-out;
}

.sidebar .nav-link i {
    font-size: 16px;
}

.sidebar .menu-title {
    font-weight: 500;
    font-size: 14px;
}

/* Hover / Focus */
.sidebar .nav-link:hover,
.sidebar .nav-link:focus {
    background-color: #57b65726 !important;
    color: #111 !important;
}

/* Active state - only for clicked/active item */
.sidebar .nav-item.tactive > .nav-link {
   color: #111 !important;
    border-left: 3px solid #0df40d;
    font-weight: 600;
}

/* Spacing between items */
.sidebar .nav-item + .nav-item {
    margin-top: 5px;
}

/* Sub-menu styling - modern and clean */
.sub-menu {
    padding-left: 0;
    margin-top: 5px;
    list-style: none !important;
}

.sub-menu li {
    list-style: none !important;
}

.sub-menu .nav-link {
    padding: 8px 15px 8px 30px !important;
    font-size: 13px;
    color: #111 !important;
    margin: 2px 10px;
    border-radius: 6px;
    position: relative;
    transition: all 0.2s ease;
}

.sub-menu .nav-link:hover {
    color: #111 !important;
    padding-left: 35px !important;
}

/* Active sub-menu item - modern indicator */
.sub-menu .nav-item.tactive > .nav-link {
    color: #111 !important;
    border-left: 3px solid #0df40d;
    font-weight: 600;
    padding-left: 30px !important;
}

.sub-menu .nav-item.tactive > .nav-link::before {
    content: '';
    position: absolute;
    left: 10px;
    top: 50%;
    transform: translateY(-50%);
    width: 6px;
    height: 6px;
    background-color: #0df40d;
    border-radius: 50%;
}

/* Smooth transition */
#settingsMenu {
    transition: all 0.3s ease-in-out;
}

/* Arrow rotate */
.transition-arrow {
    transition: transform 0.3s ease;
    font-size: 12px;
}

.transition-arrow.rotated {
    transform: rotate(180deg);
}
</style>
<script>
document.addEventListener("DOMContentLoaded", function () {
    const settingsToggle = document.querySelector('[href="#settingsMenu"]');
    const settingsMenu = document.getElementById('settingsMenu');
    
    if (settingsToggle && settingsMenu) {
        // Update arrow rotation based on collapse state
        settingsMenu.addEventListener('show.bs.collapse', function () {
            const icon = settingsToggle.querySelector(".transition-arrow");
            if (icon) icon.classList.add("rotated");
        });
        
        settingsMenu.addEventListener('hide.bs.collapse', function () {
            const icon = settingsToggle.querySelector(".transition-arrow");
            if (icon) icon.classList.remove("rotated");
        });
    }
});
</script>
