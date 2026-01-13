import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../controller/subscription_controller.dart';
import '../profile/profile_screen.dart';

class InAppPurchaseScreen extends StatefulWidget {
  const InAppPurchaseScreen({super.key});

  @override
  State<InAppPurchaseScreen> createState() => _InAppPurchaseScreenState();
}

class _InAppPurchaseScreenState extends State<InAppPurchaseScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>>? _purchaseUpdateStream;

  List<ProductDetails> _products = [];
  final Set<String> _productIds = {
    'one_month',
    'three_month',
    'six_month',
  };


  @override
  void initState() {
    super.initState();
    // Listen for purchase updates
    _purchaseUpdateStream = _inAppPurchase.purchaseStream.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _purchaseUpdateStream!.cancel();
    }, onError: (Object error) {
      // handle error here.
    });

    // Fetch the products and ensure lifecycle integrity
    _getProducts();
  }

  @override
  void dispose() {
    // Cancel the purchase update stream subscription on dispose
    _purchaseUpdateStream?.cancel();
    super.dispose();
  }


  void _listenToPurchaseUpdated(List<PurchaseDetails> purchases) {
    for (PurchaseDetails purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _handleSubscription(purchase);
        log("Purchase is done");
      } else if (purchase.status == PurchaseStatus.error) {
        if (kDebugMode) {
          log("Purchase is error");
        }
      } else if (purchase.status == PurchaseStatus.pending) {
        if (kDebugMode) {
          print('Purchase is pending');
          log("Purchase is pending");
        }
      }
      else{
        log("Not Purchase");
      }
    }
  }

  Future<void> _getProducts() async {
    try {
      ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_productIds);
      log("Available Products: ${response.productDetails.length}");
      log("Not Found IDs: ${response.notFoundIDs}");

      if (response.notFoundIDs.isEmpty) {
        setState(() {
          _products = response.productDetails;
        });
      } else {
        if (kDebugMode) {
          print('Error fetching products: ${response.notFoundIDs}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception fetching products: $e');
      }
    }
  }

  Future<void> _buySubscription(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (kDebugMode) {
        print('Error buying subscription: $e');
      }
    }
  }

  void _handleSubscription(PurchaseDetails purchase) {
    if (purchase.productID == _products[2].title) {

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase).then((value){
          Get.find<SubscriptionController>().purchaseSubscription(
              packageName: _products[2].title,
              validity: 30,
              price: _products[2].price
          ).then((value){
            if(value==200) {
              Get.offAll(()=> ProfileScreen(),transition: Transition.fadeIn);
              Get.snackbar(
                '购买',
                "计划购买成功",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
            }
            else{
              Get.snackbar(
                '购买',
                "出了点问题！请重试",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.red,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
            }
          });
        });
      }

    }
    else if (purchase.productID == _products[1].title) {

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase).then((value){
          Get.find<SubscriptionController>().purchaseSubscription(
              packageName: _products[1].title,
              validity: 180,
              price: _products[1].price
          ).then((value){
            if(value==200) {
              Get.snackbar(
                '购买',
                "计划购买成功",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
              Get.offAll(()=> ProfileScreen(),transition: Transition.fadeIn);
            }
            else{
              Get.snackbar(
                '购买',
                "出了点问题！请重试",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.red,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
            }
          });
        });
      }

    }
    else if (purchase.productID == _products[3].title) {

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase).then((value){
          Get.find<SubscriptionController>().purchaseSubscription(
              packageName: _products[3].title,
              validity: 365,
              price: _products[3].price
          ).then((value){
            if(value==200) {
              Get.snackbar(
                '购买',
                "计划购买成功",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
              Get.offAll(()=> ProfileScreen(),transition: Transition.fadeIn);
            }
            else{
              Get.snackbar(
                '购买',
                "出了点问题！请重试",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.red,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
            }
          });
        });
      }

    }
    else if (purchase.productID == _products[0].id) {

      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase).then((value){
          Get.find<SubscriptionController>().purchaseSubscription(
              packageName: _products[0].title,
              validity: 90,
              price: _products[0].price
          ).then((value){
            if(value==200) {
              Get.snackbar(
                '购买',
                "计划购买成功",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
              Get.offAll(()=> ProfileScreen(),transition: Transition.fadeIn);
            }
            else{
              Get.snackbar(
                '购买',
                "出了点问题！请重试",
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 1),
                backgroundColor: Colors.red,
                colorText: Colors.white,
                isDismissible: true,
                snackStyle: SnackStyle.FLOATING,
              );
            }
          });
        });
      }

    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 10,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        title: Text(
          "订阅计划",
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 16,letterSpacing: 0,
              fontWeight: FontWeight.w500
          ),
        ),

      ),
      body: Center(
        child: _products.isEmpty
            ? const Center(
          child: SizedBox(
            height: 25,
            width: 25,
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            ProductDetails product = _products[index];

            // Determine badge
            String? badgeText;
            Color badgeColor = Colors.transparent;

            if (index == 1) {
              badgeText = "最受欢迎";
              badgeColor = Colors.orangeAccent;
            } else if (index == 2) {
              badgeText = "节省 50%";
              badgeColor = Colors.greenAccent.shade400;
            }

            return Stack(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  color: const Color(0xff6C00FF),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    title: Text(
                      product.title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    subtitle: const SizedBox(height: 4),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.price,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white54, size: 16),
                      ],
                    ),
                    onTap: () => _buySubscription(product),
                  ),
                ),

                // Badge on top right
                if (badgeText != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),

    );
  }
}
