@extends('layouts.app')
@section('title', '应用设置')

@section('content')
<div class="container-fluid p-0 bg-light min-vh-100">
    <div class="card shadow-none text-light" style="background-color:#eee; border-radius:12px;">
        <div class="p-4">
           
            <h3 class="mb-4 text-dark">应用设置</h3>

            {{-- Flash Messages --}}
            @if(session('success'))
                <div class="alert alert-success">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="alert alert-danger">{{ session('error') }}</div>
            @endif

            {{-- Privacy Policy --}}
            <div class="setting-section mb-4">
                <form action="{{ route('settings.app.update') }}" method="POST">
                    @csrf
                    <input type="hidden" name="field" value="privacy_policy">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <label class="form-label mb-0"><i class="fas fa-shield-alt text-info"></i> 隐私政策</label>
                        <button type="submit" class="btn btn-sm btn-primary btn-hover">
                            <i class="fa fa-save"></i> 更新
                        </button>
                    </div>
                    <textarea name="value" id="privacy_policy" class="form-control input-dark rich-editor" rows="6">{{ $settings['privacy_policy'] ?? '' }}</textarea>
                </form>
            </div>

            <hr class="border-secondary">

            {{-- Terms & Conditions --}}
            <div class="setting-section mb-4">
                <form action="{{ route('settings.app.update') }}" method="POST">
                    @csrf
                    <input type="hidden" name="field" value="terms_conditions">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <label class="form-label mb-0"><i class="fas fa-file-contract text-warning"></i> 服务条款</label>
                        <button type="submit" class="btn btn-sm btn-primary btn-hover">
                            <i class="fa fa-save"></i> 更新
                        </button>
                    </div>
                    <textarea name="value" id="terms_conditions" class="form-control input-dark rich-editor" rows="6">{{ $settings['terms_conditions'] ?? '' }}</textarea>
                </form>
            </div>

            <hr class="border-secondary">

            {{-- About Us --}}
            <div class="setting-section mb-4">
                <form action="{{ route('settings.app.update') }}" method="POST">
                    @csrf
                    <input type="hidden" name="field" value="about_us">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <label class="form-label mb-0"><i class="fas fa-info-circle text-success"></i> 关于我们</label>
                        <button type="submit" class="btn btn-sm btn-primary btn-hover">
                            <i class="fa fa-save"></i> 更新
                        </button>
                    </div>
                    <textarea name="value" id="about_us" class="form-control input-dark rich-editor" rows="6">{{ $settings['about_us'] ?? '' }}</textarea>
                </form>
            </div>

            <hr class="border-secondary">

            {{-- App URLs Section --}}
            <h5 class="mb-3 text-dark"><i class="fas fa-link"></i> 应用链接</h5>
            
            <div class="row g-3">
                {{-- More Apps URL --}}
                <div class="col-md-4">
                    <form action="{{ route('settings.app.update') }}" method="POST">
                        @csrf
                        <input type="hidden" name="field" value="more_app_url">
                        <label class="form-label">更多应用链接</label>
                        <div class="input-group">
                            <input type="url" name="value" class="form-control input-dark" 
                                   value="{{ $settings['more_app_url'] ?? '' }}" placeholder="https://...">
                            <button type="submit" class="btn btn-primary btn-hover">
                                <i class="fa fa-save"></i>
                            </button>
                        </div>
                    </form>
                </div>

                {{-- Share App URL --}}
                <div class="col-md-4">
                    <form action="{{ route('settings.app.update') }}" method="POST">
                        @csrf
                        <input type="hidden" name="field" value="share_app_url">
                        <label class="form-label">分享应用链接</label>
                        <div class="input-group">
                            <input type="url" name="value" class="form-control input-dark" 
                                   value="{{ $settings['share_app_url'] ?? '' }}" placeholder="https://...">
                            <button type="submit" class="btn btn-primary btn-hover">
                                <i class="fa fa-save"></i>
                            </button>
                        </div>
                    </form>
                </div>

                {{-- Rate App URL --}}
                <div class="col-md-4">
                    <form action="{{ route('settings.app.update') }}" method="POST">
                        @csrf
                        <input type="hidden" name="field" value="rate_app_url">
                        <label class="form-label">评分应用链接</label>
                        <div class="input-group">
                            <input type="url" name="value" class="form-control input-dark" 
                                   value="{{ $settings['rate_app_url'] ?? '' }}" placeholder="https://...">
                            <button type="submit" class="btn btn-primary btn-hover">
                                <i class="fa fa-save"></i>
                            </button>
                        </div>
                    </form>
                </div>
            </div>

        </div>
    </div>
</div>
@endsection

@push('style')
<link href="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-lite.min.css" rel="stylesheet">
<style>
/* Inputs dark theme */
.input-dark {
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

/* Setting section */
.setting-section {
    background-color: #eee;
    padding: 20px;
    border-radius: 8px;
}

/* Summernote dark theme */
.note-editor.note-frame {
    background-color: #eee !important;
    border-color: #444 !important;
}
.note-editor .note-toolbar {
    background-color: #eee !important;
    border-color: #444 !important;
}
.note-editor .note-editing-area .note-editable {
    background-color: #eee !important;
    color: #111 !important;
}
.note-btn {
    background-color: #eee !important;
    border-color: #555 !important;
    color: #111 !important;
}
.note-btn:hover {
    background-color: #eee !important;
}
.note-dropdown-menu {
    background-color: #eee !important;
}
.note-dropdown-item {
    color: #111 !important;
}
.note-dropdown-item:hover {
    background-color: #eee !important;
}

/* Responsive spacing */
@media (max-width:767px){
    .card { padding: 20px 15px; }
}
</style>
@endpush

@push('script')
<script src="https://cdn.jsdelivr.net/npm/summernote@0.8.18/dist/summernote-lite.min.js"></script>
<script>
$(document).ready(function() {
    $('.rich-editor').summernote({
        height: 200,
        toolbar: [
            ['style', ['bold', 'italic', 'underline', 'clear']],
            ['font', ['strikethrough']],
            ['para', ['ul', 'ol', 'paragraph']],
            ['insert', ['link']],
            ['view', ['codeview']]
        ],
        callbacks: {
            onInit: function() {
                // Apply dark theme to editor
                $(this).next('.note-editor').find('.note-editing-area').css('background-color', '#1f1f2e');
            }
        }
    });
});
</script>
@endpush
