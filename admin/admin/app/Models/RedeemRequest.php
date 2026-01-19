<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RedeemRequest extends Model
{
    protected $fillable = [
        'user_id',
        'code',
        'status',
        'approved_by',
        'approved_at',
        'rejected_by',
        'rejected_at',
        'note',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
