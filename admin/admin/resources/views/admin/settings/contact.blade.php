@extends('layouts.app')
@section('title', '联系方式设置')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; border-radius:12px;">
        <div class="p-4">
            
            <h3 class="mb-4 text-dark">联系方式设置</h3>

            {{-- Flash Messages --}}
            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            {{-- Settings Form --}}
            <form action="{{ route('settings.contact.update') }}" method="POST">
                @csrf
                <div class="row g-3">

                    {{-- Telegram Username --}}
                    <div class="col-md-6">
                        <label for="telegram_username" class="form-label">
                            <i class="fab fa-telegram text-info"></i> Telegram用户名
                        </label>
                        <div class="input-group">
                            <span class="input-group-text input-dark">@</span>
                            <input type="text" name="telegram_username" class="form-control input-dark" 
                                   value="{{ $settings['telegram_username'] ?? '' }}" placeholder="username">
                        </div>
                        <small class="text-muted">不带@符号</small>
                    </div>

                    {{-- Contact Email --}}
                    <div class="col-md-6">
                        <label for="contact_email" class="form-label">
                            <i class="fas fa-envelope text-warning"></i> 联系邮箱
                        </label>
                        <input type="email" name="contact_email" class="form-control input-dark" 
                               value="{{ $settings['contact_email'] ?? '' }}" placeholder="support@example.com">
                    </div>

                </div>

                <button type="submit" class="btn btn-primary btn-hover mt-4">
                    <i class="fa fa-save fa-lg"></i> 更新联系方式设置
                </button>
            </form>
        </div>
    </div>
</div>
@endsection

@push('style')
<style>
/* Inputs dark theme */
.input-dark {
    background-color: #eee !important;
    border: 1px solid #444 !important;
    color: #111 !important;
}
.input-dark:focus {
    background-color: #eee !important;
    border-color: #444 !important; 
    color: #111 !important;
}

/* Input group */
.input-group-text.input-dark {
    background-color: #eee !important;
    border: 1px solid #444 !important;
    color: #111 !important;
}

/* Buttons */
.btn-primary {
    background-color: #0df40d !important;
    border-color: #0df40d !important;
    color: #111 !important;
}


/* Card & container */
.card {
    border-radius: 12px;
}

/* Breadcrumb */
.breadcrumb-item + .breadcrumb-item::before {
    color: #888;
}
.form-label {
    color: #111 !important;
}

/* Responsive spacing */
@media (max-width:767px){
    .card { padding: 20px 15px; }
}
</style>
@endpush
