<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Validation Language Lines
    |--------------------------------------------------------------------------
    |
    | The following language lines contain the default error messages used by
    | the validator class. Some of these rules have multiple versions such
    | as the size rules. Feel free to tweak each of these messages here.
    |
    */

    'accepted' => '您必须接受 :attribute。',
    'accepted_if' => '当 :other 为 :value 时，必须接受 :attribute。',
    'active_url' => ':attribute 不是一个有效的网址。',
    'after' => ':attribute 必须是一个在 :date 之后的日期。',
    'after_or_equal' => ':attribute 必须是一个在 :date 之后或同日的日期。',
    'alpha' => ':attribute 只能包含字母。',
    'alpha_dash' => ':attribute 只能包含字母、数字、短辉和下划线。',
    'alpha_num' => ':attribute 只能包含字母和数字。',
    'array' => ':attribute 必须是一个数组。',
    'before' => ':attribute 必须是一个在 :date 之前的日期。',
    'before_or_equal' => ':attribute 必须是一个在 :date 之前或同日的日期。',
    'between' => [
        'numeric' => ':attribute 必须在 :min 到 :max 之间。',
        'file' => ':attribute 必须在 :min 到 :max KB 之间。',
        'string' => ':attribute 必须在 :min 到 :max 个字符之间。',
        'array' => ':attribute 必须在 :min 到 :max 项之间。',
    ],
    'boolean' => ':attribute 字段必须是 true 或 false。',
    'confirmed' => ':attribute 两次输入不一致。',
    'current_password' => '密码错误。',
    'date' => ':attribute 不是一个有效的日期。',
    'date_equals' => ':attribute 必须是一个与 :date 相等的日期。',
    'date_format' => ':attribute 的格式必须为 :format。',
    'declined' => '必须拒绝 :attribute。',
    'declined_if' => '当 :other 为 :value 时，必须拒绝 :attribute。',
    'different' => ':attribute 和 :other 必须不同。',
    'digits' => ':attribute 必须是 :digits 位数字。',
    'digits_between' => ':attribute 必须在 :min 到 :max 位数字之间。',
    'dimensions' => ':attribute 图片尺寸不正确。',
    'distinct' => ':attribute 字段具有重复值。',
    'email' => ':attribute 必须是有效的邮箱地址。',
    'ends_with' => ':attribute 必须以 :values 为结尾。',
    'enum' => '选定的 :attribute 是无效的。',
    'exists' => '选定的 :attribute 是无效的。',
    'file' => ':attribute 必须是一个文件。',
    'filled' => ':attribute 字段是必填的。',
    'gt' => [
        'numeric' => ':attribute 必须大于 :value。',
        'file' => ':attribute 必须大于 :value KB。',
        'string' => ':attribute 必须大于 :value 个字符。',
        'array' => ':attribute 必须多于 :value 项。',
    ],
    'gte' => [
        'numeric' => ':attribute 必须大于或等于 :value。',
        'file' => ':attribute 必须大于或等于 :value KB。',
        'string' => ':attribute 必须大于或等于 :value 个字符。',
        'array' => ':attribute 必须多于或等于 :value 项。',
    ],
    'image' => ':attribute 必须是图片。',
    'in' => '选定的 :attribute 是无效的。',
    'in_array' => ':attribute 字段不存在于 :other 中。',
    'integer' => ':attribute 必须是整数。',
    'ip' => ':attribute 必须是有效的 IP 地址。',
    'ipv4' => ':attribute 必须是有效的 IPv4 地址。',
    'ipv6' => ':attribute 必须是有效的 IPv6 地址。',
    'json' => ':attribute 必须是有效的 JSON 字符串。',
    'lt' => [
        'numeric' => ':attribute 必须小于 :value。',
        'file' => ':attribute 必须小于 :value KB。',
        'string' => ':attribute 必须小于 :value 个字符。',
        'array' => ':attribute 必须少于 :value 项。',
    ],
    'lte' => [
        'numeric' => ':attribute 必须小于或等于 :value。',
        'file' => ':attribute 必须小于或等于 :value KB。',
        'string' => ':attribute 必须小于或等于 :value 个字符。',
        'array' => ':attribute 必须少于或等于 :value 项。',
    ],
    'mac_address' => ':attribute 必须是有效的 MAC 地址。',
    'max' => [
        'numeric' => ':attribute 不能大于 :max。',
        'file' => ':attribute 不能大于 :max KB。',
        'string' => ':attribute 不能大于 :max 个字符。',
        'array' => ':attribute 不能多于 :max 项。',
    ],
    'mimes' => ':attribute 必须是 type: :values 的文件。',
    'mimetypes' => ':attribute 必须是 type: :values 的文件。',
    'min' => [
        'numeric' => ':attribute 必须至少为 :min。',
        'file' => ':attribute 必须至少为 :min KB。',
        'string' => ':attribute 必须至少为 :min 个字符。',
        'array' => ':attribute 必须至少有 :min 项。',
    ],
    'multiple_of' => ':attribute 必须是 :value 的倍数。',
    'not_in' => '选定的 :attribute 是无效的。',
    'not_regex' => ':attribute 格式无效。',
    'numeric' => ':attribute 必须是数字。',
    'password' => '密码错误。',
    'present' => ':attribute 字段必须存在。',
    'prohibited' => ':attribute 字段被禁止。',
    'prohibited_if' => '当 :other 为 :value 时，:attribute 字段被禁止。',
    'prohibited_unless' => '除非 :other 在 :values 中，否则 :attribute 字段被禁止。',
    'prohibits' => ':attribute 字段禁止 :other 出现。',
    'regex' => ':attribute 格式无效。',
    'required' => ':attribute 不能为空。',
    'required_array_keys' => ':attribute 字段必须包含：:values。',
    'required_if' => '当 :other 为 :value 时，:attribute 字段不能为空。',
    'required_unless' => '除非 :other 在 :values 中，否则 :attribute 字段不能为空。',
    'required_with' => '当 :values 存在时，:attribute 字段不能为空。',
    'required_with_all' => '当 :values 都存在时，:attribute 字段不能为空。',
    'required_without' => '当 :values 不存在时，:attribute 字段不能为空。',
    'required_without_all' => '当 :values 都不存在时，:attribute 字段不能为空。',
    'same' => ':attribute 和 :other 必须一致。',
    'size' => [
        'numeric' => ':attribute 必须是 :size。',
        'file' => ':attribute 必须是 :size KB。',
        'string' => ':attribute 必须是 :size 个字符。',
        'array' => ':attribute 必须包含 :size 项。',
    ],
    'starts_with' => ':attribute 必须以 :values 为开头。',
    'string' => ':attribute 必须是字符串。',
    'timezone' => ':attribute 必须是有效的时区。',
    'unique' => ':attribute 已经存在。',
    'uploaded' => ':attribute 上传失败。',
    'url' => ':attribute 格式无效。',
    'uuid' => ':attribute 必须是有效的 UUID。',

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Language Lines
    |--------------------------------------------------------------------------
    |
    | Here you may specify custom validation messages for attributes using the
    | convention "attribute.rule" to name the lines. This makes it quick to
    | specify a specific custom language line for a given attribute rule.
    |
    */

    'custom' => [
        'attribute-name' => [
            'rule-name' => 'custom-message',
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Custom Validation Attributes
    |--------------------------------------------------------------------------
    |
    | The following language lines are used to swap our attribute placeholder
    | with something more reader friendly such as "E-Mail Address" instead
    | of "email". This simply helps us make our message more expressive.
    |
    */

    'attributes' => [
        'email' => '邮箱',
        'password' => '密码',
        'name' => '名称',
        'username' => '用户名',
        'title' => '标题',
        'content' => '内容',
        'description' => '描述',
        'excerpt' => '摘要',
        'date' => '日期',
        'time' => '时间',
        'available' => '可用',
        'size' => '大小',
        'phone' => '电话',
        'mobile' => '手机',
    ],

];
