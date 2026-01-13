<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;

use App\Notifications\CustomResetPasswordNotification;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * App\Models\User
 *
 * @property int $id
 * @property string $name
 * @property string $email
 * @property \Illuminate\Support\Carbon|null $email_verified_at
 * @property string $password
 * @property int|null $subscription_id
 * @property int $isPremium
 * @property int $isSuspended
 * @property string|null $last_seen
 * @property string|null $remember_token
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property-read \Illuminate\Notifications\DatabaseNotificationCollection<int, \Illuminate\Notifications\DatabaseNotification> $notifications
 * @property-read int|null $notifications_count
 * @property-read \Illuminate\Database\Eloquent\Collection<int, \Laravel\Sanctum\PersonalAccessToken> $tokens
 * @property-read int|null $tokens_count
 *
 * @method static \Illuminate\Database\Eloquent\Builder|User activeUsers()
 * @method static \Database\Factories\UserFactory factory($count = null, $state = [])
 * @method static \Illuminate\Database\Eloquent\Builder|User newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|User newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|User query()
 * @method static \Illuminate\Database\Eloquent\Builder|User whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereEmail($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereEmailVerifiedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereIsPremium($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereIsSuspended($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereLastSeen($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereName($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User wherePassword($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereRememberToken($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereSubscriptionId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|User whereUpdatedAt($value)
 *
 * @mixin \Eloquent
 */
class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $guarded = [];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'validity_created_at' => 'datetime',
        'validity_expiry_at' => 'datetime',
        'expired_date' => 'datetime',
        'start_date' =>'datetime'

    ];

    public static function scopeActiveUsers()
    {
        $currentTime = Carbon::now();
        $twoMinutesAgo = $currentTime->copy()->subMinutes(2);

        return self::whereBetween('last_seen', [$twoMinutesAgo, $currentTime]);
    }

    public static function registeredUsersCountLast30Days()
    {
        $thirtyDaysAgo = Carbon::now()->subDays(30);

        return self::where('created_at', '>=', $thirtyDaysAgo)->count();
    }

    public static function activeUsersCountLast1Hour()
    {
        $oneHourAgo = Carbon::now()->subHour();

        return self::where('last_seen', '>=', $oneHourAgo)->count();
    }

    public static function registeredUsersPercentageLast30Days()
    {
        $totalUsers = self::count();
        if ($totalUsers > 0) {
            $registeredUsersCount = self::registeredUsersCountLast30Days();

            return ($registeredUsersCount / $totalUsers) * 100;
        }

        return 0;
    }

    public static function activeUsersPercentageLast1Hour()
    {
        $totalUsers = self::count();
        if ($totalUsers > 0) {
            $activeUsersCount = self::activeUsersCountLast1Hour();

            return ($activeUsersCount / $totalUsers) * 100;
        }

        return 0;
    }

    public function sendPasswordResetNotification($token)
    {
        $this->notify(new CustomResetPasswordNotification($token));
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

   
}
