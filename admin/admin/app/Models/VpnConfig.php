<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * VPN Configuration model for storing generated WireGuard configs.
 *
 * @property int $id
 * @property int|null $user_id
 * @property string $client_name
 * @property string|null $client_ip
 * @property string $config_content
 * @property string $download_token
 * @property string $server_host
 * @property string|null $server_endpoint
 * @property string $status
 * @property \Carbon\Carbon|null $expires_at
 * @property int $download_count
 * @property \Carbon\Carbon $created_at
 * @property \Carbon\Carbon $updated_at
 */
class VpnConfig extends Model
{
    use HasFactory;

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'vpn_configs';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<string>
     */
    protected $fillable = [
        'user_id',
        'client_name',
        'client_ip',
        'config_content',
        'download_token',
        'server_host',
        'server_endpoint',
        'status',
        'expires_at',
        'download_count',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'expires_at' => 'datetime',
        'download_count' => 'integer',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<string>
     */
    protected $hidden = [
        'config_content',
    ];

    /**
     * Get the user that owns the VPN config.
     *
     * @return BelongsTo
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope for active configs only.
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeActive($query)
    {
        return $query->where('status', 'active')
                     ->where(function ($q) {
                         $q->whereNull('expires_at')
                           ->orWhere('expires_at', '>', now());
                     });
    }

    /**
     * Check if config is expired.
     *
     * @return bool
     */
    public function isExpired(): bool
    {
        if ($this->status !== 'active') {
            return true;
        }

        if ($this->expires_at && $this->expires_at->isPast()) {
            return true;
        }

        return false;
    }

    /**
     * Get decrypted config content.
     *
     * @return string
     */
    public function getDecryptedConfig(): string
    {
        try {
            return decrypt($this->config_content);
        } catch (\Exception $e) {
            return $this->config_content;
        }
    }
}
