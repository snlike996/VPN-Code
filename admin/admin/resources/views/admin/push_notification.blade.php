@extends('layouts.app')
@section('title')
推送通知
@endsection
@section('content')
    <div class="col-lg-12 grid-margin stretch-card">
        <div class="card">
            @if (session('status'))
                <div class="alert alert-success">
                    {{ session('status') }}
                </div>
            @endif
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
            <form method="POST" action="{{ route('admin.send.notification') }}">
                @csrf
                <div class="form-group">
                    <label for="title">标题</label>
                    <input class="form-control" type="text" name="title" placeholder="标题" required>
                </div>
                <div class="form-group">
                    <label for="message">消息内容</label>
                    <textarea class="form-control" name="message" placeholder="消息内容" rows="4" required></textarea>
                </div>
                <button class="btn btn-primary" type="submit">发送</button>
            </form>
        </div>
    </div>

@endsection
@push('script')
<script>
    function openEditModal(id, country_code, name, link, isPremium) {
        $('#editModal').modal('show');
        $('#editForm').attr('action', '{{ route("admin.servers.update", ":id") }}'.replace(':id', id));
        $('#country_code').val(country_code);
        $('#name').val(name);
        $('#link').val(link);
        $('#isPremium').val(isPremium);

        if (country_code) {
            var baseUrl = '{{ url('/') }}'; // Get the base URL
            var imageUrl = baseUrl + '/images/countries' + country_code + '.png'; // Prepend the base URL to the image URL
            $('#imagePreview').attr('src', imageUrl).show(); // Show image preview
        } else {
            $('#imagePreview').attr('src', '').hide(); // Hide image preview if no image
        }
    }

    function previewImage(input) {
        var file = input.files[0];
        if (file) {
            var imageUrl = URL.createObjectURL(file);
            $('#imagePreview').attr('src', imageUrl).show();
        } else {
            $('#imagePreview').attr('src', '').hide();
        }
    }
</script>


    <script>
        function confirmDelete(userId) {
            var result = confirm("确定要删除此用户吗?");
            if (result) {
                window.location.href = "{{ route('admin.servers.delete', ['id' => ':userId']) }}".replace(':userId',
                    userId);
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
        .btn {

            border-radius: 25px;

        }

        .new {
            font-size: 12px;
        }

        .card {

            padding: 20px;
            border: none;


        }


        .active {

            background: #f6f7fb !important;
            border-color: #f6f7fb !important;
            color: #000 !important;
            font-size: 12px;

        }

        .inputs {

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


        .form-control:focus {
            color: blue;
        }

        .inputs i {

            position: absolute;
            top: 14px;
            left: 4px;
            color: #b8b9bc;
        }
    </style>
@endpush
