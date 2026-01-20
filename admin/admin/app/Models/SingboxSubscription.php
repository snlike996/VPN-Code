<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SingboxSubscription extends Model
{
    protected $table = 'singbox_subscriptions';

    protected $fillable = [
        'name',
        'platform',
        'content_type',
        'config_content',
        'subscription_url',
        'enabled',
        'priority',
    ];
}
