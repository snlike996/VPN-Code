<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class V2raySubscriptionConfig extends Model
{
    use HasFactory;

    protected $table = 'v2ray_subscription_configs';

    protected $fillable = [
        'country_code',
        'country_name',
        'subscription_url',
        'enabled',
        'sort_order',
        'remark',
    ];

    protected $casts = [
        'enabled' => 'boolean',
    ];
}
