import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:imeasure/providers/loading_provider.dart';
import 'package:imeasure/providers/uploaded_image_provider.dart';
import 'package:imeasure/widgets/custom_miscellaneous_widgets.dart';
import 'package:imeasure/widgets/text_widgets.dart';
import 'package:imeasure/widgets/top_navigator_widget.dart';

import '../providers/cart_provider.dart';
import '../providers/user_data_provider.dart';
import '../utils/color_util.dart';
import '../utils/delete_entry_dialog_util.dart';
import '../utils/firebase_util.dart';
import '../utils/go_router_util.dart';
import '../utils/quotation_dialog_util.dart';
import '../utils/string_util.dart';
import '../widgets/custom_padding_widgets.dart';
import '../widgets/dropdown_widget.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with TickerProviderStateMixin {
  late TabController tabController;

  List<DocumentSnapshot> associatedItemDocs = [];
  num paidAmount = 0;
  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final goRouter = GoRouter.of(context);
      try {
        ref.read(loadingProvider).toggleLoading(true);
        if (!hasLoggedInUser()) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        final userDoc = await getCurrentUserDoc();
        final userData = userDoc.data() as Map<dynamic, dynamic>;
        String userType = userData[UserFields.userType];
        ref.read(userDataProvider).setUserType(userType);
        if (ref.read(userDataProvider).userType == UserTypes.admin) {
          ref.read(loadingProvider).toggleLoading(false);
          goRouter.goNamed(GoRoutes.home);
          return;
        }
        ref.read(cartProvider).setCartItems(await getCartEntries(context));
        associatedItemDocs = await getSelectedItemDocs(
            ref.read(cartProvider).cartItems.map((cartDoc) {
          final cartData = cartDoc.data() as Map<dynamic, dynamic>;
          return cartData[CartFields.itemID].toString();
        }).toList());
        setState(() {});
        ref.read(loadingProvider).toggleLoading(false);
      } catch (error) {
        ref.read(loadingProvider).toggleLoading(false);
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error getting your cart: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(loadingProvider);
    ref.watch(userDataProvider);
    ref.watch(cartProvider);
    ref.watch(uploadedImageProvider);
    return DefaultTabController(
      initialIndex: 2,
      length: 3,
      child: Scaffold(
        appBar: topUserNavigator(context, path: GoRoutes.cart),
        body: stackedLoadingContainer(
            context,
            ref.read(loadingProvider).isLoading,
            Column(children: [
              TabBar(tabs: [
                Tab(
                    child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    quicksandWhiteBold('NO ADDITIONAL COST REQUESTED: '),
                    quicksandCoralRedBold(ref
                        .read(cartProvider)
                        .noAdditionalCostRequestedCartItems
                        .length
                        .toString())
                  ],
                )),
                Tab(
                    child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    quicksandWhiteBold('PENDING ADDITIONAL COST: '),
                    quicksandCoralRedBold(ref
                        .read(cartProvider)
                        .pendingAdditionalCostCartItems
                        .length
                        .toString())
                  ],
                )),
                Tab(
                    child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    quicksandWhiteBold('FOR CHECKOUT: '),
                    quicksandCoralRedBold(ref
                        .read(cartProvider)
                        .forCheckoutCartItems
                        .length
                        .toString())
                  ],
                ))
              ]),
              SizedBox(
                height: MediaQuery.of(context).size.height - 150,
                child: TabBarView(children: [
                  _noAdditionalCostRequested(),
                  _pendingAdditionalCostRequested(),
                  _forCheckout()
                ]),
              )
            ])),
      ),
    );
  }

  Widget _noAdditionalCostRequested() {
    return ref.read(cartProvider).noAdditionalCostRequestedCartItems.isNotEmpty
        ? SingleChildScrollView(
            child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemCount: ref
                    .read(cartProvider)
                    .noAdditionalCostRequestedCartItems
                    .length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return _cartEntry(ref
                      .read(cartProvider)
                      .noAdditionalCostRequestedCartItems[index]);
                }))
        : Center(
            child: quicksandWhiteBold(
                'YOU HAVE NO CART ITEMS WHICH NEED TO HAVE ADDITIONAL COSTS REQUESTED'));
  }

  Widget _pendingAdditionalCostRequested() {
    return ref.read(cartProvider).pendingAdditionalCostCartItems.isNotEmpty
        ? SingleChildScrollView(
            child: ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemCount: ref
                    .read(cartProvider)
                    .pendingAdditionalCostCartItems
                    .length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return _cartEntry(ref
                      .read(cartProvider)
                      .pendingAdditionalCostCartItems[index]);
                }))
        : Center(
            child: quicksandWhiteBold(
                'YOU HAVE NO CART ITEMS PENDING ADDITIONAL COSTS'));
  }

  Widget _forCheckout() {
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_forCheckoutCartEntries(), _checkoutContainer()]);
  }

  Widget _forCheckoutCartEntries() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.height - 160,
      child: all10Pix(
        child: ref.read(cartProvider).forCheckoutCartItems.isNotEmpty
            ? SingleChildScrollView(
                child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount:
                        ref.read(cartProvider).forCheckoutCartItems.length,
                    itemBuilder: (context, index) {
                      return _cartEntry(
                          ref.read(cartProvider).forCheckoutCartItems[index]);
                    }),
              )
            : Center(
                child: quicksandWhiteBold(
                    'YOU HAVE NO CART ITEMS READY FOR CHECK-OUT')),
      ),
    );
  }

  Widget _cartEntry(DocumentSnapshot cartDoc) {
    final cartData = cartDoc.data() as Map<dynamic, dynamic>;
    String itemType = cartData[CartFields.itemType];
    int quantity = cartData[CartFields.quantity];
    Map<dynamic, dynamic> quotation = {};
    num price = 0;
    num laborPrice = 0;
    num additionalServicePrice = 0;
    bool isRequestingAdditionalService = false;
    DocumentSnapshot? associatedItemDoc =
        associatedItemDocs.where((productDoc) {
      return productDoc.id == cartData[CartFields.itemID].toString();
    }).firstOrNull;
    if (associatedItemDoc == null)
      return Container();
    else {
      String name = associatedItemDoc[ItemFields.name];
      List<dynamic> imageURLs = associatedItemDoc[ItemFields.imageURLs];
      List<dynamic> accessoryField = [];
      String color = '';
      quotation = cartData[CartFields.quotation];

      if (itemType == ItemTypes.rawMaterial) {
        price = associatedItemDoc[ItemFields.price];
      } else {
        price = quotation[QuotationFields.itemOverallPrice];
        laborPrice = quotation[QuotationFields.laborPrice];
        accessoryField = associatedItemDoc[ItemFields.accessoryFields];
        color = quotation[QuotationFields.color];
      }
      additionalServicePrice =
          quotation[QuotationFields.additionalServicePrice];
      isRequestingAdditionalService =
          quotation[QuotationFields.isRequestingAdditionalService];
      String requestAddress = quotation[QuotationFields.requestAddress];
      String requestContactNumber =
          quotation[QuotationFields.requestContactNumber];
      //num price = associatedItemDoc[ItemFields.price];
      return all10Pix(
          child: Stack(
        children: [
          Container(
              decoration: BoxDecoration(
                  border: Border.all(color: CustomColors.lavenderMist)),
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  //  Checkbox
                  if (ref
                      .read(cartProvider)
                      .forCheckoutCartItems
                      .contains(cartDoc))
                    _selectItemCheckbox(
                        cartDoc: cartDoc,
                        laborPrice: laborPrice,
                        itemType: itemType),
                  // Order Data
                  _orderDataWidgets(
                      imageURLs: imageURLs,
                      name: name,
                      price: price,
                      itemType: itemType,
                      laborPrice: laborPrice,
                      additionalServicePrice: additionalServicePrice,
                      quotation: quotation,
                      color: color,
                      cartDoc: cartDoc,
                      address: requestAddress,
                      requestContactNumber: requestContactNumber,
                      isRequestingAdditionalService:
                          isRequestingAdditionalService,
                      accessoryField: accessoryField),
                  if (ref
                      .read(cartProvider)
                      .forCheckoutCartItems
                      .contains(cartDoc))
                    _changeQuantityButtons(
                        quantity: quantity, cartDoc: cartDoc),
                  if (!ref
                      .read(cartProvider)
                      .pendingAdditionalCostCartItems
                      .contains(cartDoc))
                    _deleteFromCartButton(name: name, cartDoc: cartDoc)
                ],
              )),
          // if (laborPrice > 0)
          //   Positioned(
          //       top: 10,
          //       right: 10,
          //       child: Container(
          //         width: 12,
          //         height: 12,
          //         decoration:
          //             BoxDecoration(shape: BoxShape.circle, color: Colors.red),
          //       ))
        ],
      ));
    }
  }

  Widget _selectItemCheckbox(
      {required DocumentSnapshot cartDoc,
      required num laborPrice,
      required String itemType}) {
    return Flexible(
        child: Checkbox(
            value:
                ref.read(cartProvider).selectedCartItemIDs.contains(cartDoc.id),
            onChanged: (itemType == ItemTypes.rawMaterial || laborPrice > 0)
                ? (newVal) {
                    if (newVal == null) return;
                    setState(() {
                      if (newVal) {
                        ref.read(cartProvider).selectCartItem(cartDoc.id);
                      } else {
                        ref.read(cartProvider).deselectCartItem(cartDoc.id);
                      }
                    });
                  }
                : null));
  }

  Widget _orderDataWidgets(
      {required List<dynamic> imageURLs,
      required String name,
      required num price,
      required String itemType,
      required num laborPrice,
      required num additionalServicePrice,
      required Map<dynamic, dynamic> quotation,
      required String color,
      required List<dynamic> accessoryField,
      required DocumentSnapshot cartDoc,
      required bool isRequestingAdditionalService,
      required String address,
      required String requestContactNumber,
      double? width}) {
    String requestStatus = quotation[QuotationFields.requestStatus];
    return Flexible(
      flex: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            //crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(imageURLs.first))),
              ),
              Gap(20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                      width: width ?? MediaQuery.of(context).size.width * 0.15,
                      child: quicksandWhiteBold(name,
                          textAlign: TextAlign.left,
                          textOverflow: TextOverflow.ellipsis)),
                  Row(
                    children: [
                      quicksandWhiteRegular(
                          'PHP ${formatPrice(price.toDouble())}',
                          fontSize: 16),
                    ],
                  ),
                  if (itemType != ItemTypes.rawMaterial)
                    quicksandWhiteRegular(
                        'Labor Price: PHP ${laborPrice > 0 ? laborPrice : 'TBA'}',
                        fontSize: 14),
                  if (isRequestingAdditionalService) ...[
                    if ((itemType == ItemTypes.window ||
                            itemType == ItemTypes.door) &&
                        (requestStatus == RequestStatuses.pending ||
                            requestStatus == RequestStatuses.approved))
                      quicksandWhiteRegular(
                          'Installation Address:\n${address} ',
                          fontSize: 14,
                          textAlign: TextAlign.left)
                    else if (itemType == ItemTypes.rawMaterial &&
                        (requestStatus == RequestStatuses.pending ||
                            requestStatus == RequestStatuses.approved))
                      quicksandWhiteRegular('Delivery Address:\n${address}',
                          textAlign: TextAlign.left, fontSize: 12),
                    if (requestStatus == RequestStatuses.pending ||
                        requestStatus == RequestStatuses.approved)
                      quicksandWhiteRegular(
                          'Contact Number: ${requestContactNumber}',
                          textAlign: TextAlign.left,
                          fontSize: 14),
                    if ((itemType == ItemTypes.window ||
                            itemType == ItemTypes.door) &&
                        requestStatus == RequestStatuses.approved)
                      quicksandWhiteRegular(
                          'Installation Fee: PHP ${formatPrice(additionalServicePrice.toDouble())} ',
                          fontSize: 14)
                    else if (itemType == ItemTypes.rawMaterial &&
                        (requestStatus == RequestStatuses.approved))
                      quicksandWhiteRegular(
                          'Delivery Fee: PHP ${formatPrice(additionalServicePrice.toDouble())} ',
                          fontSize: 14)
                    else if ((itemType == ItemTypes.window ||
                            itemType == ItemTypes.door) &&
                        requestStatus == RequestStatuses.denied)
                      Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        //decoration: BoxDecoration(border: Border.all()),
                        child: quicksandWhiteRegular(
                            'Installation Request Denied: ${quotation[QuotationFields.requestDenialReason]}',
                            textAlign: TextAlign.left,
                            fontSize: 14),
                      )
                    else if (itemType == ItemTypes.rawMaterial &&
                        (requestStatus == RequestStatuses.denied))
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: quicksandWhiteRegular(
                            'Delivery Request Denied: ${quotation[QuotationFields.requestDenialReason]}',
                            textAlign: TextAlign.left,
                            fontSize: 14),
                      )
                  ]
                ],
              ),
            ],
          ),
          if (ref
              .read(cartProvider)
              .noAdditionalCostRequestedCartItems
              .contains(cartDoc))
            _requestAdditionalCostButton(
                itemType: itemType,
                isRequestingAdditionalService: isRequestingAdditionalService,
                cartID: cartDoc.id),
          if (itemType != ItemTypes.rawMaterial)
            _showQuotationButton(
                itemType, quotation, name, imageURLs, accessoryField, color)
          else if (!ref
              .read(cartProvider)
              .forCheckoutCartItems
              .contains(cartDoc))
            Gap(190)
        ],
      ),
    );
  }

  Widget _changeQuantityButtons(
      {required int quantity, required DocumentSnapshot cartDoc}) {
    return Flexible(
      flex: 4,
      child: Row(
        children: [
          Container(
              decoration: BoxDecoration(
                  border: Border.all(color: CustomColors.lavenderMist)),
              child: TextButton(
                  onPressed: quantity == 1
                      ? null
                      : () => changeCartItemQuantity(context, ref,
                          cartEntryDoc: cartDoc, isIncreasing: false),
                  child: quicksandWhiteRegular('-'))),
          Container(
              decoration: BoxDecoration(
                  border: Border.all(color: CustomColors.lavenderMist)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: quicksandWhiteRegular(quantity.toString(), fontSize: 15),
              )),
          Container(
              decoration: BoxDecoration(
                  border: Border.all(color: CustomColors.lavenderMist)),
              child: TextButton(
                  onPressed: () => changeCartItemQuantity(context, ref,
                      cartEntryDoc: cartDoc, isIncreasing: true),
                  child: quicksandWhiteRegular('+')))
        ],
      ),
    );
  }

  Widget _deleteFromCartButton(
      {required String name, required DocumentSnapshot cartDoc}) {
    return Flexible(
      child: IconButton(
          onPressed: () => displayDeleteEntryDialog(context,
                  message:
                      'Are you sure you wish to remove ${name} from your cart?',
                  deleteEntry: () {
                if (ref
                    .read(cartProvider)
                    .selectedCartItemIDs
                    .contains(cartDoc.id)) {
                  ref.read(cartProvider).deselectCartItem(cartDoc.id);
                }
                removeCartItem(context, ref, cartDoc: cartDoc);
              }),
          icon: Icon(Icons.delete, color: CustomColors.coralRed)),
    );
  }

  Widget _showQuotationButton(
      String itemType,
      Map<dynamic, dynamic> quotation,
      String itemName,
      List<dynamic> imageURLs,
      List<dynamic> accessoryField,
      String color) {
    final mandatoryWindowFields = quotation[QuotationFields.mandatoryMap];
    final optionalWindowFields =
        quotation[QuotationFields.optionalMap] as List<dynamic>;
    return all20Pix(
      child: SizedBox(
        width: 150,
        child: ElevatedButton(
            onPressed: () => showCartQuotationDialog(context, ref,
                laborPrice: quotation[QuotationFields.laborPrice],
                totalOverallPayment:
                    quotation[QuotationFields.itemOverallPrice],
                mandatoryWindowFields: mandatoryWindowFields,
                optionalWindowFields: optionalWindowFields,
                accessoryFields: accessoryField,
                width: quotation[QuotationFields.width],
                height: quotation[QuotationFields.height],
                color: color,
                itemName: itemName,
                imageURLs: imageURLs),
            child: quicksandWhiteRegular('VIEW\nQUOTATION', fontSize: 16)),
      ),
    );
  }

  Widget _requestAdditionalCostButton(
      {required String itemType,
      required bool isRequestingAdditionalService,
      required String cartID}) {
    bool isFurniture =
        itemType == ItemTypes.window || itemType == ItemTypes.door;
    return all20Pix(
      child: SizedBox(
        width: 250,
        child: ElevatedButton(
            onPressed: () =>
                requestForAdditionalCosts(context, ref, cartID: cartID),
            child: isFurniture && isRequestingAdditionalService
                ? quicksandWhiteRegular('REQUEST LABOR &\n INSTALLATION COST')
                : isFurniture && !isRequestingAdditionalService
                    ? quicksandWhiteRegular('REQUEST LABOR COST')
                    : quicksandWhiteRegular('REQUEST DELIVERY COST')),
      ),
    );
  }

  Widget _checkoutContainer() {
    return all20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25 - 40,
        height: MediaQuery.of(context).size.height - 200,
        decoration:
            BoxDecoration(border: Border.all(color: CustomColors.lavenderMist)),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: quicksandWhiteBold('CHECKOUT', fontSize: 30),
              ),
              if (ref.read(cartProvider).selectedCartItemIDs.isNotEmpty)
                _totalAmountFutureBuilder()
              else
                quicksandWhiteBold('TOTAL AMOUNT: PHP 0.00'),
              const Gap(20),
              paymentMethod(ref),
              if (ref.read(cartProvider).selectedPaymentMethod.isNotEmpty)
                uploadPayment(ref),
              if (ref.read(uploadedImageProvider).uploadedImage != null)
                vertical20Pix(
                  child: selectedMemoryImageDisplay(
                      ref.read(uploadedImageProvider).uploadedImage,
                      () => ref.read(uploadedImageProvider).removeImage()),
                ),
              _paymentButton(),
              if (ref.read(uploadedImageProvider).uploadedImage != null &&
                  ref.read(cartProvider).selectedCartItemIDs.isNotEmpty &&
                  ref.read(cartProvider).selectedPaymentMethod.isNotEmpty)
                _confirmPurchase()
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalAmountFutureBuilder() {
    //  1. Get every associated cart DocumentSnapshot
    List<DocumentSnapshot> selectedCartDocs = [];
    for (var cartID in ref.read(cartProvider).selectedCartItemIDs) {
      selectedCartDocs.add(ref
          .read(cartProvider)
          .cartItems
          .where((element) => element.id == cartID)
          .first);
    }
    //  2. get list of associated products
    num totalAmount = 0;
    //  Go through every selected cart item
    for (var cartDoc in selectedCartDocs) {
      final cartData = cartDoc.data() as Map<dynamic, dynamic>;
      String itemID = cartData[CartFields.itemID];
      num quantity = cartData[CartFields.quantity];
      DocumentSnapshot? itemDoc =
          associatedItemDocs.where((item) => item.id == itemID).firstOrNull;
      if (itemDoc == null) {
        continue;
      }
      final itemData = itemDoc.data() as Map<dynamic, dynamic>;
      if (itemData[ItemFields.itemType] == ItemTypes.rawMaterial) {
        num price = itemData[ItemFields.price];
        totalAmount += quantity * price;
        Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
        num additionalServicePrice =
            quotation[QuotationFields.additionalServicePrice] ?? 0;
        totalAmount += additionalServicePrice;
      } else {
        Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
        totalAmount +=
            (quantity * quotation[QuotationFields.itemOverallPrice]) +
                quotation[QuotationFields.laborPrice];
        num additionalServicePrice =
            quotation[QuotationFields.additionalServicePrice] ?? 0;
        totalAmount += additionalServicePrice;
      }
    }
    paidAmount = totalAmount;
    return quicksandWhiteBold(
        'TOTAL AMOUNT: PHP ${formatPrice(totalAmount.toDouble())}');
  }

  Widget paymentMethod(WidgetRef ref) {
    return all10Pix(
        child: Column(
      children: [
        Row(
          children: [quicksandWhiteBold('PAYMENT METHOD')],
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: dropdownWidget(ref.read(cartProvider).selectedPaymentMethod,
              (newVal) {
            ref.read(cartProvider).setSelectedPaymentMethod(newVal!);
          }, ['GCASH', 'BANK TRANSFER'], 'Select your payment method', false),
        )
      ],
    ));
  }

  Widget uploadPayment(WidgetRef ref) {
    return all10Pix(
        child: Column(
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                quicksandWhiteBold('SEND YOUR PAYMENT HERE'),
                Gap(4),
                if (ref.read(cartProvider).selectedPaymentMethod == 'GCASH')
                  quicksandWhiteRegular('GCASH:\n\t09484548667\n\tJonas Banca',
                      fontSize: 14, textAlign: TextAlign.left)
                else if (ref.read(cartProvider).selectedPaymentMethod ==
                    'BANK TRANSFER')
                  quicksandWhiteBold('CIMB HASC:\n20867602518671\nTERENCE SY',
                      fontSize: 14, textAlign: TextAlign.left)
              ],
            )
          ],
        ),
      ],
    ));
  }

  Widget _paymentButton() {
    return vertical20Pix(
      child: SizedBox(
        height: 60,
        child: ElevatedButton(
            onPressed: ref.read(cartProvider).selectedPaymentMethod.isEmpty ||
                    ref.read(cartProvider).selectedCartItemIDs.isEmpty
                ? null
                : () async {
                    final pickedFile = await ImagePickerWeb.getImageAsBytes();
                    if (pickedFile == null) return;
                    ref.read(uploadedImageProvider).addImage(pickedFile);
                  },
            style: ElevatedButton.styleFrom(
                disabledBackgroundColor: CustomColors.lavenderMist),
            child: quicksandWhiteBold('MAKE PAYMENT')),
      ),
    );
  }

  Widget _confirmPurchase() {
    return vertical20Pix(
        child: SizedBox(
      height: 60,
      child: ElevatedButton(
          onPressed: () =>
              purchaseSelectedCartItems(context, ref, paidAmount: paidAmount),
          child: quicksandWhiteRegular('CONFIRM PURCHASE')),
    ));
  }
}
