@php
    use Illuminate\Support\Carbon;
@endphp

<footer class="footer bg-light border-top border-secondary py-3">
    <div class="d-sm-flex justify-content-center justify-content-sm-between">
        <span class="text-muted text-center text-sm-left d-block d-sm-inline-block" style="color: #111;">
            &copy; {{ Carbon::now()->year }} Vpn. 版权所有。
        </span>
    </div>
</footer>

@push('style')
<style>
.footer {
    background-color: #eee;
    color: #111;
    font-size: 14px;
}

.footer a {
    color: #111;
    text-decoration: none;
}

.footer a:hover {
    color: #111;
    text-decoration: underline;
}
</style>
@endpush
