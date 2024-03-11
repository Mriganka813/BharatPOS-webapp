import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:provider/provider.dart';
import 'package:shopos/src/models/KotModel.dart';
import 'package:shopos/src/models/input/order.dart';

import 'package:shopos/src/models/product.dart';
import 'package:shopos/src/pages/billing_list.dart';
import 'package:shopos/src/pages/checkout.dart';
// import 'package:shopos/src/pages/products_list.dart';
import 'package:shopos/src/pages/search_result.dart';
import 'package:shopos/src/provider/billing_order.dart';
import 'package:shopos/src/services/LocalDatabase.dart';
import 'package:shopos/src/services/global.dart';
import 'package:shopos/src/services/locator.dart';
import 'package:shopos/src/widgets/custom_button.dart';
import 'package:shopos/src/widgets/custom_text_field.dart';
import 'package:shopos/src/widgets/product_card_horizontal.dart';
import 'package:slidable_button/slidable_button.dart';

import '../services/product.dart';

/*class BillingPageArgs {
  final String? orderId;
  final List<OrderItemInput>? editOrders;
  final id;

  BillingPageArgs({this.orderId, this.editOrders, this.id});
}*/

class CreateSaleReturn extends StatefulWidget {
  static const routeName = '/create_sale_return';
  CreateSaleReturn({Key? key}) : super(key: key);

  //BillingPageArgs? args;

  @override
  State<CreateSaleReturn> createState() => _CreateSaleReturnState();
}

class _CreateSaleReturnState extends State<CreateSaleReturn> {
  late Order _Order;
  late final AudioCache _audioCache;
  List<OrderItemInput>? newAddedItems = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // _audioCache = AudioCache(
    //   fixedPlayer: AudioPlayer()..setReleaseMode(ReleaseMode.STOP),
    // );

    _Order = Order(
      id:0,
      orderItems: [],
    );
  }


  void _onAdd(OrderItemInput orderItem) {
    final qty = orderItem.quantity + 1;
    double discountForOneItem = double.parse(orderItem.discountAmt) / orderItem.quantity;
    orderItem.discountAmt = (double.parse(orderItem.discountAmt) + discountForOneItem).toStringAsFixed(2);
    final availableQty = orderItem.product?.quantity ?? 0;
    if (qty > availableQty) {
      locator<GlobalServices>().infoSnackBar("Quantity not available");
      return;
    }
    setState(() {
      orderItem.quantity = orderItem.quantity + 1;
      orderItem.quantity = roundToDecimalPlaces(orderItem.quantity, 4);
      orderItem.product?.quantityToBeSold = orderItem.quantity;
    });
  }
  void setQuantityToBeSold(OrderItemInput orderItem, double value,int index){
    final availableQty = orderItem.product?.quantity ?? 0;
    print("setting quantity to be sold: value is $value and available is $availableQty");
    if (value > availableQty) {
      locator<GlobalServices>().infoSnackBar("Quantity not available");
      return;
    }

    setState(() {
      if(value <=0 ){
        orderItem.quantity = 0;
        _Order.orderItems?[index].product?.quantityToBeSold = 0;
        _Order.orderItems?.removeAt(index);
      }else{
        orderItem.quantity = value;
        orderItem.product?.quantityToBeSold = value;
      }
    });
  }
  _onSubtotalChange(Product product, String? localSellingPrice) async {
    product.baseSellingPriceGst = localSellingPrice;
    double newGStRate = (double.parse(product.baseSellingPriceGst!) * double.parse(product.gstRate == 'null' ? '0' : product.gstRate!) / 100);
    product.saleigst = newGStRate.toStringAsFixed(2);

    product.salecgst = (newGStRate / 2).toStringAsFixed(2);
    print(product.salecgst);

    product.salesgst = (newGStRate / 2).toStringAsFixed(2);
    print(product.salesgst);

    product.sellingPrice = double.parse(product.baseSellingPriceGst!.toString()) + newGStRate;
    print(product.sellingPrice);
  }

  _onTotalChange(Product product, String? discountedPrice) {
    product.sellingPrice = double.parse(discountedPrice!);
    print(product.gstRate);

    double newBasePrice = (product.sellingPrice! * 100.0) / (100.0 + double.parse(product.gstRate == 'null' ? '0.0' : product.gstRate!));

    print(newBasePrice);

    product.baseSellingPriceGst = newBasePrice.toString();

    double newGst = product.sellingPrice! - newBasePrice;

    print(newGst);

    product.saleigst = newGst.toStringAsFixed(2);

    product.salecgst = (newGst / 2).toStringAsFixed(2);
    print(product.salecgst);

    product.salesgst = (newGst / 2).toStringAsFixed(2);
    print(product.salesgst);
  }

  @override
  Widget build(BuildContext context) {
    final _orderItems = _Order.orderItems ?? [];
    final provider = Provider.of<Billing>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Return'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: _orderItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No products added yet',
                            ),
                          )
                        : ListView.separated(
                            physics: const ClampingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _orderItems.length,
                            itemBuilder: (context, index) {
                              var basesellingprice = 0.0;
                              if (_orderItems[index].product!.baseSellingPriceGst != null && _orderItems[index].product!.baseSellingPriceGst != "null")
                                basesellingprice = double.parse(_orderItems[index].product!.baseSellingPriceGst!);

                              return GestureDetector(
                                onLongPress: () {
                                  showaddDiscountDialouge(basesellingprice, _orderItems, index);
                                },
                                child: ProductCardPurchase(
                                  type: "sale",
                                  product: _orderItems[index].product!,
                                  discount: _orderItems[index].discountAmt,
                                  onQuantityFieldChange: (double value){
                                    setQuantityToBeSold(_orderItems[index], value, index);
                                  },
                                  onAdd: () {
                                    _onAdd(_orderItems[index]);
                                  },
                                  onDelete: () {
                                    OnDelete(_orderItems[index], index);
                                  },
                                  productQuantity: _orderItems[index].quantity,
                                ),
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const Divider(color: Colors.transparent);
                            },
                          ),
                  ),
                  const Divider(color: Colors.transparent),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomButton(
                        title: "Add manually",
                        onTap: () async {
                          _onAddManually(context);
                        },
                      ),
                      CustomButton(
                        title: "Scan barcode",
                        onTap: () async {
                          _searchProductByBarcode();
                        },
                        type: ButtonType.outlined,
                      ),
                    ],
                  ),
                  const Divider(color: Color.fromRGBO(0, 0, 0, 0)),
                  HorizontalSlidableButton(
                    width: double.maxFinite,
                    buttonWidth: 50,
                    color: Colors.green,
                    isRestart: true,
                    buttonColor: Colors.green,
                    dismissible: false,
                    label: const Center(
                        child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.black,
                      ),
                    )),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Swipe to Return",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    height: 50,
                    onChanged: (position) {
                      if (position == SlidableButtonPosition.end) {
                        if (_orderItems.isNotEmpty) {
                          // insertToDatabase(provider);
                          // provider.addSalesReturnBill(
                          //   _Order,
                          //   _Order.id.toString(),
                          // );
                          Navigator.pushNamed(
                            context,
                            CheckoutPage.routeName,
                            arguments: CheckoutPageArgs(invoiceType: OrderType.saleReturn, order: _Order),
                          );
                        }else{
                          locator<GlobalServices>().errorSnackBar("No Products added");
                        }


                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }

  ///
  Future<void> _searchProductByBarcode() async {
    locator<GlobalServices>().showBottomSheetLoader();
    final barcode = await FlutterBarcodeScanner.scanBarcode(
      "#000000",
      "Cancel",
      false,
      ScanMode.BARCODE,
    );
    const _type = FeedbackType.success;
    Vibrate.feedback(_type);
    //await _audioCache.play('audio/beep.mp3');
    try {
      /// Fetch product by barcode
      final res = await const ProductService().getProductByBarcode(barcode);
      final product = Product.fromMap(res.data['inventory']);
      final order = OrderItemInput(product: product, quantity: 1, price: 0);
      final hasProduct = _Order.orderItems?.any((e) => e.product?.id == product.id);

      /// Check if product already exists
      if (hasProduct ?? false) {
        final i = _Order.orderItems?.indexWhere((e) => e.product?.id == product.id);

        /// Increase quantity if product already exists
        setState(() {
          _Order.orderItems![i!].quantity += 1;
        });
      } else {
        setState(() {
          _Order.orderItems?.add(order);
        });
      }
    } catch (_) {}
    Navigator.pop(context);
  }

  Map CountNoOfitemIsList(List<Product> temp) {
    var tempMap = {};

    for (int i = 0; i < temp.length; i++) {
      if (!tempMap.containsKey("${temp[i].id}")) {
        temp[i].quantityToBeSold = roundToDecimalPlaces(temp[i].quantityToBeSold!, 4);
        tempMap["${temp[i].id}"] = temp[i].quantityToBeSold;
      }
    }

    for (int i = 0; i < temp.length; i++) {
      for (int j = i + 1; j < temp.length; j++) {
        if (temp[i].id == temp[j].id) {
          temp.removeAt(j);
          j--;
        }
      }
    }

    return tempMap;
  }

  void OnDelete(OrderItemInput _orderItem, index) {
    double discountForOneItem = double.parse(_orderItem.discountAmt) / _orderItem.quantity;
    _orderItem.discountAmt = (double.parse(_orderItem.discountAmt) - discountForOneItem).toStringAsFixed(2);
    setState(() {
      if(_orderItem.quantity <= 1){
        _orderItem.quantity = 0;
        _Order.orderItems?[index].product?.quantityToBeSold = 0;
        _Order.orderItems?.removeAt(index);
      }else{
        _orderItem.quantity = _orderItem.quantity - 1;
        _orderItem.quantity = roundToDecimalPlaces(_orderItem.quantity, 4);
        _orderItem.product?.quantityToBeSold = _orderItem.quantity;
      }
    },);
  }

  void _onAddManually(BuildContext context) async {
    final result = await Navigator.pushNamed(
      context,
      SearchProductListScreen.routeName,
      arguments: ProductListPageArgs(isSelecting: true, orderType: OrderType.saleReturn, productlist: _Order.orderItems!),
    );
    if (result == null && result is! List<Product>) {
      return;
    }

    var temp = result as List<Product>;

    var tempMap = CountNoOfitemIsList(temp);
    final orderItems = temp.map((e) => OrderItemInput(
              product: e,
              quantity: tempMap["${e.id}"].toDouble(),
              price: 0,
            ))
        .toList();


    var tempOrderItems = _Order.orderItems;

    for (int i = 0; i < tempOrderItems!.length; i++) {
      for (int j = 0; j < orderItems.length; j++) {
        if (tempOrderItems[i].product!.id == orderItems[j].product!.id) {
          // tempOrderItems[i].product!.quantity = tempOrderItems[i].product!.quantity! - orderItems[j].quantity;
          tempOrderItems[i].quantity = tempOrderItems[i].quantity + orderItems[j].quantity;
          tempOrderItems[i].quantity = roundToDecimalPlaces(tempOrderItems[i].quantity, 4);
          tempOrderItems[i].product?.quantityToBeSold = (tempOrderItems[i].product?.quantityToBeSold ?? 0) + (orderItems[j].product?.quantityToBeSold ?? 0);
          tempOrderItems[i].product?.quantityToBeSold = roundToDecimalPlaces(tempOrderItems[i].product!.quantityToBeSold!, 4);
          orderItems.removeAt(j);
        }
      }
    }

    _Order.orderItems = tempOrderItems;

    setState(() {
      _Order.orderItems?.addAll(orderItems);
      newAddedItems!.addAll(orderItems);
    });
  }
  double roundToDecimalPlaces(double value, int decimalPlaces) {
    final factor = pow(10, decimalPlaces).toDouble();
    return (value * factor).round() / factor;
  }
  void showaddDiscountDialouge(double basesellingprice, List<OrderItemInput> _orderItems, int index) async {
    final _orderItem = _orderItems[index];

    double discount = double.parse(_orderItem.discountAmt);
    final product = _orderItems[index].product!;
    final tappedProduct = await ProductService().getProduct(_orderItems[index].product!.id!);
    final productJson = Product.fromMap(tappedProduct.data['inventory']);

    final baseSellingPriceToShow = productJson.baseSellingPriceGst;
    final sellingPriceToShow = productJson.sellingPrice;
    showDialog(
        useSafeArea: true,
        useRootNavigator: true,
        context: context,
        builder: (ctx) {
          String? localSellingPrice;
          String? discountedPrice;

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AlertDialog(
                content: Column(
                  children: [
                    Text(
                      "Discount",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    CustomTextField(
                      inputType: TextInputType.number,
                      onChanged: (val) {
                        localSellingPrice = val;
                      },
                        hintText: 'Enter Taxable Value   (${_orderItem.product!.gstRate != "null"  && _orderItem.product!.gstRate!="" ?
                        baseSellingPriceToShow : sellingPriceToShow})'
                    ),
                    _orderItem.product!.gstRate != "null" && _orderItem.product!.gstRate!=""?
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('or'),
                    ) : SizedBox.shrink(),
                    _orderItem.product!.gstRate != "null"  && _orderItem.product!.gstRate!="" ?
                    CustomTextField(
                      inputType: TextInputType.number,
                      onChanged: (val) {
                        discountedPrice = val;
                      },
                      hintText: 'Enter total value   (${sellingPriceToShow})',
                      validator: (val) {
                        if (val!.isNotEmpty && localSellingPrice!.isNotEmpty) {
                          return 'Do not fill both fields';
                        }
                        return null;
                      },
                    ) : SizedBox.shrink(),
                  ],
                ),
                actions: [
                  Center(
                    child: CustomButton(
                        title: 'Submit',
                        onTap: () {
                          if (localSellingPrice != null) {
                            print(localSellingPrice);
                            print(discountedPrice);
                            if(_orderItem.product!.baseSellingPriceGst =="null"){
                              discount = (_orderItem.product!.sellingPrice!  + double.parse(_orderItem.discountAmt) - double.parse(localSellingPrice!).toDouble()) * _orderItem.quantity;
                            }else{
                              discount = (double.parse(_orderItem.product!.baseSellingPriceGst!) + double.parse(_orderItem.discountAmt) - double.parse(localSellingPrice!).toDouble()) * _orderItem.quantity;
                            }
                            _orderItems[index].discountAmt = discount.toStringAsFixed(2);
                            setState(() {});
                          }

                          if (localSellingPrice != null && localSellingPrice!.isNotEmpty) {
                            _onSubtotalChange(product, localSellingPrice);
                            setState(() {});
                          } else if (discountedPrice != null) {
                            print('s$discountedPrice');

                            double realBaseSellingPrice = double.parse(_orderItem.product!.baseSellingPriceGst!);

                            _onTotalChange(product, discountedPrice);
                            print("realbase selling price=${realBaseSellingPrice}");
                            print("discount=${discount}");
                            discount = (realBaseSellingPrice + discount - double.parse(_orderItem.product!.baseSellingPriceGst!)) * _orderItem.quantity;
                            _orderItems[index].discountAmt = discount.toStringAsFixed(2);

                            setState(() {});
                          }

                          Navigator.of(ctx).pop();
                        }),
                  )
                ],
              ),
            ],
          );
        });
  }
}
