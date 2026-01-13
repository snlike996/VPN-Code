<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NotificationSent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public string $title;
    public string $message;

    /**
     * Create a new event instance.
     */
    public function __construct(string $title, string $message)
    {
        $this->title = $title;
        $this->message = $message;
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): Channel
    {
        return new PrivateChannel('notifications');
    }

    /**
     * Optional: Custom event name.
     */
    public function broadcastWith(): array
    {
        return [
            'message' => $this->message,
            'title' => $this->title,
        ];
    }
}
