<?php

namespace App\Services\Epay;

use Illuminate\Support\Facades\Http;

class EpayService
{
    protected string $pid;
    protected string $key;
    protected string $apiUrl;
    protected string $submitUrl;

    public function __construct()
    {
        $this->pid       = config('epay.pid');
        $this->key       = config('epay.key');
        $this->apiUrl    = rtrim(config('epay.api_url'), '/') . '/mapi.php';
        $this->submitUrl = rtrim(config('epay.api_url'), '/') . '/submit.php';
    }

    /**
     * Build MD5 signature
     */
    protected function sign(array $params): string
    {
        ksort($params);
        $str = '';
        foreach ($params as $k => $v) {
            if ($k !== 'sign' && $k !== 'sign_type' && $v !== '') {
                $str .= "$k=$v&";
            }
        }
        $str = rtrim($str, '&') . $this->key;
        return md5($str);
    }

    /**
     * API Pay (JSON response)
     */
    public function apiPay(string $orderId, float $amount, string $name, string $type = 'alipay'): array
    {
        $params = [
            'pid'          => $this->pid,
            'type'         => $type,
            'notify_url'   => route('epay.notify'),
            'return_url'   => route('epay.return'),
            'out_trade_no' => $orderId,
            'name'         => $name,
            'money'        => $amount,
            'device'       => 'mobile',
            'clientip'     => request()->ip(),
        ];

        $params['sign']      = $this->sign($params);
        $params['sign_type'] = 'MD5';

        $response = Http::asForm()->post($this->apiUrl, $params);

        return $response->json();
    }

    /**
     * Page Pay (redirect URL)
     */
    public function pagePay(string $orderId, float $amount, string $name, string $type = 'alipay'): string
    {
        $params = [
            'pid'          => $this->pid,
            'type'         => $type,
            'notify_url'   => route('epay.notify'),
            'return_url'   => route('epay.return'),
            'out_trade_no' => $orderId,
            'name'         => $name,
            'money'        => $amount,
            'device'       => 'mobile',
            'clientip'     => request()->ip(),
        ];

        $params['sign']      = $this->sign($params);
        $params['sign_type'] = 'MD5';

        return $this->submitUrl . '?' . http_build_query($params);
    }

    /**
     * Verify server notify
     */
    public function verifyNotify(array $data): bool
    {
        $sign = $data['sign'] ?? '';
        unset($data['sign'], $data['sign_type']);

        return $sign === $this->sign($data);
    }

    /**
     * Verify return redirect
     */
    public function verifyReturn(array $data): bool
    {
        $sign = $data['sign'] ?? '';
        unset($data['sign'], $data['sign_type']);

        return $sign === $this->sign($data);
    }

    /**
 * Query order status from Epay API
 */
    public function queryOrder(string $orderId): array
    {
        $params = [
            'act' => 'order',
            'pid' => $this->pid,
            'key' => $this->key,
            'trade_no' => $orderId,
        ];

        $url = $this->apiUrl . 'api.php?' . http_build_query($params);

        $response = Http::timeout(60)->get($url);

        return $response->json() ?? [];
    }

}
