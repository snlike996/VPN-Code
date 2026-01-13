<?php

namespace App\Http\Controllers;

use App\Models\Epay;
use Illuminate\Http\Request;
use App\Services\Epay\EpayService;

class EpayController extends Controller
{
    protected EpayService $epay;

    public function __construct(EpayService $epay)
    {
        $this->epay = $epay;
    }

    /**
     * API payment (Flutter or frontend API)
     */
    public function apiPay(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0.1',
            'name'   => 'required|string',
            'type'   => 'required|string',
        ]);

        $orderId = uniqid('ORD_');

        Epay::create([
            'order_no' => $orderId,
            'name'     => $request->name,
            'amount'   => $request->amount,
            'status'   => 'pending',
        ]);

        $result = $this->epay->apiPay($orderId, $request->amount, $request->name, $request->type);

        return response()->json([$result, 'orderId' => $orderId]);
    }

    /**
     * Page redirect payment
     */
    public function pagePay(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:0.1',
            'name'   => 'required|string',
            'type'   => 'required|string',
        ]);

        $orderId = uniqid('ORD_');

        Epay::create([
            'order_no' => $orderId,
            'name'     => $request->name,
            'amount'   => $request->amount,
            'status'   => 'pending',
        ]);

        $url = $this->epay->pagePay($orderId, $request->amount, $request->name, $request->type);

        return redirect()->away($url);
    }

    /**
     * Server notify (POST)
     */
    public function notify(Request $request)
    {
        $data = $request->all();

        if ($this->epay->verifyNotify($data) && ($data['trade_status'] ?? '') === 'TRADE_SUCCESS') {
            Epay::where('order_no', $data['out_trade_no'])
                ->update(['status' => 'paid']);
            return response('success');
        }

        return response('fail');
    }

    /**
     * Return redirect (GET)
     */
    public function return(Request $request)
    {
        $data = $request->all();

        if ($this->epay->verifyReturn($data)) {
            return response()->json([
                'message' => 'Payment successful',
                'order'   => $data,
            ]);
        }

        return response()->json([
            'message' => 'Payment verification failed',
        ], 400);
    }

    public function checkStatus($order_no)
    {
        $order = Epay::where('order_no', $order_no)->first();

        if (!$order) {
            return response()->json(['message' => 'Order not found'], 404);
        }

        // Query remote API
        $apiResult = $this->epay->queryOrder($order_no);

        // Optional: Update local status if API says it's paid
        if (($apiResult['status'] ?? 0) == 1) {
            $order->update(['status' => 'paid']);
        }

        return response()->json([
            'order_no' => $order->order_no,
            'local_status' => $order->status,
            'api_status' => $apiResult['status'] ?? 0,
            'api_data' => $apiResult,
        ]);
    }


}
