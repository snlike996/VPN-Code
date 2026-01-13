<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

/**
 * App\Models\AppSetting
 *
 * @property int $id
 * @property string $key
 * @property string $value
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 *
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting query()
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting whereKey($value)
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|AppSetting whereValue($value)
 *
 * @mixin \Eloquent
 */
class AppSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'key',
        'value',
    ];

    /**
     * Get a setting value by key.
     *
     * @param string $key
     * @param mixed $default
     * @return mixed
     */
    public static function getValue(string $key, $default = null)
    {
        $setting = self::where('key', $key)->first();
        return $setting ? $setting->value : $default;
    }

    /**
     * Get multiple settings by keys.
     *
     * @param array $keys
     * @return array
     */
    public static function getValues(array $keys): array
    {
        return self::whereIn('key', $keys)
            ->pluck('value', 'key')
            ->toArray();
    }

    /**
     * Set a setting value.
     *
     * @param string $key
     * @param mixed $value
     * @return void
     */
    public static function setValue(string $key, $value): void
    {
        self::updateOrCreate(['key' => $key], ['value' => $value]);
    }

    /**
     * Set multiple settings at once.
     *
     * @param array $settings
     * @return void
     */
    public static function setValues(array $settings): void
    {
        foreach ($settings as $key => $value) {
            if ($value !== null) {
                self::setValue($key, $value);
            }
        }
    }
}
