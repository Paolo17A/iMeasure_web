import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/string_util.dart';

class CartNotifier extends ChangeNotifier {
  List<DocumentSnapshot> _cartItems = [];
  List<DocumentSnapshot> _noAdditionalCostRequestedCartItems = [];
  List<DocumentSnapshot> _pendingAdditionalCostCartItems = [];
  List<DocumentSnapshot> _forCheckoutCartItems = [];
  String _selectedPaymentMethod = '';
  List<String> _selectedCartItemIDs = [];
  String _selectedGlassType = '';
  String _selectedColor = '';

  List<DocumentSnapshot> get cartItems => _cartItems;
  List<DocumentSnapshot> get noAdditionalCostRequestedCartItems =>
      _noAdditionalCostRequestedCartItems;
  List<DocumentSnapshot> get pendingAdditionalCostCartItems =>
      _pendingAdditionalCostCartItems;
  List<DocumentSnapshot> get forCheckoutCartItems => _forCheckoutCartItems;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  List<String> get selectedCartItemIDs => _selectedCartItemIDs;
  String get selectedGlassType => _selectedGlassType;
  String get selectedColor => _selectedColor;

  void setCartItems(List<DocumentSnapshot> items) {
    _cartItems = items;
    _cartItems.sort((a, b) {
      DateTime aTime = (a[CartFields.dateLastModified] as Timestamp).toDate();
      DateTime bTime = (b[CartFields.dateLastModified] as Timestamp).toDate();
      return aTime.compareTo(bTime);
    });
    updateCartSubLists();
    notifyListeners();
  }

  void updateCartSubLists() {
    _noAdditionalCostRequestedCartItems = _cartItems.where((cart) {
      final cartData = cart.data() as Map<dynamic, dynamic>;
      String itemType = cartData[CartFields.itemType];
      Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
      String requestStatus = quotation[QuotationFields.requestStatus];
      bool isRequestingAdditionalService =
          quotation[QuotationFields.isRequestingAdditionalService];
      bool isFurniture =
          (itemType == ItemTypes.window || itemType == ItemTypes.door);
      return (isFurniture && requestStatus.isEmpty) ||
          (!isFurniture &&
              isRequestingAdditionalService &&
              requestStatus.isEmpty);
    }).toList();

    _pendingAdditionalCostCartItems = _cartItems.where((cart) {
      final cartData = cart.data() as Map<dynamic, dynamic>;
      Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
      String requestStatus = quotation[QuotationFields.requestStatus];
      return requestStatus == RequestStatuses.pending;
    }).toList();

    _forCheckoutCartItems = _cartItems.where((cart) {
      final cartData = cart.data() as Map<dynamic, dynamic>;
      String itemType = cartData[CartFields.itemType];
      Map<dynamic, dynamic> quotation = cartData[CartFields.quotation];
      String requestStatus = quotation[QuotationFields.requestStatus];
      bool isRequestingAdditionalService =
          quotation[QuotationFields.isRequestingAdditionalService];
      bool isFurniture =
          (itemType == ItemTypes.window || itemType == ItemTypes.door);
      return (isFurniture &&
              (requestStatus == RequestStatuses.approved ||
                  requestStatus == RequestStatuses.denied)) ||
          (!isFurniture && !isRequestingAdditionalService) ||
          (!isFurniture &&
              isRequestingAdditionalService &&
              (requestStatus == RequestStatuses.approved ||
                  requestStatus == RequestStatuses.denied));
    }).toList();
    notifyListeners();
  }

  void addCartItem(dynamic item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void removeCartItem(DocumentSnapshot item) {
    _cartItems.remove(item);
    notifyListeners();
  }

  bool cartContainsThisItem(String itemID) {
    return _cartItems.any((cartItem) {
      final cartData = cartItem.data() as Map<dynamic, dynamic>;
      return cartData[CartFields.itemID] == itemID;
    });
  }

  void setSelectedPaymentMethod(String paymentMethod) {
    _selectedPaymentMethod = paymentMethod;
    notifyListeners();
  }

  void setSelectedColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  void selectCartItem(String item) {
    if (selectedCartItemIDs.contains(item)) return;
    _selectedCartItemIDs.add(item);
    notifyListeners();
  }

  void deselectCartItem(String item) {
    if (!selectedCartItemIDs.contains(item)) return;
    _selectedCartItemIDs.remove(item);
    notifyListeners();
  }

  void resetSelectedCartItems() {
    _selectedCartItemIDs.clear();
    notifyListeners();
  }

  void setGlassType(String glass) {
    _selectedGlassType = glass;
    notifyListeners();
  }
}

final cartProvider =
    ChangeNotifierProvider<CartNotifier>((ref) => CartNotifier());
