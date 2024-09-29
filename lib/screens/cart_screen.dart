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

class _CartScreenState extends ConsumerState<CartScreen> {
  List<DocumentSnapshot> associatedItemDocs = [];
  num paidAmount = 0;
  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      appBar: topUserNavigator(context, path: GoRoutes.cart),
      body: stackedLoadingContainer(
          context,
          ref.read(loadingProvider).isLoading,
          Column(
            children: [
              Divider(),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_cartEntries(), _checkoutContainer()]),
            ],
          )),
    );
  }

  Widget _cartEntries() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.height - 160,
      child: all10Pix(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            quicksandWhiteBold('CART ITEMS', fontSize: 40),
            ref.read(cartProvider).cartItems.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: ref.read(cartProvider).cartItems.length,
                    itemBuilder: (context, index) {
                      return _cartEntry(
                          ref.read(cartProvider).cartItems[index]);
                    })
                : quicksandWhiteBold('YOU DO NOT HAVE ANY ITEMS IN YOUR CART')
          ],
        ),
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
    DocumentSnapshot? associatedItemDoc =
        associatedItemDocs.where((productDoc) {
      return productDoc.id == cartData[CartFields.itemID].toString();
    }).firstOrNull;
    if (associatedItemDoc == null)
      return Container();
    else {
      String name = associatedItemDoc[ItemFields.name];
      String imageURL = associatedItemDoc[ItemFields.imageURL];
      if (itemType == ItemTypes.rawMaterial) {
        price = associatedItemDoc[ItemFields.price];
      } else {
        quotation = cartData[CartFields.quotation];
        price = quotation[QuotationFields.itemOverallPrice];
        laborPrice = quotation[QuotationFields.laborPrice];
      }
      //num price = associatedItemDoc[ItemFields.price];
      return all10Pix(
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: CustomColors.lavenderMist)),
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  //  Checkbox
                  Flexible(
                      child: Checkbox(
                          value: ref
                              .read(cartProvider)
                              .selectedCartItemIDs
                              .contains(cartDoc.id),
                          onChanged: (itemType == ItemTypes.rawMaterial ||
                                  laborPrice > 0)
                              ? (newVal) {
                                  if (newVal == null) return;
                                  setState(() {
                                    if (newVal) {
                                      ref
                                          .read(cartProvider)
                                          .selectCartItem(cartDoc.id);
                                    } else {
                                      ref
                                          .read(cartProvider)
                                          .deselectCartItem(cartDoc.id);
                                    }
                                  });
                                }
                              : null)),
                  // Order Data
                  Flexible(
                    flex: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                      image: NetworkImage(imageURL))),
                            ),
                            Gap(20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                quicksandWhiteBold(name),
                                Row(
                                  children: [
                                    quicksandWhiteRegular(
                                        'PHP ${formatPrice(price.toDouble())}',
                                        fontSize: 16),
                                  ],
                                ),
                                if (itemType != ItemTypes.rawMaterial ||
                                    laborPrice > 0)
                                  quicksandWhiteRegular(
                                      'Labor Price: PHP ${laborPrice > 0 ? laborPrice : 'TBA'}',
                                      fontSize: 14),
                                if (itemType != ItemTypes.rawMaterial)
                                  all4Pix(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        quicksandWhiteRegular(
                                            'Width: ${quotation[QuotationFields.width]}ft',
                                            fontSize: 12),
                                        quicksandWhiteRegular(
                                            'Height: ${quotation[QuotationFields.height]}ft',
                                            fontSize: 12)
                                      ]))
                              ],
                            ),
                          ],
                        ),
                        itemType != ItemTypes.rawMaterial
                            ? all20Pix(
                                child: _showQuotationButton(
                                    itemType, cartData[CartFields.quotation]))
                            : Container()
                      ],
                    ),
                  ),

                  Flexible(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: CustomColors.lavenderMist)),
                            child: TextButton(
                                onPressed: quantity == 1
                                    ? null
                                    : () => changeCartItemQuantity(context, ref,
                                        cartEntryDoc: cartDoc,
                                        isIncreasing: false),
                                child: quicksandWhiteRegular('-'))),
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: CustomColors.lavenderMist)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: quicksandWhiteRegular(quantity.toString(),
                                  fontSize: 15),
                            )),
                        Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: CustomColors.lavenderMist)),
                            child: TextButton(
                                onPressed: () => changeCartItemQuantity(
                                    context, ref,
                                    cartEntryDoc: cartDoc, isIncreasing: true),
                                child: quicksandWhiteRegular('+')))
                      ],
                    ),
                  ),
                  Flexible(
                    child: IconButton(
                        onPressed: () => displayDeleteEntryDialog(context,
                                message:
                                    'Are you sure you wish to remove ${name} from your cart?',
                                deleteEntry: () {
                              if (ref
                                  .read(cartProvider)
                                  .selectedCartItemIDs
                                  .contains(cartDoc.id)) {
                                ref
                                    .read(cartProvider)
                                    .deselectCartItem(cartDoc.id);
                              }
                              removeCartItem(context, ref, cartDoc: cartDoc);
                            }),
                        icon: Icon(Icons.delete, color: CustomColors.coralRed)),
                  )
                ],
              )));
    }
  }

  Widget _showQuotationButton(
      String itemType, Map<dynamic, dynamic> quotation) {
    final mandatoryWindowFields = quotation[QuotationFields.mandatoryMap];
    final optionalWindowFields =
        quotation[QuotationFields.optionalMap] as List<dynamic>;
    return ElevatedButton(
        onPressed: () => showCartQuotationDialog(context, ref,
            laborPrice: quotation[QuotationFields.laborPrice],
            totalOverallPayment: quotation[QuotationFields.itemOverallPrice],
            mandatoryWindowFields: mandatoryWindowFields,
            optionalWindowFields: optionalWindowFields),
        child: quicksandWhiteRegular('VIEW\nQUOTATION', fontSize: 16));
  }

  Widget _checkoutContainer() {
    return all20Pix(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.25 - 40,
        height: MediaQuery.of(context).size.height - 160,
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
      } else {
        Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
        totalAmount +=
            (quantity * quotation[QuotationFields.itemOverallPrice]) +
                quotation[QuotationFields.laborPrice];
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
          }, ['GCASH', 'PAYMAYA'], 'Select your payment method', false),
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
                    'PAYMAYA')
                  quicksandWhiteRegular(
                      'PAYMAYA:\n\t09484548667\n\tJonas Banca',
                      fontSize: 14,
                      textAlign: TextAlign.left)
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
