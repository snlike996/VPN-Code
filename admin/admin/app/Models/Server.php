<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * App\Models\Server
 *
 * @property int $id
 * @property string|null $country_code
 * @property string $name
 * @property string|null $address
 * @property int $connections
 * @property string|null $image
 * @property int $isPremium
 * @property string|null $link
 * @property string|null $remember_token
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read string $country_flag
 *
 * @method static \Illuminate\Database\Eloquent\Builder|Server newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Server newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|Server query()
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereAddress($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereConnections($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereCountryCode($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereImage($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereIsPremium($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereLink($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereRememberToken($value)
 * @method static \Illuminate\Database\Eloquent\Builder|Server whereUpdatedAt($value)
 *
 * @mixin \Eloquent
 */
class Server extends Model
{
    use HasFactory;

    protected $fillable = [
        'country_code',
        'address',
        'name',
        'image',
        'link',
        'connections',
        'isPremium',
    ];

    protected $appends = ['country_flag'];

    protected static function boot()
    {
        parent::boot();
        static::saving(function ($model) {
            if (\Str::startsWith($model->link, ['vmess', 'vless', 'trojan', 'ss', 'socks'])) {
                $config = json_decode(base64_decode(\Arr::last(explode('://', $model->link))), true);
                $model->address = $config['add'] ?? '';
            }
        });
    }

    public static function activeServersCountLast1Hour()
    {
        $oneHourAgo = Carbon::now()->subHour();

        return self::where('created_at', '>=', $oneHourAgo)->count();
    }

    public static function registeredServersPercentageLast1Hour()
    {
        $totalUsers = self::count();
        if ($totalUsers > 0) {
            $activeUsersCount = self::activeServersCountLast1Hour();

            return ($activeUsersCount / $totalUsers) * 100;
        }

        return 0;
    }

    public function getCountryFlagAttribute(): string
    {
        return $this->country_code ? asset('images/countries/'.$this->country_code.'.png') : '';
    }
}
