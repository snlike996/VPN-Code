@extends('layouts.app')

@section('content')
<div class="container-fluid py-4 min-vh-100">
    <div class="row">
        <!-- Users list -->
        <div class="col-md-4">
            <h3>在线客服</h3>
            <input type="text" id="userSearch" class="form-control mb-3" placeholder="搜索用户...">

           <ul id="userList" class="list-group" style="max-height: calc(100vh - 120px); overflow-y: auto;">
    @forelse($users as $user)
        <li class="border list-group-item user-item"
            data-id="{{ $user['id'] }}"
            style="cursor:pointer;{{ $user['admin_read_view'] == 0 ? 'color: red;' : '' }}">
            <div class="d-flex justify-content-between">
                <div>
                    <h4>{{ $user['name'] }}</h4>
                    <h6>{{ $user['email'] }}</h6>
                </div>
                <p>{{ $user['last_message_at'] ? \Carbon\Carbon::parse($user['last_message_at'])->diffForHumans() : '无消息' }}</p>
            </div>
        </li>
    @empty
        <li class="list-group-item text-center text-muted">暂无聊天记录</li>
    @endforelse
</ul>

        </div>



        <!-- Chat box -->
        <div class="col-md-8">
            <h3 id="chatTitle">请选择用户</h3>
            <div id="chatBox" class="p-3 mb-3 border" style="height:400px; overflow-y:auto; background:#f9f9f9;"></div>

            <!-- Hidden form initially -->
            <form id="chatForm" style="display: none;">
                @csrf
                <input type="hidden" name="user_id" id="user_id">
                <div class="input-group">
                    <input type="text" name="message" id="message" class="form-control" placeholder="输入消息..." autocomplete="off">
                    <button class="btn btn-primary" type="submit">发送</button>
                </div>
            </form>
        </div>
    </div>
</div>
@endsection

@push('scripts')
<script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>
<script>
    $(document).ready(function() {
        var selectedUser = null;
        var refreshInterval = null;

        // 🔹 Click on user to open chat
        $(document).on('click', '.user-item', function() {
          
            selectedUser = { 
                id: $(this).data('id'), 
                name: $(this).find('h4').text() 
            };

            // Remove highlight from all users first
            $('.user-item').removeClass('bg-primary text-white');

            // Highlight only the clicked user
            $(this).addClass('bg-primary text-white');

            // Remove unread highlight
            $(this).removeClass('bg-warning-subtle');

            // Update chat title and form
            $('#user_id').val(selectedUser.id);
            $('#chatTitle').text('与 ' + selectedUser.name + ' 的对话');
            $('#chatForm').show();

            // 🔹 Mark messages as read (AJAX)
            $.ajax({
                url: '/admin/chat/read-view/' + selectedUser.id,
                type: 'POST',
                data: { _token: '{{ csrf_token() }}' },
                success: function(res) {
                    console.log('Messages marked as read');
                },
                error: function(err) {
                    console.error('Failed to mark as read', err);
                }
            });

            // Load messages immediately
            loadMessages();

            // Clear previous interval if exists
            if (refreshInterval) clearInterval(refreshInterval);

            // Auto-refresh every 5 seconds
            refreshInterval = setInterval(loadMessages, 5000);
        });

        // 🔹 Load messages
        function loadMessages() {
            if(!selectedUser) return;

            $.ajax({
                url: "{{ route('admin.chat.messages') }}",
                method: 'POST',
                data: {
                    user_id: selectedUser.id,
                    _token: "{{ csrf_token() }}"
                },
                success: function(messages) {
                    $('#chatBox').empty();

                    messages.forEach(function(msg) {
                        // Format message date/time
                        var msgDate = new Date(msg.created_at);
                        var today = new Date();
                        var dateText = msgDate.toDateString() === today.toDateString()
                            ? '今天 ' + msgDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                            : msgDate.toLocaleDateString() + ' ' + msgDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

                        // Message alignment & style
                        var align = msg.sender_type === 'admin' ? 'd-flex justify-content-end' : 'd-flex justify-content-start';
                        var bg = msg.sender_type === 'admin' ? 'bg-primary text-white' : 'bg-secondary text-dark';

                        $('#chatBox').append(`
                            <div class="${align} mb-2">
                                <div class="p-2 rounded ${bg}" style="max-width:70%;">
                                    ${msg.message}
                                    <div class="small text-muted mt-1">${dateText}</div>
                                </div>
                            </div>
                        `);
                    });

                    // Auto scroll to bottom
                    $('#chatBox').scrollTop($('#chatBox')[0].scrollHeight);
                },
                error: function(err) {
                    console.error('Failed to load messages', err);
                }
            });
        }

        // 🔹 Send message
        $('#chatForm').submit(function(e) {
            e.preventDefault();
            if(!selectedUser) return;

            var message = $('#message').val().trim();
            if(!message) return;

            $.ajax({
                url: "{{ route('admin.chat.send') }}",
                method: 'POST',
                data: {
                    user_id: selectedUser.id,
                    message: message,
                    _token: "{{ csrf_token() }}"
                },
                success: function() {
                    $('#message').val('');
                    loadMessages();
                },
                error: function(err) {
                    console.error('Failed to send message', err);
                }
            });
        });
    });
</script>
<script>
    function timeAgo(dateString) {
    const date = new Date(dateString);
    const now = new Date();
    const seconds = Math.floor((now - date) / 1000);

    const intervals = [
        { label: "年", seconds: 31536000 },
        { label: "个月", seconds: 2592000 },
        { label: "天", seconds: 86400 },
        { label: "小时", seconds: 3600 },
        { label: "分钟", seconds: 60 },
        { label: "秒", seconds: 1 }
    ];

    for (const interval of intervals) {
        const count = Math.floor(seconds / interval.seconds);
        if (count > 0) {
            return count + " " + interval.label + "前";
        }
    }
    return "刚刚";
}



$(document).ready(function() {
    $('#userSearch').on('keyup', function() {
        let q = $(this).val().trim();

        // 🔹 If input is empty, reload the whole page
        if (q === '') {
            location.reload();
            return;
        }

        $.ajax({
            url: "{{ route('admin.chat.search') }}",
            method: 'POST',
            data: {
                q: q,
                _token: "{{ csrf_token() }}"
            },
            success: function(users) {
                $('#userList').empty();

                if (users.length === 0) {
                    $('#userList').append('<li class="list-group-item text-center text-muted">未找到用户</li>');
                    return;
                }

                users.forEach(function(user) {
                    let highlight = (user.admin_read_view == 0 && user.last_message_at) ? 'bg-warning-subtle' : '';
                    // Usage in your code:
                    let last = user.last_message_at 
                        ? timeAgo(user.last_message_at) 
                        : '无消息';

                    $('#userList').append(`
                        <li class="border list-group-item user-item ${highlight}" data-id="${user.id}">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h4>${user.name}</h4>
                                    <h6>${user.email}</h6>
                                </div>
                                <p>${last}</p>
                            </div>
                        </li>
                    `);
                });
            },
            error: function() {
                $('#userList').html('<li class="list-group-item text-center text-danger">加载用户失败</li>');
            }
        });
    });
});
</script>


@endpush
